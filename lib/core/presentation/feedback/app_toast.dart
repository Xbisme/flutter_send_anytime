import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Toast severity.
enum AppToastType { success, error, info }

/// Centralized toast utility. Always use this — never call
/// `ScaffoldMessenger.showSnackBar` directly (Constitution VI).
abstract final class AppToast {
  /// Show a transient [message] toast.
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
  }) {
    toastification.show(
      context: context,
      type: switch (type) {
        AppToastType.success => ToastificationType.success,
        AppToastType.error => ToastificationType.error,
        AppToastType.info => ToastificationType.info,
      },
      style: ToastificationStyle.flatColored,
      title: Text(message),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}
