import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:hadrami_nlp/src/configs/app_radius.dart';

/// Visual treatment for [AppTextField].
///
/// - [standard]: relies on the app's global `InputDecorationTheme` (rounded
///   border, filled surface). Use for most fields.
/// - [pill]: borderless, meant to sit inside a caller-provided pill-shaped
///   container (see `ChatInput`).
/// - [compact]: filled with a caller-controlled corner radius, for fields
///   that need a distinct look from the global theme.
enum AppTextFieldVariant { standard, pill, compact }

/// Single reusable text input covering every text field in the app: plain
/// controller-driven fields and `reactive_forms`-bound fields alike. Pass
/// exactly one of [controller] or [formControlName].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.formControlName,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.textDirection = TextDirection.rtl,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.validationMessages,
    this.inputFormatters,
    this.variant = AppTextFieldVariant.standard,
    this.enabled = true,
    this.autofocus = false,
    this.isDense = false,
    this.alignLabelWithHint = false,
    this.style,
    this.borderRadius,
  }) : assert(
          (controller == null) != (formControlName == null),
          'Provide exactly one of controller or formControlName',
        );

  final TextEditingController? controller;
  final String? formControlName;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextDirection textDirection;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final Map<String, ValidationMessageFunction>? validationMessages;
  final List<TextInputFormatter>? inputFormatters;
  final AppTextFieldVariant variant;
  final bool enabled;
  final bool autofocus;
  final bool isDense;
  final bool alignLabelWithHint;
  final TextStyle? style;

  /// Corner radius override. Only honored by [AppTextFieldVariant.compact];
  /// [AppTextFieldVariant.standard] always uses the global theme's radius
  /// and [AppTextFieldVariant.pill] is borderless by design.
  final BorderRadius? borderRadius;

  InputDecoration _decoration(ColorScheme colorScheme) {
    switch (variant) {
      case AppTextFieldVariant.pill:
        return InputDecoration(
          hintText: hintText,
          hintTextDirection: textDirection,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: isDense,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          hintStyle: TextStyle(color: colorScheme.outline, fontSize: 14),
        );
      case AppTextFieldVariant.compact:
        return InputDecoration(
          hintText: hintText,
          hintTextDirection: textDirection,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: isDense,
          alignLabelWithHint: alignLabelWithHint,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: borderRadius ?? AppRadius.md,
          ),
        );
      case AppTextFieldVariant.standard:
        return InputDecoration(
          hintText: hintText,
          hintTextDirection: textDirection,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          isDense: isDense,
          alignLabelWithHint: alignLabelWithHint,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _decoration(Theme.of(context).colorScheme);

    if (formControlName != null) {
      return ReactiveTextField<String>(
        formControlName: formControlName!,
        textDirection: textDirection,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        minLines: minLines,
        maxLines: maxLines,
        onSubmitted:
            onSubmitted == null ? null : (_) => onSubmitted!(),
        inputFormatters: inputFormatters,
        validationMessages: validationMessages,
        style: style,
        decoration: decoration,
      );
    }

    return TextField(
      controller: controller,
      textDirection: textDirection,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      inputFormatters: inputFormatters,
      enabled: enabled,
      autofocus: autofocus,
      style: style,
      decoration: decoration,
    );
  }
}
