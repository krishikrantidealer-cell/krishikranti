import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  String get minVersion => _remoteConfig.getString('min_version');
  String get updateTitle => _remoteConfig.getString('force_update_title');
  String get updateMessage => _remoteConfig.getString('force_update_message');
  String get storeUrl => _remoteConfig.getString('store_url');

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(const {
        'min_version': '1.0.0',
        'force_update_title': 'Update Required',
        'force_update_message': 'A new version of Krishi Dealer is available. Please update to continue using the app.',
        'store_url': 'https://play.google.com/store/apps/details?id=com.krishi.dealer.retailer',
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfigService] Values initialized successfully.');
      debugPrint('[RemoteConfigService] Min version required: $minVersion');
    } catch (e) {
      debugPrint('[RemoteConfigService] Initialization failed: $e');
    }
  }

  Future<bool> isUpdateRequired() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      
      debugPrint('[RemoteConfigService] Current installed app version: $currentVersion');
      debugPrint('[RemoteConfigService] Min required version: $minVersion');

      return _needsUpdate(currentVersion, minVersion);
    } catch (e) {
      debugPrint('[RemoteConfigService] Error checking version: $e');
      return false;
    }
  }

  bool _needsUpdate(String currentVersion, String minVersion) {
    // Strip build number if present (e.g. 1.0.5+8 -> 1.0.5)
    final currentClean = currentVersion.split('+')[0].trim();
    final minClean = minVersion.split('+')[0].trim();

    final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final minParts = minClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength = currentParts.length > minParts.length ? currentParts.length : minParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) {
        return true;
      } else if (currentPart > minPart) {
        return false;
      }
    }
    return false;
  }
}
