import 'package:flutter/material.dart';
import 'package:safe_send/core/presentation/inputs/code_box.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Read-only row of [CodeBox] cells displaying the issued 6-digit code.
class CodeDisplay extends StatelessWidget {
  const CodeDisplay({required this.code, super.key});

  /// The code value (leading zeros preserved).
  final String code;

  @override
  Widget build(BuildContext context) {
    final digits = code.split('');
    return Semantics(
      label: digits.join(' '),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < digits.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.x2),
              CodeBox(value: digits[i]),
            ],
          ],
        ),
      ),
    );
  }
}
