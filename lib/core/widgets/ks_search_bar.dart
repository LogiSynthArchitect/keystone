import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/ks_colors.dart';

class KsSearchBar extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool autofocus;

  const KsSearchBar({
    super.key,
    this.hint = 'SEARCH...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<KsSearchBar> createState() => _KsSearchBarState();
}

class _KsSearchBarState extends State<KsSearchBar> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _underlineController;
  late Animation<double> _underlineWidth;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _isFocused = _focusNode.hasFocus;

    _underlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _underlineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _underlineController, curve: Curves.easeOut),
    );

    if (_isFocused) _underlineController.value = 1.0;
  }

  void _onFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void didUpdateWidget(KsSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger underline animation when text changes (has content = stays focused)
  }

  @override
  void dispose() {
    _underlineController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller?.text.isNotEmpty == true;
    final iconColor = _isFocused || hasText ? context.ksc.accent500 : context.ksc.neutral500;

    // Animate underline when focus changes
    if (_isFocused && !_underlineController.isCompleted) {
      _underlineController.forward();
    } else if (!_isFocused && _underlineController.isCompleted) {
      _underlineController.reverse();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(LineAwesomeIcons.search_solid, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                },
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: TextStyle(color: context.ksc.white, fontSize: 14, fontWeight: FontWeight.w300),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: context.ksc.neutral600, fontSize: 13, fontWeight: FontWeight.w300),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                  suffixIcon: hasText && widget.onClear != null
                      ? GestureDetector(
                          onTap: () {
                            widget.controller?.clear();
                            widget.onClear?.call();
                            setState(() {});
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 14),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        AnimatedBuilder(
          animation: _underlineWidth,
          builder: (context, child) {
            return FractionallySizedBox(
              widthFactor: _underlineWidth.value,
              child: Container(height: 1.5, color: context.ksc.accent500),
            );
          },
        ),
      ],
    );
  }
}
