import 'dart:async';

import 'package:whixp/src/handler/handler.dart';
import 'package:whixp/src/handler/matcher.dart';
import 'package:whixp/src/handler/router.dart';
import 'package:whixp/src/jid/jid.dart';
import 'package:whixp/src/log/log.dart';
import 'package:whixp/src/stanza/error.dart';
import 'package:whixp/src/stanza/iq.dart';
import 'package:whixp/src/stanza/mixins.dart';
import 'package:whixp/src/stanza/stanza.dart';
import 'package:whixp/src/transport.dart';

/// Matcher for ping IQ stanzas
class _PingMatcher extends Matcher {
  _PingMatcher() : super('ping-matcher');

  @override
  bool match(Packet packet) {
    if (packet is! IQ) return false;
    if (packet.type != 'get') return false;

    // Check if the payload is a PingStanza (properly parsed)
    if (packet.payload is PingStanza) {
      return true;
    }

    // Fallback: check if the IQ contains a ping element by looking at the XML
    final xml = packet.toXML();
    for (final child in xml.childElements) {
      if (child.localName == 'ping' &&
          child.getAttribute('xmlns') == _pingNamespace) {
        return true;
      }
    }

    // Also check the 'any' node which contains unrecognized children
    if (packet.any != null && packet.any!.name == 'ping') {
      return true;
    }

    return false;
  }
}

/// XEP-0199 Ping namespace
const _pingNamespace = 'urn:xmpp:ping';

/// Result of a ping operation.
class PingResult {
  const PingResult._({
    required this.success,
    this.rtt,
    this.error,
  });

  /// Creates a successful ping result with round-trip time.
  factory PingResult.success(Duration rtt) => PingResult._(
        success: true,
        rtt: rtt,
      );

  /// Creates a failed ping result with an error.
  factory PingResult.failure([ErrorStanza? error]) => PingResult._(
        success: false,
        error: error,
      );

  /// Creates a timeout ping result.
  factory PingResult.timeout() => const PingResult._(
        success: false,
      );

  /// Whether the ping was successful.
  final bool success;

  /// Round-trip time for successful pings.
  final Duration? rtt;

  /// Error stanza for failed pings.
  final ErrorStanza? error;

  /// Whether the ping timed out.
  bool get isTimeout => !success && error == null;
}

/// XEP-0199: XMPP Ping
///
/// This plugin handles ping IQ stanzas from the server and responds
/// appropriately to keep the connection alive. It also provides methods
/// to send ping requests to the server or other entities.
///
/// See: https://xmpp.org/extensions/xep-0199.html
class PingPlugin {
  static const String handlerName = 'ping_handler';

  /// Register the ping handler to respond to incoming pings
  static void register() {
    final handler = Handler(handlerName, _handlePing)
      ..addMatcher(_PingMatcher());
    Router.addHandler(handler);
  }

  /// Unregister the ping handler
  static void unregister() {
    Router.removeHandler(handlerName);
  }

  /// Handle incoming ping IQ and respond with result
  static Future<void> _handlePing(Packet packet) async {
    if (packet is! IQ) return;

    // Create result response
    final response = IQ()
      ..id = packet.id
      ..type = 'result'
      ..to = packet.from;
    // Don't set 'from' - server will fill it in

    Transport.instance().send(response);
  }

  /// Sends a ping to the server (the domain of the bound JID).
  ///
  /// Returns a [Future] that completes with a [PingResult] containing:
  /// - [PingResult.success] with round-trip time if successful
  /// - [PingResult.failure] with error if the ping failed
  /// - [PingResult.timeout] if the ping timed out
  ///
  /// [timeout] specifies how long to wait for a response (default: 30 seconds).
  ///
  /// Example:
  /// ```dart
  /// final result = await PingPlugin.ping();
  /// if (result.success) {
  ///   print('Ping successful! RTT: ${result.rtt?.inMilliseconds}ms');
  /// } else if (result.isTimeout) {
  ///   print('Ping timed out');
  /// } else {
  ///   print('Ping failed: ${result.error}');
  /// }
  /// ```
  static Future<PingResult> ping({int timeout = 30}) async {
    final transport = Transport.instance();
    final serverJid = transport.boundJID?.domain;
    if (serverJid == null) {
      Log.instance.warning('Cannot ping: no bound JID');
      return PingResult.failure();
    }
    return pingEntity(JabberID(serverJid), timeout: timeout);
  }

  /// Sends a ping to a specific XMPP entity.
  ///
  /// [jid] is the JabberID of the entity to ping.
  /// [timeout] specifies how long to wait for a response (default: 30 seconds).
  ///
  /// Returns a [Future] that completes with a [PingResult].
  ///
  /// Example:
  /// ```dart
  /// final result = await PingPlugin.pingEntity(
  ///   JabberID('user@example.com'),
  ///   timeout: 10,
  /// );
  /// if (result.success) {
  ///   print('Entity is reachable! RTT: ${result.rtt?.inMilliseconds}ms');
  /// }
  /// ```
  static Future<PingResult> pingEntity(
    JabberID jid, {
    int timeout = 30,
  }) async {
    final startTime = DateTime.now();

    final iq = IQ(generateID: true)
      ..type = 'get'
      ..to = jid
      ..payload = const PingStanza();

    try {
      final response = await iq.send(
        timeout: timeout,
        timeoutCallback: () {
          Log.instance.warning('Ping to $jid timed out');
        },
      );

      if (response.type == 'result') {
        final rtt = DateTime.now().difference(startTime);
        return PingResult.success(rtt);
      } else if (response.type == 'error') {
        return PingResult.failure(response.error);
      }

      return PingResult.failure();
    } catch (e) {
      Log.instance.error('Ping error: $e');
      return PingResult.timeout();
    }
  }

  /// Sends a ping and calls the provided callback with the result.
  ///
  /// This is a convenience method for callback-based code.
  ///
  /// [jid] is the optional JabberID to ping. If null, pings the server.
  /// [onResult] is called with the [PingResult] when the ping completes.
  /// [timeout] specifies how long to wait for a response.
  static void sendPing({
    JabberID? jid,
    required void Function(PingResult result) onResult,
    int timeout = 30,
  }) {
    final future = jid != null
        ? pingEntity(jid, timeout: timeout)
        : ping(timeout: timeout);

    future.then(onResult);
  }
}
