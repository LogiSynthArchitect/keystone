import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
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

class _KsSearchBarState extends State<KsSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _isFocused = _focusNode.hasFocus;
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused ? context.ksc.accent500 : context.ksc.primary700;
    final borderWidth = _isFocused ? 2.0 : 1.0;
    final iconColor = _isFocused ? context.ksc.accent500 : context.ksc.neutral500;

    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: _isFocused
            ? [BoxShadow(color: context.ksc.accent500.withValues(alpha: 0.12), blurRadius: 8, spreadRadius: 0)]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 1.0),
          prefixIcon: Icon(LineAwesomeIcons.search_solid, color: iconColor, size: 20),
          suffixIcon: widget.onClear != null && widget.controller?.text.isNotEmpty == true
              ? GestureDetector(
                  onTap: widget.onClear,
                  child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
