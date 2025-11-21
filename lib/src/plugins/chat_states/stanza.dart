part of 'chat_states.dart';

/// XEP-0085 Chat State Namespace
const _chatStatesNamespace = 'http://jabber.org/protocol/chatstates';

/// Composing state - user is actively typing
class _ComposingStanza extends Stanza {
  @override
  xml.XmlElement toXML() => WhixpUtils.xmlElement(
        name,
        namespace: _chatStatesNamespace,
      );

  @override
  String get name => 'composing';
}

/// Paused state - user was typing but has stopped
class _PausedStanza extends Stanza {
  @override
  xml.XmlElement toXML() => WhixpUtils.xmlElement(
        name,
        namespace: _chatStatesNamespace,
      );

  @override
  String get name => 'paused';
}

/// Active state - user is actively participating in the conversation
class _ActiveStanza extends Stanza {
  @override
  xml.XmlElement toXML() => WhixpUtils.xmlElement(
        name,
        namespace: _chatStatesNamespace,
      );

  @override
  String get name => 'active';
}

/// Inactive state - user is not active but watching the conversation
class _InactiveStanza extends Stanza {
  @override
  xml.XmlElement toXML() => WhixpUtils.xmlElement(
        name,
        namespace: _chatStatesNamespace,
      );

  @override
  String get name => 'inactive';
}

/// Gone state - user has closed or left the conversation
class _GoneStanza extends Stanza {
  @override
  xml.XmlElement toXML() => WhixpUtils.xmlElement(
        name,
        namespace: _chatStatesNamespace,
      );

  @override
  String get name => 'gone';
}
