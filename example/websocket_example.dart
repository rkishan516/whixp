import 'package:whixp/whixp.dart';

/// Example demonstrating how to use whixp with WebSocket connections.
///
/// This example shows how to connect to an XMPP server using WebSocket
/// protocol (RFC 7395) instead of traditional TCP sockets.
void main() async {
  // Example 1: Using a full WebSocket URL
  final whixpWs = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'wss://example.com:5280/websocket',
    useWebSocket: true,
  );

  // Example 2: Using host and port (will construct wss://example.com:5280/websocket)
  final whixpWsAuto = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'example.com',
    port: 5280,
    useWebSocket: true,
  );

  // Example 3: Using insecure WebSocket (ws://)
  final whixpWsInsecure = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'ws://example.com:5280/websocket',
    useWebSocket: true,
  );

  // Add event handlers
  whixpWs.addEventHandler('sessionStart', (_) {
    print('Session started successfully!');
  });

  whixpWs.addEventHandler('message', (message) {
    if (message is Message) {
      print('Received message: ${message.body}');
    }
  });

  // Connect to the server
  whixpWs.connect();

  // Keep the program running
  await Future.delayed(const Duration(hours: 1));
}

/// Example showing WebSocket with custom certificate handling
void customCertificateExample() {
  final whixp = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'wss://example.com:5280/websocket',
    useWebSocket: true,
    onBadCertificateCallback: (cert) {
      // Custom certificate validation logic
      print('Certificate Subject: ${cert.subject}');
      print('Certificate Issuer: ${cert.issuer}');

      // Return true to accept the certificate, false to reject
      return true;
    },
  );

  whixp.connect();
}

/// Example comparing traditional TCP/TLS vs WebSocket
void comparisonExample() {
  // Traditional TCP connection (default)
  final traditionalClient = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'example.com',
    port: 5222,
    // useWebSocket is false by default
  );

  // WebSocket connection
  final websocketClient = Whixp(
    jabberID: 'user@example.com',
    password: 'password',
    host: 'wss://example.com:5280/websocket',
    useWebSocket: true,
  );

  // Both have the same API
  traditionalClient.connect();
  websocketClient.connect();
}
