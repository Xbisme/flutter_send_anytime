import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/utils/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  void mock({bool throwError = false}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          if (throwError) throw PlatformException(code: 'no-haptics');
          return null;
        });
  }

  setUp(calls.clear);
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  MethodCall? lastVibrate() =>
      calls.where((c) => c.method == 'HapticFeedback.vibrate').lastOrNull;

  test('connect → medium impact', () async {
    mock();
    await Haptics.connect();
    expect(lastVibrate()?.arguments, 'HapticFeedbackType.mediumImpact');
  });

  test('complete → heavy impact', () async {
    mock();
    await Haptics.complete();
    expect(lastVibrate()?.arguments, 'HapticFeedbackType.heavyImpact');
  });

  test('fail → vibrate', () async {
    mock();
    await Haptics.fail();
    expect(lastVibrate(), isNotNull);
  });

  test('degrades gracefully — never throws when the platform errors', () async {
    mock(throwError: true);
    await expectLater(Haptics.connect(), completes);
    await expectLater(Haptics.complete(), completes);
    await expectLater(Haptics.fail(), completes);
  });
}

extension<E> on Iterable<E> {
  E? get lastOrNull {
    E? result;
    for (final e in this) {
      result = e;
    }
    return result;
  }
}
