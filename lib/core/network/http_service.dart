import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:krishikranti/core/network/auth_service.dart';

import 'package:krishikranti/main.dart'; // Import navigatorKey

class HttpService {
  static final dio.Dio _dio = dio.Dio();
  static final http.Client _client = http.Client();

  static void _forceLogout() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/phone-verify',
      (route) => false,
    );
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final defaultHeaders = await _getHeaders();
      var response = await _client.get(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          final newHeaders = await _getHeaders();
          response = await _client.get(
            Uri.parse(url),
            headers: {...newHeaders, ...?headers},
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final defaultHeaders = await _getHeaders();
      var response = await _client.post(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          final newHeaders = await _getHeaders();
          response = await _client.post(
            Uri.parse(url),
            headers: {...newHeaders, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> patch(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final defaultHeaders = await _getHeaders();
      var response = await _client.patch(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          final newHeaders = await _getHeaders();
          response = await _client.patch(
            Uri.parse(url),
            headers: {...newHeaders, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final defaultHeaders = await _getHeaders();
      var response = await _client.delete(
        Uri.parse(url),
        headers: {...defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          final newHeaders = await _getHeaders();
          response = await _client.delete(
            Uri.parse(url),
            headers: {...newHeaders, ...?headers},
            body: body != null ? jsonEncode(body) : null,
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload file using Dio for progress tracking and better performance
  static Future<dio.Response> uploadFile(
    String url, {
    required Map<String, dynamic> fields,
    required String fileKey,
    required String filePath,
    Function(int, int)? onProgress,
  }) async {
    try {
      final token = await AuthService.getToken();

      final formData = dio.FormData.fromMap({
        ...fields,
        fileKey: await dio.MultipartFile.fromFile(
          filePath,
          contentType: MediaType.parse(
            lookupMimeType(filePath) ?? 'application/octet-stream',
          ),
        ),
      });

      final options = dio.Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      var response = await _dio.post(
        url,
        data: formData,
        options: options,
        onSendProgress: onProgress,
      );

      return response;
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final newToken = await AuthService.getToken();
          final formData = dio.FormData.fromMap({
            ...fields,
            fileKey: await dio.MultipartFile.fromFile(
              filePath,
              contentType: MediaType.parse(
                lookupMimeType(filePath) ?? 'application/octet-stream',
              ),
            ),
          });
          final options = dio.Options(
            headers: {
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
          );
          return await _dio.post(
            url,
            data: formData,
            options: options,
            onSendProgress: onProgress,
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      rethrow;
    }
  }

  /// Upload multiple files using Dio for progress tracking and better performance
  static Future<dio.Response> uploadFiles(
    String url, {
    required Map<String, dynamic> fields,
    required Map<String, String> files, // Map of fileKey: filePath
    Function(int, int)? onProgress,
  }) async {
    try {
      final token = await AuthService.getToken();

      final Map<String, dynamic> dataMap = {...fields};
      for (var entry in files.entries) {
        if (entry.value.isNotEmpty) {
          dataMap[entry.key] = await dio.MultipartFile.fromFile(
            entry.value,
            contentType: MediaType.parse(
              lookupMimeType(entry.value) ?? 'application/octet-stream',
            ),
          );
        }
      }

      final formData = dio.FormData.fromMap(dataMap);

      final options = dio.Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      var response = await _dio.post(
        url,
        data: formData,
        options: options,
        onSendProgress: onProgress,
      );

      return response;
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final newToken = await AuthService.getToken();
          final Map<String, dynamic> dataMap = {...fields};
          for (var entry in files.entries) {
            if (entry.value.isNotEmpty) {
              dataMap[entry.key] = await dio.MultipartFile.fromFile(
                entry.value,
                contentType: MediaType.parse(
                  lookupMimeType(entry.value) ?? 'application/octet-stream',
                ),
              );
            }
          }
          final formData = dio.FormData.fromMap(dataMap);
          final options = dio.Options(
            headers: {
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
          );
          return await _dio.post(
            url,
            data: formData,
            options: options,
            onSendProgress: onProgress,
          );
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      rethrow;
    }
  }

  static Future<http.StreamedResponse> postMultipart(
    String url, {
    required Map<String, String> fields,
    required String fileKey,
    required String filePath,
  }) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      // Detect MIME type
      final mimeType = lookupMimeType(filePath);
      final contentType = mimeType != null ? MediaType.parse(mimeType) : null;

      request.files.add(
        await http.MultipartFile.fromPath(
          fileKey,
          filePath,
          contentType: contentType,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshAccessToken();
        if (refreshed) {
          // Re-create request with new token
          final newToken = await AuthService.getToken();
          final newRequest = http.MultipartRequest('POST', Uri.parse(url));
          if (newToken != null) {
            newRequest.headers['Authorization'] = 'Bearer $newToken';
          }
          newRequest.fields.addAll(fields);
          newRequest.files.add(
            await http.MultipartFile.fromPath(
              fileKey,
              filePath,
              contentType: contentType,
            ),
          );
          response = await newRequest.send();
        } else if (!(await AuthService.isLoggedIn())) {
          _forceLogout();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
