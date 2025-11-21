import 'package:whixp/src/handler/handler.dart';
import 'package:whixp/src/handler/matcher.dart';
import 'package:whixp/src/handler/router.dart';
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

/// XEP-0199: XMPP Ping
///
/// This plugin handles ping IQ stanzas from the server and responds
/// appropriately to keep the connection alive.
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
}
