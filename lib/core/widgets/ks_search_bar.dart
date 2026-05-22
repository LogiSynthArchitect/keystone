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

class _KsSearchBarState extends State<KsSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
    _isFocused = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller?.text.isNotEmpty == true;
    final iconColor = _isFocused || hasText ? context.ksc.accent500 : context.ksc.neutral500;

    return TextField(
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
        prefixIcon: Icon(LineAwesomeIcons.search_solid, color: iconColor, size: 16),
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
        border: UnderlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700, width: 1)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700, width: 1)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.ksc.accent500, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
        filled: false,
        fillColor: Colors.transparent,
      ),
    );
  }
}