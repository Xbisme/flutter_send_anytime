import 'package:flutter/material.dart';

/// Lays out a flow screen body that centers/space-distributes its [child] when
/// there is room, but scrolls instead of overflowing on short screens. Use in
/// place of a `Padding` + `Column(... Spacer ...)` so `Spacer`/`Expanded` still
/// work while staying overflow-safe across device heights.
class FlowBody extends StatelessWidget {
  const FlowBody({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - padding.vertical,
            ),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
