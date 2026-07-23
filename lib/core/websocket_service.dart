import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:krishikranti/core/constants/api_constants.dart';
import 'package:krishikranti/core/network/auth_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

class WebSocketService {
  // ── Singleton ───────────────────────────────────────────────────────────────
  WebSocketService._internal();
  static final WebSocketService instance = WebSocketService._internal();
  factory WebSocketService() => instance;

  // ── State ───────────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  String? _userId;
  bool _intentionalClose = false;

  static const _reconnectDelay = Duration(seconds: 5);
  static const _pingInterval = Duration(seconds: 25);

  // ── Public Broadcast Stream ─────────────────────────────────────────────────
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  /// Listen to this stream for messages such as `{ type: 'ORDER_STATUS_UPDATE', ... }`
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call this once after the user logs in (e.g. in main.dart or after auth).
  /// Pass the authenticated user's Mongo `_id`.
  Future<void> connect({String? userId}) async {
    _intentionalClose = false;

    if (userId != null) {
      _userId = userId;
    } else {
      _userId ??= await _resolveUserId();
    }

    if (_userId == null) {
      debugPrint('[WS] No userId — aborting connect.');
      return;
    }

    _openConnection();
  }

  /// Gracefully disconnect (e.g. on logout).
  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    debugPrint('[WS] Disconnected intentionally.');
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<String?> _resolveUserId() async {
    // The JWT payload contains `userId` (the Mongo _id of the user).
    // We decode it client-side — this is safe because we only need the
    // user ID for the WebSocket query parameter; the server re-validates
    // the session via its own auth middleware.
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Base64url → base64 padding fix
      String payload = parts[1];
      payload = payload.padRight(
        payload.length + (4 - payload.length % 4) % 4,
        '=',
      );
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      return decoded['userId']?.toString() ??
          decoded['id']?.toString() ??
          decoded['_id']?.toString();
    } catch (e) {
      debugPrint('[WS] Failed to resolve userId from token: $e');
      return null;
    }
  }

  void _openConnection() {
    if (_userId == null) return;
    if (_intentionalClose) return;

    // Connect async: fetch token then open
    AuthService.getToken()
        .then((token) {
          if (_intentionalClose || _userId == null) return;
          try {
            _channelSubscription?.cancel();
            _pingTimer?.cancel();

            final tokenParam = token != null
                ? '&token=${Uri.encodeComponent(token)}'
                : '';
            final wsUri = Uri.parse(
              '${ApiConstants.wsUrl}?userId=$_userId$tokenParam',
            );
            _channel = WebSocketChannel.connect(wsUri);
            debugPrint('[WS] Connecting to $wsUri');

            _channelSubscription = _channel!.stream.listen(
              _onMessage,
              onDone: _onDone,
              onError: _onError,
              cancelOnError: false,
            );

            // Keep-alive ping every 25 seconds
            _pingTimer = Timer.periodic(_pingInterval, (_) {
              _safeSend({'type': 'PING'});
            });
          } catch (e) {
            debugPrint('[WS] Connection failed: $e');
            _scheduleReconnect();
          }
        })
        .catchError((e) {
          debugPrint('[WS] Failed to get token: $e');
          _scheduleReconnect();
        });
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      debugPrint('[WS] ← $type');

      if (type == 'CONNECTION_ACK') {
        debugPrint('[WS] ✅ Connected as user $_userId');
        return;
      }
      if (type == 'PONG') return;

      // Forward everything else (ORDER_STATUS_UPDATE, etc.) to listeners
      _messageController.add(data);
    } catch (_) {}
  }

  void _onDone() {
    debugPrint('[WS] Connection closed.');
    _pingTimer?.cancel();
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _pingTimer?.cancel();
    if (!_intentionalClose) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_intentionalClose) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      debugPrint('[WS] Reconnecting...');
      _openConnection();
    });
  }

  void _safeSend(Map<String, dynamic> data) {
    try {
      if (_channel != null) {
        _channel!.sink.add(jsonEncode(data));
      }
    } catch (_) {}
  }
}
