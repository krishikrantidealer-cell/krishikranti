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
  }

  // ── Active language ──────────────────────────────────────────────────────
  String _currentLangCode = 'en';
  OnDeviceTranslator? _translator;
  final Map<OnDeviceTranslator, int> _activeCalls = {};
  ModelManager? _modelManager;
  bool _isModelReady = false;
  bool _isDownloadingModel = false;
  String? _downloadErrorMessage;
  Future<void>? _initFuture;

  // Non-blocking sequential download queue state
  List<String> _pendingBackgroundLangs = [];
  bool _isQueueProcessing = false;

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
    debugPrint(
      '[DTS] onLocaleChanged called with: $newLangCode (current: $_currentLangCode)',
    );
    if (_currentLangCode == newLangCode) return;
    _currentLangCode = newLangCode;

    // Tear down old translator safely
    final translatorToClose = _translator;
    _translator = null;
    _isModelReady = false;
    _isDownloadingModel = false;
    _downloadErrorMessage = null;
    _initFuture = null;

    if (translatorToClose != null) {
      _safeCloseTranslator(translatorToClose);
    }

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

  Future<void> _safeCloseTranslator(OnDeviceTranslator translator) async {
    final watch = Stopwatch()..start();
    while ((_activeCalls[translator] ?? 0) > 0 && watch.elapsedMilliseconds < 5000) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    try {
      await translator.close();
      debugPrint('[DTS] Translator closed successfully.');
    } catch (e) {
      debugPrint('[DTS] Error closing translator: $e');
    }
  }

  Future<void> _initTranslator(TranslateLanguage target) async {
    // Set downloading state
    _isDownloadingModel = true;
    _downloadErrorMessage = null;
    Future.microtask(() => notifyListeners());

    final bcp = target.bcpCode;
    _modelManager ??= OnDeviceTranslatorModelManager();

    debugPrint('[DTS] Initializing language model check/download for: $bcp');
    try {
      final isDownloaded = await _modelManager!.isModelDownloaded(bcp);
      if (!isDownloaded) {
        debugPrint(
          '[DTS] Model NOT downloaded. Starting active download for: $bcp',
        );

        // Use a temporary translator to trigger native downloadModelIfNeeded() correctly,
        // which avoids the "MlKitException: No existing model file" error.
        final tempTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: target,
        );
        try {
          await tempTranslator
              .translateText('ping')
              .timeout(const Duration(seconds: 45));
        } finally {
          await tempTranslator.close();
        }
        debugPrint('[DTS] Active model downloaded successfully for $bcp');
      } else {
        debugPrint('[DTS] Active model is already downloaded for: $bcp');
      }

      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: target,
      );
      _isModelReady = true;
      _isDownloadingModel = false;
      _downloadErrorMessage = null;
      notifyListeners();
    } on TimeoutException catch (e) {
      _isDownloadingModel = false;
      _downloadErrorMessage =
          'Model download is pending. Please connect to Wi-Fi '
          'or check Google Play Store settings.';
      _initFuture = null; // allow retry
      notifyListeners();
      debugPrint('[DTS] Active model download timed out: $e');
      rethrow;
    } catch (e) {
      _isDownloadingModel = false;
      _downloadErrorMessage =
          'Translation model unavailable. '
          'Translations will show when online.';
      _initFuture = null; // allow retry
      notifyListeners();
      debugPrint('[DTS] Active model download failed: $e');
      rethrow;
    }
  }

  /// Public method to trigger sequential download of all models in the background.
  /// Typically called after splash screen to pre-warm languages during login/onboarding.
  void startBackgroundDownloadOfAllModels() {
    Future.delayed(const Duration(seconds: 10), () {
      debugPrint(
        '[DTS] Starting background sequential download after 10 seconds boot delay...',
      );
      _enqueueRemainingBackgroundDownloads();
    });
  }

  Future<void> _enqueueRemainingBackgroundDownloads() async {
    _modelManager ??= OnDeviceTranslatorModelManager();
    final remaining = <String>[];
    for (final langEntry in _langMap.entries) {
      final langCode = langEntry.key;
      final target = langEntry.value;
      if (langCode == _currentLangCode) continue;

      try {
        final isDownloaded = await _modelManager!.isModelDownloaded(
          target.bcpCode,
        );
        if (!isDownloaded) {
          remaining.add(langCode);
        }
      } catch (e) {
        debugPrint('[DTS] Error checking model status for $langCode: $e');
      }
    }

    if (remaining.isNotEmpty) {
      for (final code in remaining) {
        if (!_pendingBackgroundLangs.contains(code)) {
          _pendingBackgroundLangs.add(code);
        }
      }
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isQueueProcessing) return;
    _isQueueProcessing = true;

    try {
      while (_pendingBackgroundLangs.isNotEmpty) {
        final langCode = _pendingBackgroundLangs.removeAt(0);
        final target = _langMap[langCode];
        if (target != null && langCode != _currentLangCode) {
          _modelManager ??= OnDeviceTranslatorModelManager();
          debugPrint('[DTS] Background pre-download checking for: $langCode');
          try {
            final isDownloaded = await _modelManager!.isModelDownloaded(
              target.bcpCode,
            );
            if (!isDownloaded) {
              debugPrint(
                '[DTS] Pre-downloading model sequentially in background for: $langCode',
              );

              // Use a temporary translator to trigger native downloadModelIfNeeded() correctly,
              // which avoids the "MlKitException: No existing model file" error.
              final tempTranslator = OnDeviceTranslator(
                sourceLanguage: TranslateLanguage.english,
                targetLanguage: target,
              );
              try {
                await tempTranslator
                    .translateText('ping')
                    .timeout(const Duration(minutes: 5));
                debugPrint(
                  '[DTS] Background pre-download for $langCode completed successfully',
                );
              } finally {
                await tempTranslator.close();
              }
            } else {
              debugPrint('[DTS] Model already downloaded for: $langCode');
            }
          } catch (e) {
            debugPrint(
              '[DTS] Error/timeout in background pre-download for $langCode: $e',
            );
          }
          // Small delay before next task inside the queue to avoid immediate reuse of the native channel
          await Future.delayed(const Duration(seconds: 4));
        }
      }
    } finally {
      _isQueueProcessing = false;
    }
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
          debugPrint(
            '[DTS] Active init future failed inside _translateAsync: $e',
          );
        }
      }

      // Lazy-init translator if not yet set up
      if (_translator == null) {
        final target = _langMap[_currentLangCode];
        if (target != null) {
          if (_initFuture == null) {
            debugPrint(
              '[DTS] Lazy initializing translator for: ${_currentLangCode}',
            );
            _initFuture = _initTranslator(target);
          }
          try {
            await _initFuture;
          } catch (e) {
            debugPrint('[DTS] Lazy init future failed: $e');
          }
        }
      }

      final translator = _translator;
      if (translator == null) {
        debugPrint(
          '[DTS] Translator is null, aborting translation for: "$text"',
        );
        _inFlight.remove(key);
        return text;
      }

      debugPrint('[DTS] Executing ML Kit translation for: "$text"');
      _activeCalls[translator] = (_activeCalls[translator] ?? 0) + 1;
      try {
        final result = await translator.translateText(text);
        debugPrint('[DTS] Translation successful: "$text" -> "$result"');
        _writeCache(key, result);
        _inFlight.remove(key);
        notifyListeners();
        return result;
      } finally {
        _activeCalls[translator] = (_activeCalls[translator] ?? 0) - 1;
        if (_activeCalls[translator]! <= 0) {
          _activeCalls.remove(translator);
        }
      }
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
    if (_translator != null) {
      _safeCloseTranslator(_translator!);
    }
    super.dispose();
  }
}
