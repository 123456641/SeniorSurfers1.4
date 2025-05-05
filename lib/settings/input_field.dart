import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final String initialValue;
  final TextInputType inputType;
  final bool obscureText;

  const InputField({
    required this.label,
    this.initialValue = '',
    this.inputType = TextInputType.text,
    this.obscureText = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: inputType,
      obscureText: obscureText,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
