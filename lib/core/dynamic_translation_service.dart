import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MNC-grade on-device dynamic translation service using Google ML Kit.
///
/// Features:
/// - Two-tier cache: in-memory LRU + persistent SharedPreferences
/// - Fire-and-forget background translation (never blocks UI)
/// - Batch pre-warming via [ensureAllTranslated]
/// - Automatic model download when a new language is selected
/// - No-op when current locale is English
/// - Thread-safe deduplication (won't translate the same text twice concurrently)
class DynamicTranslationService extends ChangeNotifier {
  static final DynamicTranslationService _instance =
      DynamicTranslationService._internal();
  factory DynamicTranslationService() => _instance;
  DynamicTranslationService._internal() {
    _loadPersistentCache();
    _preDownloadAllModels();
  }

  // ── Active language ──────────────────────────────────────────────────────
  String _currentLangCode = 'en';
  OnDeviceTranslator? _translator;
  ModelManager? _modelManager;
  bool _isModelReady = false;
  bool _isDownloadingModel = false;
  String? _downloadErrorMessage;
  Future<void>? _initFuture;

  // Non-blocking sequential download queue state
  List<String> _pendingBackgroundLangs = [];
  bool _isQueueProcessing = false;
  Completer<void>? _activeInitCompleter;

  String get currentLangCode => _currentLangCode;
  bool get isModelReady => _isModelReady;
  bool get isDownloadingModel => _isDownloadingModel;
  String? get downloadErrorMessage => _downloadErrorMessage;

  // ── In-memory cache (LRU, max 1000 entries) ─────────────────────────────
  // Key: "$langCode|$sourceText"  Value: translatedText
  final LinkedHashMap<String, String> _memCache = LinkedHashMap();
  static const int _maxMemCacheEntries = 1000;

  // ── In-flight deduplication ──────────────────────────────────────────────
  final Set<String> _inFlight = {};

  // ── Persistent cache via SharedPreferences ───────────────────────────────
  static const String _prefKey = 'dynamic_translation_cache_v1';
  SharedPreferences? _prefs;

  // ── ML Kit language mapping ──────────────────────────────────────────────
  static const Map<String, TranslateLanguage> _langMap = {
    'hi': TranslateLanguage.hindi,
    'mr': TranslateLanguage.marathi,
    'te': TranslateLanguage.telugu,
    'ta': TranslateLanguage.tamil,
    'kn': TranslateLanguage.kannada,
  };

  // ══════════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the cached translation for [text], or [text] itself if not yet
  /// available (never returns null, never blocks).
  String getTranslation(String text) {
    if (text.isEmpty || _currentLangCode == 'en') return text;
    final key = _cacheKey(text);
    return _memCache[key] ?? text;
  }

  /// Returns true if a cached translation exists for [text].
  bool hasTranslation(String text) {
    if (_currentLangCode == 'en') return true;
    return _memCache.containsKey(_cacheKey(text));
  }

  /// Fire-and-forget: translates [text] in background and calls
  /// [notifyListeners] when done. Safe to call from build().
  void ensureTranslated(String text) {
    if (text.isEmpty || _currentLangCode == 'en') return;
    final key = _cacheKey(text);
    if (_memCache.containsKey(key) || _inFlight.contains(key)) return;
    _translateAsync(text, key);
  }

  /// Batch fire-and-forget for a list of texts.
  void ensureAllTranslated(List<String> texts) {
    for (final t in texts) {
      ensureTranslated(t);
    }
  }

  /// Fully async translate — returns the translated string when done.
  Future<String> translate(String text) async {
    if (text.isEmpty || _currentLangCode == 'en') return text;
    final key = _cacheKey(text);
    if (_memCache.containsKey(key)) return _memCache[key]!;
    return _translateAsync(text, key);
  }

  // ── Locale change (called from LanguageService) ──────────────────────────

  /// Call this whenever the user picks a new language.
  Future<void> onLocaleChanged(String newLangCode) async {
    debugPrint('[DTS] onLocaleChanged called with: $newLangCode (current: $_currentLangCode)');
    if (_currentLangCode == newLangCode) return;
    _currentLangCode = newLangCode;

    // Tear down old translator
    await _translator?.close();
    _translator = null;
    _isModelReady = false;
    _isDownloadingModel = false;
    _downloadErrorMessage = null;
    _initFuture = null;
    
    // Immediately clear pending background downloads so active selection takes precedence
    _pendingBackgroundLangs.clear();
    _activeInitCompleter = null;
    notifyListeners();

    if (newLangCode == 'en') return;

    final target = _langMap[newLangCode];
    if (target == null) {
      debugPrint('[DTS] Target language map entry not found for: $newLangCode');
      return;
    }

    _initFuture = _initTranslator(target);
    _initFuture!.catchError((e) {
      debugPrint('[DTS] Init future error: $e');
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════════════════════

  String _cacheKey(String text) => '$_currentLangCode|$text';

  Future<void> _initTranslator(TranslateLanguage target) {
    if (_activeInitCompleter != null && !_activeInitCompleter!.isCompleted) {
      return _activeInitCompleter!.future;
    }
    _activeInitCompleter = Completer<void>();
    
    // Set downloading state
    _isDownloadingModel = true;
    _downloadErrorMessage = null;
    notifyListeners();

    // Trigger queue processing
    _processQueue();
    
    return _activeInitCompleter!.future;
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;
    _isQueueProcessing = true;

    try {
      while (true) {
        // 1. Process active language download first (High Priority)
        final activeTarget = _langMap[_currentLangCode];
        if (activeTarget != null && !_isModelReady && _isDownloadingModel) {
          final bcp = activeTarget.bcpCode;
          _modelManager ??= OnDeviceTranslatorModelManager();
          
          debugPrint('[DTS] Queue: Processing active language download for: $bcp');
          try {
            final isDownloaded = await _modelManager!.isModelDownloaded(bcp);
            if (!isDownloaded) {
              debugPrint('[DTS] Queue: Model NOT downloaded. Starting active download for: $bcp');
              await _modelManager!.downloadModel(
                bcp,
                isWifiRequired: false,
              ).timeout(const Duration(seconds: 40));
              debugPrint('[DTS] Queue: Active model downloaded successfully for $bcp');
            } else {
              debugPrint('[DTS] Queue: Active model is already downloaded for: $bcp');
            }
            
            _translator = OnDeviceTranslator(
              sourceLanguage: TranslateLanguage.english,
              targetLanguage: activeTarget,
            );
            _isModelReady = true;
            _isDownloadingModel = false;
            _downloadErrorMessage = null;
            notifyListeners();
            
            final completer = _activeInitCompleter;
            _activeInitCompleter = null;
            completer?.complete();

            // Trigger background pre-downloads for remaining languages
            _enqueueRemainingBackgroundDownloads();
          } on TimeoutException catch (e) {
            _isDownloadingModel = false;
            _downloadErrorMessage =
                'Model download is pending. Please connect to Wi-Fi '
                'or check Google Play Store settings.';
            _initFuture = null; // allow retry
            notifyListeners();
            debugPrint('[DTS] Queue: Active model download timed out: $e');
            
            final completer = _activeInitCompleter;
            _activeInitCompleter = null;
            completer?.complete();
          } catch (e) {
            _isDownloadingModel = false;
            _downloadErrorMessage =
                'Translation model unavailable. '
                'Translations will show when online.';
            _initFuture = null; // allow retry
            notifyListeners();
            debugPrint('[DTS] Queue: Active model download failed: $e');
            
            final completer = _activeInitCompleter;
            _activeInitCompleter = null;
            completer?.completeError(e);
          }
          continue;
        }

        // 2. Process background downloads sequentially (Low Priority)
        if (_pendingBackgroundLangs.isNotEmpty) {
          final langCode = _pendingBackgroundLangs.removeAt(0);
          final target = _langMap[langCode];
          if (target != null && langCode != _currentLangCode) {
            _modelManager ??= OnDeviceTranslatorModelManager();
            debugPrint('[DTS] Queue: Background pre-download checking for: $langCode');
            try {
              final isDownloaded = await _modelManager!.isModelDownloaded(target.bcpCode);
              if (!isDownloaded) {
                debugPrint('[DTS] Queue: Pre-downloading model sequentially in background for: $langCode');
                await _modelManager!.downloadModel(
                  target.bcpCode,
                  isWifiRequired: false,
                ).timeout(const Duration(seconds: 20));
                debugPrint('[DTS] Queue: Background pre-download for $langCode completed successfully');
              } else {
                debugPrint('[DTS] Queue: Model already downloaded for: $langCode');
              }
            } catch (e) {
              debugPrint('[DTS] Queue: Error/timeout in background pre-download for $langCode: $e');
            }
            // Small delay before next task inside the queue to avoid immediate reuse of the native channel
            await Future.delayed(const Duration(seconds: 3));
          }
          continue;
        }

        break;
      }
    } finally {
      _isQueueProcessing = false;
    }
  }

  Future<void> _enqueueRemainingBackgroundDownloads() async {
    _modelManager ??= OnDeviceTranslatorModelManager();
    final remaining = <String>[];
    for (final langEntry in _langMap.entries) {
      final langCode = langEntry.key;
      final target = langEntry.value;
      if (langCode == _currentLangCode) continue;
      
      try {
        final isDownloaded = await _modelManager!.isModelDownloaded(target.bcpCode);
        if (!isDownloaded) {
          remaining.add(langCode);
        }
      } catch (e) {
        debugPrint('[DTS] Error checking model status for $langCode: $e');
      }
    }
    
    if (remaining.isNotEmpty) {
      _pendingBackgroundLangs = remaining;
      _processQueue();
    }
  }

  Future<void> _preDownloadAllModels() async {
    // Only pre-download after a short delay to let app boot
    Future.delayed(const Duration(seconds: 5), () {
      debugPrint('[DTS] Starting background sequential pre-download check for all target languages...');
      _enqueueRemainingBackgroundDownloads();
    });
  }

  Future<String> _translateAsync(String text, String key) async {
    _inFlight.add(key);
    debugPrint('[DTS] _translateAsync called for: "$text"');
    try {
      // If there's an active init future, wait for it
      if (_initFuture != null) {
        debugPrint('[DTS] Awaiting active initialization future for: "$text"');
        try {
          await _initFuture;
        } catch (e) {
          debugPrint('[DTS] Active init future failed inside _translateAsync: $e');
        }
      }

      // Lazy-init translator if not yet set up
      if (_translator == null) {
        final target = _langMap[_currentLangCode];
        if (target != null) {
          if (_initFuture == null) {
            debugPrint('[DTS] Lazy initializing translator for: ${_currentLangCode}');
            _initFuture = _initTranslator(target);
          }
          try {
            await _initFuture;
          } catch (e) {
            debugPrint('[DTS] Lazy init future failed: $e');
          }
        }
      }

      if (_translator == null) {
        debugPrint('[DTS] Translator is null, aborting translation for: "$text"');
        _inFlight.remove(key);
        return text;
      }

      debugPrint('[DTS] Executing ML Kit translation for: "$text"');
      final result = await _translator!.translateText(text);
      debugPrint('[DTS] Translation successful: "$text" -> "$result"');
      _writeCache(key, result);
      _inFlight.remove(key);
      notifyListeners();
      return result;
    } catch (e) {
      _inFlight.remove(key);
      debugPrint('[DTS] Translation error for "$text": $e');
      return text;
    }
  }

  void _writeCache(String key, String value) {
    // LRU eviction
    if (_memCache.length >= _maxMemCacheEntries) {
      _memCache.remove(_memCache.keys.first);
    }
    _memCache[key] = value;
    _persistCache();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadPersistentCache() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getStringList(_prefKey) ?? [];
      // Format: ['langCode|sourceText', 'translatedText', ...]
      for (int i = 0; i + 1 < raw.length; i += 2) {
        _memCache[raw[i]] = raw[i + 1];
      }
      debugPrint('[DTS] Loaded ${_memCache.length} cached translations');
    } catch (e) {
      debugPrint('[DTS] Cache load error: $e');
    }
  }

  Future<void> _persistCache() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = <String>[];
      _memCache.forEach((k, v) {
        raw.add(k);
        raw.add(v);
      });
      await _prefs!.setStringList(_prefKey, raw);
    } catch (e) {
      debugPrint('[DTS] Cache persist error: $e');
    }
  }



  @override
  void dispose() {
    _translator?.close();
    super.dispose();
  }
}
