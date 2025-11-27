import 'package:whixp/src/stanza/stanza.dart';
import 'package:whixp/src/utils/utils.dart';

import 'package:xml/xml.dart' as xml;

final _namespace = WhixpUtils.getNamespace('SESSION');

/// Represents a Session IQ stanza used in XMPP communication.
///
/// This is used for session establishment after resource binding.
/// See RFC 6120 for details.
class XMPPSession extends IQStanza {
  static const String _name = 'session';

  const XMPPSession();

  factory XMPPSession.fromXML(xml.XmlElement _) {
    return const XMPPSession();
  }

  @override
  xml.XmlElement toXML() {
    final element = WhixpUtils.makeGenerator();
    element.element(
      name,
      attributes: <String, String>{'xmlns': namespace},
    );

    return element.buildDocument().rootElement;
  }

  @override
  String get name => _name;

  @override
  String get namespace => _namespace;

  @override
  String get tag => '{$namespace}$name';
}
