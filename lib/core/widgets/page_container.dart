import 'package:flutter/material.dart';

/// Keeps the mobile-first layout readable on web/desktop.
///
/// Also adds the device bottom inset so scrollable content always clears the
/// floating bottom navigation on phones with a home indicator.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 120),
    this.maxWidth = 560,
  });

  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
          child: child,
        ),
      ),
    );
  }
}
