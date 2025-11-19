import 'dart:async' as async;
import 'dart:io' as io;

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:whixp/src/enums.dart';
import 'package:whixp/src/log/log.dart';
import 'package:whixp/src/utils/utils.dart';

/// WebSocket connection handler for XMPP over WebSocket (RFC 7395).
///
/// This class manages WebSocket connections for XMPP, handling the WebSocket
/// protocol handshake and message framing.
class WebSocketConnection {
  WebSocketConnection({
    required this.url,
    required this.onData,
    required this.onDone,
    required this.onError,
    required this.changeStateCallback,
    this.securityContext,
    this.onBadCertificateCallback,
    this.connectionTimeout = 2000,
  });

  /// The WebSocket URL to connect to (e.g., wss://example.com:5280/websocket)
  final String url;

  /// Callback when data is received
  final void Function(List<int> data) onData;

  /// Callback when connection is closed
  final void Function() onDone;

  /// Callback when an error occurs
  final void Function(dynamic exception) onError;

  /// Callback to notify state changes
  final void Function(TransportState state) changeStateCallback;

  /// Optional security context for WSS connections
  final io.SecurityContext? securityContext;

  /// Callback to handle bad certificates
  final bool Function(io.X509Certificate)? onBadCertificateCallback;

  /// Connection timeout in milliseconds
  final int connectionTimeout;

  /// The active WebSocket channel
  WebSocketChannel? _channel;

  /// Subscription to the WebSocket stream
  async.StreamSubscription<dynamic>? _subscription;

  /// Whether the connection is currently active
  bool get isConnected => _channel != null;

  /// Whether the connection is secure (WSS)
  bool get isSecure => url.startsWith('wss://');

  /// Connect to the WebSocket server
  Future<void> connect() async {
    try {
      Log.instance.info('Connecting to WebSocket: $url');
      changeStateCallback(TransportState.connecting);

      // Create WebSocket connection with timeout
      final socket = await io.WebSocket.connect(
        url,
        customClient: _createHttpClient(),
      ).timeout(
        Duration(milliseconds: connectionTimeout),
        onTimeout: () {
          throw async.TimeoutException('WebSocket connection timed out');
        },
      );

      _channel = IOWebSocketChannel(socket);

      // Listen to incoming messages
      _subscription = _channel!.stream.listen(
        (data) {
          if (data is String) {
            // Convert string to bytes
            onData(WhixpUtils.utf8Encode(data));
          } else if (data is List<int>) {
            onData(data);
          }
        },
        onDone: () {
          Log.instance.warning('WebSocket connection closed');
          onDone();
        },
        onError: (error) {
          Log.instance.error('WebSocket error: $error');
          onError(error);
        },
      );

      changeStateCallback(TransportState.connected);
      Log.instance.info('WebSocket connected successfully');
    } catch (exception) {
      Log.instance.error('Failed to connect to WebSocket: $exception');
      changeStateCallback(TransportState.connectionFailure);
      onError(exception);
      rethrow;
    }
  }

  /// Create HTTP client with custom security context and certificate handling
  io.HttpClient _createHttpClient() {
    final client = io.HttpClient(context: securityContext);

    if (onBadCertificateCallback != null) {
      client.badCertificateCallback = (cert, host, port) {
        return onBadCertificateCallback!(cert);
      };
    }

    return client;
  }

  /// Send data through the WebSocket
  void send(String data) {
    if (_channel == null) {
      Log.instance.warning('Cannot send data: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(data);
      Log.instance.debug('SENT (WebSocket): $data');
    } catch (exception) {
      Log.instance.error('Failed to send data: $exception');
      onError(exception);
    }
  }

  /// Close the WebSocket connection
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (_channel == null) return;

    Log.instance.info('Closing WebSocket connection');

    try {
      await _subscription?.cancel();
      await _channel!.sink.close(closeCode, closeReason);
    } catch (exception) {
      Log.instance.warning('Error while closing WebSocket: $exception');
    } finally {
      _channel = null;
      _subscription = null;
      changeStateCallback(TransportState.disconnected);
    }
  }

  /// Forcefully destroy the connection
  void destroy() {
    _subscription?.cancel();
    _channel = null;
    _subscription = null;
  }
}
