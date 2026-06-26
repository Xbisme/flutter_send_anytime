import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/services/app_info_service.dart';
import 'package:safe_send/core/services/app_review_service.dart';
import 'package:safe_send/features/settings/presentation/pages/how_it_works_page.dart';
import 'package:safe_send/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:safe_send/features/settings/presentation/widgets/about_section.dart';

import '../../../helpers/pump_app.dart';

class _FakeAppInfo implements AppInfoService {
  @override
  Future<String> version() async => '9.9.9';
}

class _FakeReview implements AppReviewService {
  int count = 0;
  @override
  Future<void> requestReview() async => count++;
}

void main() {
  testWidgets('about section shows the build version + tagline (FR-016)', (
    tester,
  ) async {
    final review = _FakeReview();
    await tester.pumpApp(
      Scaffold(
        body: AboutSection(appInfo: _FakeAppInfo(), review: review),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('9.9.9'), findsOneWidget);
    expect(find.textContaining('WebRTC P2P'), findsOneWidget);
    expect(find.text('Cách hoạt động'), findsOneWidget);
    expect(find.text('Chính sách bảo mật'), findsOneWidget);
  });

  testWidgets('tapping rate invokes the review service (FR-018)', (
    tester,
  ) async {
    final review = _FakeReview();
    await tester.pumpApp(
      Scaffold(
        body: AboutSection(appInfo: _FakeAppInfo(), review: review),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đánh giá ứng dụng'));
    await tester.pump();
    expect(review.count, 1);
  });

  testWidgets('how-it-works page renders the no-server explainer (FR-017)', (
    tester,
  ) async {
    await tester.pumpApp(const HowItWorksPage());
    expect(find.textContaining('không bao giờ'), findsOneWidget);
  });

  testWidgets('privacy page renders its body (FR-017)', (tester) async {
    await tester.pumpApp(const PrivacyPolicyPage());
    expect(find.textContaining('không có máy chủ đám mây'), findsOneWidget);
  });
}
