import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/file/received_files_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = ReceivedFilesServiceImpl();

  // The service wraps the share/open plugins so the cubit never sees a throw
  // (Constitution V). With no method-channel handler registered in the test the
  // plugins throw, which the service must catch and map to a Result.failure.

  test('open maps a platform failure to a Result.failure', () async {
    final result = await service.open('/does/not/exist.bin');
    expect(result, isA<Failure<void>>());
  });

  test('share maps a platform failure to a Result.failure', () async {
    final result = await service.share(['/does/not/exist.bin']);
    expect(result, isA<Failure<void>>());
  });
}
