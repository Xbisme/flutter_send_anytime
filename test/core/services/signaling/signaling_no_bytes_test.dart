import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';

/// Categorize a signaling message. This exhaustive switch is the structural
/// guarantee that signaling carries metadata only — if a byte-carrying variant
/// were ever added to [SignalingMessage], this would stop compiling (SC-007).
String _kind(SignalingMessage message) => switch (message) {
  SignalingOffer() => 'sdp',
  SignalingAnswer() => 'sdp',
  SignalingIceCandidate() => 'ice',
  SignalingBye() => 'control',
};

void main() {
  test('every SignalingMessage variant is SDP/ICE/control — never bytes', () {
    expect(_kind(const SignalingMessage.offer(sdp: 'o')), 'sdp');
    expect(_kind(const SignalingMessage.answer(sdp: 'a')), 'sdp');
    expect(
      _kind(const SignalingMessage.iceCandidate(candidate: 'c')),
      'ice',
    );
    expect(_kind(const SignalingMessage.bye()), 'control');
  });
}
