import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:krishikranti/core/constants/api_constants.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _isProfileCompleteKey = 'is_profile_complete';
  static const _isKycCompleteKey = 'is_kyc_complete';

  static String? _cachedToken;
  static String? _cachedRefreshToken;

  static Future<void> saveTokens(String token, String refreshToken) async {
    _cachedToken = token;
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> saveUserStatus({
    required bool isProfileComplete,
    required bool isKycComplete,
  }) async {
    await _storage.write(
      key: _isProfileCompleteKey,
      value: isProfileComplete.toString(),
    );
    await _storage.write(
      key: _isKycCompleteKey,
      value: isKycComplete.toString(),
    );
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _storage.read(key: _refreshTokenKey);
    return _cachedRefreshToken;
  }

  static Future<bool> isProfileComplete() async {
    final val = await _storage.read(key: _isProfileCompleteKey);
    return val == 'true';
  }

  static Future<bool> isKycComplete() async {
    final val = await _storage.read(key: _isKycCompleteKey);
    return val == 'true';
  }

  static Future<void> logout() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _isProfileCompleteKey);
    await _storage.delete(key: _isKycCompleteKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void>? _refreshFuture;

  static Future<bool> refreshAccessToken() async {
    // If a refresh is already in progress, wait for it
    if (_refreshFuture != null) {
      await _refreshFuture;
      return await isLoggedIn();
    }

    final Completer<void> completer = Completer<void>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        completer.complete();
        _refreshFuture = null;
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newToken != null && newRefreshToken != null) {
          await saveTokens(newToken, newRefreshToken);
          completer.complete();
          _refreshFuture = null;
          return true;
        }
      }

      // If the server explicitly rejects the refresh token (401 or 403)
      if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
        completer.complete();
        _refreshFuture = null;
        return false;
      }

      // For other errors (500, etc.), don't logout, just fail the refresh
      completer.complete();
      _refreshFuture = null;
      return false;
    } catch (e) {
      // If it's a network error, do NOT logout. Just return false.
      completer.complete();
      _refreshFuture = null;
      return false;
    }
  }
}
