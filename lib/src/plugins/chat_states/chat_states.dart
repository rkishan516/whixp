import 'package:whixp/src/stanza/message.dart';
import 'package:whixp/src/stanza/stanza.dart';
import 'package:whixp/src/utils/utils.dart';

import 'package:xml/xml.dart' as xml;

part 'stanza.dart';

/// XEP-0085: Chat State Notifications
///
/// This extension provides support for sending and receiving chat state
/// notifications (composing, paused, active, inactive, gone).
///
/// See: https://xmpp.org/extensions/xep-0085.html
extension ChatStates on Message {
  /// Add composing state to message (user is typing)
  ///
  /// ### Example:
  /// ```xml
  /// <message to='juliet@capulet.lit' type='chat'>
  ///   <composing xmlns='http://jabber.org/protocol/chatstates'/>
  /// </message>
  /// ```
  Message get makeComposing {
    addPayload(_ComposingStanza());
    return this;
  }

  /// Add paused state to message (user stopped typing)
  ///
  /// ### Example:
  /// ```xml
  /// <message to='juliet@capulet.lit' type='chat'>
  ///   <paused xmlns='http://jabber.org/protocol/chatstates'/>
  /// </message>
  /// ```
  Message get makePaused {
    addPayload(_PausedStanza());
    return this;
  }

  /// Add active state to message (user is actively participating)
  ///
  /// ### Example:
  /// ```xml
  /// <message to='juliet@capulet.lit' type='chat'>
  ///   <active xmlns='http://jabber.org/protocol/chatstates'/>
  /// </message>
  /// ```
  Message get makeActive {
    addPayload(_ActiveStanza());
    return this;
  }

  /// Add inactive state to message (user is not active but watching)
  ///
  /// ### Example:
  /// ```xml
  /// <message to='juliet@capulet.lit' type='chat'>
  ///   <inactive xmlns='http://jabber.org/protocol/chatstates'/>
  /// </message>
  /// ```
  Message get makeInactive {
    addPayload(_InactiveStanza());
    return this;
  }

  /// Add gone state to message (user has closed the conversation)
  ///
  /// ### Example:
  /// ```xml
  /// <message to='juliet@capulet.lit' type='chat'>
  ///   <gone xmlns='http://jabber.org/protocol/chatstates'/>
  /// </message>
  /// ```
  Message get makeGone {
    addPayload(_GoneStanza());
    return this;
  }

  /// Add chat state to message by state name
  ///
  /// Valid states: 'composing', 'paused', 'active', 'inactive', 'gone'
  Message makeChatState(String state) {
    switch (state.toLowerCase()) {
      case 'composing':
        return makeComposing;
      case 'paused':
        return makePaused;
      case 'active':
        return makeActive;
      case 'inactive':
        return makeInactive;
      case 'gone':
        return makeGone;
      default:
        throw ArgumentError('Invalid chat state: $state');
    }
  }
}
