import 'package:in_app_review/in_app_review.dart';
import 'package:injectable/injectable.dart';

/// Triggers the platform's native rate/review experience (#010, FR-018).
// ignore: one_member_abstracts
abstract interface class AppReviewService {
  /// Request the in-app review flow when available.
  Future<void> requestReview();
}

/// `in_app_review`-backed implementation.
@LazySingleton(as: AppReviewService)
class InAppReviewService implements AppReviewService {
  final InAppReview _review = InAppReview.instance;

  @override
  Future<void> requestReview() async {
    if (await _review.isAvailable()) {
      await _review.requestReview();
    } else {
      await _review.openStoreListing();
    }
  }
}
