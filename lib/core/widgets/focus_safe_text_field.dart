import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ks_colors.dart';

/// A [TextField] wrapper that owns its [TextEditingController] and [FocusNode],
/// so parent rebuilds never detach the text field's render tree (preventing
/// keyboard dismissal on Android).
///
/// ## Why this exists
/// Flutter loses keyboard focus when `setState()` rebuilds the widget tree
/// above a [TextField] (see flutter/flutter#96345). By isolating the controller
/// and focus node inside this `StatefulWidget`, the parent can rebuild freely
/// without affecting the text field's render object.
///
/// ## Key properties
/// - [initialText] — set once at build time; changes are ignored (no [controller])
/// - [onChanged], [onSubmitted] — fire without any parent [setState]
/// - [focusOnSubmitted] — focus node to request focus when this field is submitted
/// - [obscureText] — password mode; eye toggle is handled internally via
///   [ValueNotifier<bool>] with zero parent involvement
/// - [validator] — returns null if valid, error string otherwise; displayed inline
class FocusSafeTextField extends StatefulWidget {
  final String? initialText;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusOnSubmitted;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? maxLength;

  const FocusSafeTextField({
    super.key,
    this.initialText,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusOnSubmitted,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<FocusSafeTextField> createState() => _FocusSafeTextFieldState();
}

class _FocusSafeTextFieldState extends State<FocusSafeTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final ValueNotifier<bool> _obscured = ValueNotifier(true);
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _obscured.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Validate inline without setState — error is shown via ValueNotifier.
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        _errorText = error;
        (context as Element).markNeedsBuild();
      }
    }
    widget.onChanged?.call(value);
  }

  void _onSubmitted(String value) {
    widget.onSubmitted?.call(value);
    if (widget.focusOnSubmitted != null) {
      widget.focusOnSubmitted!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ksc = context.ksc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontFamily: 'BarlowSemiCondensed',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: ksc.neutral400,
              ),
            ),
          ),
        Row(
          children: [
            if (widget.prefix != null) widget.prefix!,
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                onSubmitted: _onSubmitted,
                obscureText: widget.obscureText ? _obscured.value : false,
                autofocus: widget.autofocus,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction ?? TextInputAction.next,
                textCapitalization: widget.textCapitalization,
                inputFormatters: widget.inputFormatters,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                style: TextStyle(
                  fontFamily: 'BarlowSemiCondensed',
                  fontSize: widget.obscureText ? 18 : 17,
                  fontWeight: FontWeight.w600,
                  color: ksc.white,
                ),
                cursorColor: ksc.accent500,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    fontFamily: 'BarlowSemiCondensed',
                    fontSize: widget.obscureText ? 18 : 17,
                    fontWeight: FontWeight.w500,
                    color: ksc.neutral500,
                  ),
                  contentPadding: widget.obscureText
                      ? const EdgeInsets.symmetric(vertical: 12)
                      : EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  errorText: _errorText,
                ),
              ),
            ),
            if (widget.obscureText)
              GestureDetector(
                onTap: () => _obscured.value = !_obscured.value,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _obscured,
                    builder: (_, obscured, __) => Icon(
                      obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: ksc.neutral400.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            if (widget.suffix != null) widget.suffix!,
          ],
        ),
        // Gradient underline
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ksc.accent500,
                ksc.primary500,
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }
}
