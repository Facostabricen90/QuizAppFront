import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.textInputAction,
    this.readOnly = false,
    this.autofillHints,
  });

  final String label;

  final TextEditingController? controller;

  final TextInputType? keyboardType;

  final String? Function(String?)? validator;

  final IconData? prefixIcon;

  final TextInputAction? textInputAction;

  final bool readOnly;

  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      readOnly: readOnly,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
