import 'package:flutter/material.dart';

/// Centers [child] when it fits the viewport, and scrolls it (instead of a
/// RenderFlex overflow) when the viewport is too short — e.g. small devices,
/// large text scaling, or the keyboard rising. The child may use `Spacer`/
/// `Expanded` for vertical centering; do NOT use it around a child that itself
/// has an unbounded vertical child (e.g. `Expanded(ListView)`), which has no
/// intrinsic height.
class FitOrScroll extends StatelessWidget {
  const FitOrScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
