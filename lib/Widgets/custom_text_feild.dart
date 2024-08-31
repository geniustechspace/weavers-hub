import 'package:flutter/material.dart';


class CustomInputField extends StatefulWidget {
  final String hintText;
  final String? Function(String?)? validator;
  final TextEditingController textEditingController;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool showVisibilityToggle; // Added property for visibility toggle

  const CustomInputField({
    super.key,
    required this.hintText,
    required this.textEditingController,
    required this.validator,
    required this.keyboardType,
    this.obscureText = false,
    this.showVisibilityToggle = false, // Default to false
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
          )
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 30),
        child: TextFormField(
          obscureText: widget.obscureText && isObscured,
          keyboardType: widget.keyboardType,
          controller: widget.textEditingController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
            ),
            border: InputBorder.none,
            suffixIcon: widget.showVisibilityToggle
                ? IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  isObscured = !isObscured;
                });
              },
            )
                : null,
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}