import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_send/core/presentation/inputs/code_box.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Editable 6-digit pairing-code entry (#005 receiver side). Renders a row of
/// [CodeBox] cells driven by a transparent text field: digit-only, fixed length,
/// leading zeros preserved. Calls [onChanged] on every edit and [onCompleted]
/// once all [length] digits are entered. Reusable by #007/#009.
class CodeInput extends StatefulWidget {
  const CodeInput({
    required this.onChanged,
    this.onCompleted,
    this.length = 6,
    this.semanticLabel,
    super.key,
  });

  /// Fired on every edit with the current (digit-only) value.
  final ValueChanged<String> onChanged;

  /// Fired once exactly [length] digits are present.
  final ValueChanged<String>? onCompleted;

  /// Number of digit cells.
  final int length;

  /// Accessibility label for the field.
  final String? semanticLabel;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp('[^0-9]'), '');
    final clamped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (clamped != _controller.text) {
      _controller.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
    }
    setState(() {});
    widget.onChanged(clamped);
    if (clamped.length == widget.length) widget.onCompleted?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.x2),
                  CodeBox(
                    value: i < text.length ? text[i] : null,
                    focused: i == text.length,
                  ),
                ],
              ],
            ),
            // Transparent capture field over the cells (kept in the tree so the
            // platform keyboard + tests can drive it).
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  showCursor: false,
                  maxLength: widget.length,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _onChanged,
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
