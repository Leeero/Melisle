import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';

class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final AutovalidateMode autovalidateMode;

  static String? validateHttpUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'URL 格式无效，必须以 http:// 或 https:// 开头';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final effectiveHelper = errorText == null ? helperText : null;

    return Semantics(
      textField: true,
      label: label,
      enabled: enabled,
      readOnly: readOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: errorText != null
                  ? colors.error
                  : enabled
                  ? colors.onSurface
                  : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacingTokens.formLabelGap),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            validator: validator,
            onFieldSubmitted: onSubmitted,
            obscureText: obscureText,
            enabled: enabled,
            readOnly: readOnly,
            autovalidateMode: autovalidateMode,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: enabled ? colors.onSurface : colors.onSurfaceVariant,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              helperText: effectiveHelper,
              errorText: errorText,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: readOnly
                  ? colors.surfaceContainerHigh
                  : colors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.cardPadding,
                vertical: AppSpacingTokens.formFieldVerticalPadding,
              ),
              constraints: const BoxConstraints(minHeight: 48),
              border: _border(colors.outlineVariant),
              enabledBorder: _border(colors.outlineVariant),
              disabledBorder: _border(colors.outlineVariant),
              focusedBorder: _border(colors.primary, width: AppBorderTokens.focus),
              errorBorder: _border(colors.error),
              focusedErrorBorder: _border(colors.error, width: AppBorderTokens.focus),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = AppBorderTokens.thin}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadiusTokens.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
