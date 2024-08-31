import 'package:quill_ai/core/extension/context.dart';
import 'package:quill_ai/core/util/validators.dart';
import 'package:flutter/material.dart';

class InputField extends StatefulWidget {
  const InputField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    super.key,
  });

  const InputField.api({
    required TextEditingController controller,
    String label = 'Enter API Key',
    TextInputAction textInputAction = TextInputAction.done,
    Key? key,
  }) : this(
          key: key,
          controller: controller,
          label: label,
          textInputAction: textInputAction,
          keyboardType: TextInputType.url,
          autofillHints: const [AutofillHints.url],
          validator: Validators.apiKey,
        );

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final List<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;
  late bool _isPassword;

  @override
  void initState() {
    _isPassword = widget.keyboardType == TextInputType.visiblePassword;
    _obscureText = _isPassword;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant InputField oldWidget) {
    if (oldWidget.keyboardType != widget.keyboardType) {
      _isPassword = widget.keyboardType == TextInputType.visiblePassword;
      _obscureText = _isPassword;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final validator =
        widget.validator ?? Validators.getValidator(widget.keyboardType);

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      validator: validator,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: Colors.black),
        suffixIcon: _isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: _obscureText
                    ? const Icon(Icons.visibility_off)
                    : const Icon(Icons.visibility_sharp),
              )
            : null,
        filled: true, // Add this line
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: const TextStyle(color: Colors.black),  // Input text color
      cursorColor: Colors.black, // Cursor color
    );
  }
}