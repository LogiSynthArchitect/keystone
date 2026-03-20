import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

class KsSearchBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        focusNode: focusNode,
        autofocus: autofocus,
        style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
        cursorColor: context.ksc.accent500,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, letterSpacing: 1.0),
          prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 20),
          suffixIcon: onClear != null && controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: Icon(LineAwesomeIcons.times_solid, size: 18, color: context.ksc.neutral500),
                  onPressed: onClear,
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
