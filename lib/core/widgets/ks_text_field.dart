import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/ks_colors.dart';

enum KsTextFieldType { text, phone, amount, multiline, search }

class KsTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final KsTextFieldType type;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;

  const KsTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.type = KsTextFieldType.text,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          keyboardType: _keyboardType,
          inputFormatters: _inputFormatters,
          maxLines: type == KsTextFieldType.multiline ? 5 : 1,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral400),
            errorText: errorText,
            helperText: helperText,
            prefixText: type == KsTextFieldType.amount ? 'GHS ' : null,
            prefixIcon: type == KsTextFieldType.phone
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('+233', style: TextStyle(color: context.ksc.neutral700)),
                  )
                : type == KsTextFieldType.search
                    ? Icon(Icons.search, color: context.ksc.neutral400)
                    : null,
            prefixIconConstraints: type == KsTextFieldType.phone
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
          ),
        ),
      ],
    );
  }

  TextInputType get _keyboardType {
    switch (type) {
      case KsTextFieldType.phone:  return TextInputType.text;
      case KsTextFieldType.amount: return TextInputType.text;
      case KsTextFieldType.multiline: return TextInputType.multiline;
      default: return TextInputType.text;
    }
  }

  List<TextInputFormatter> get _inputFormatters {
    if (type == KsTextFieldType.amount) {
      return [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))];
    }
    if (type == KsTextFieldType.phone) {
      return [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]'))];
    }
    return [];
  }
}
