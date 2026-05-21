import 'package:flutter/material.dart';

/// Wraps body content with an animated slide-down search panel.
///
/// The search panel animates in/out from the top of the body area.
/// The body content (child) is wrapped in [Expanded] so it adjusts
/// automatically — no overflow, no empty space when closed.
///
/// Chips/filters should be rendered as a permanent header BEFORE this
/// widget, so they're always visible regardless of search state.
class SearchPanelBody extends StatelessWidget {
  final bool isOpen;
  final Widget searchContent;
  final Widget child;

  const SearchPanelBody({
    super.key,
    required this.isOpen,
    required this.searchContent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isOpen ? searchContent : const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}