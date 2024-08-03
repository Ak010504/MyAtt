import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    Key? key,
    required this.hint,
    required this.label,
    this.controller,
    this.isPassword = false,
  }) : super(key: key);

  final String hint;
  final String label;
  final bool isPassword;
  final TextEditingController? controller;

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: widget.isPassword && _isObscure,
      controller: widget.controller,
      decoration: InputDecoration(
        hintText: widget.hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        labelText: widget.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        )
            : null,
      ),
    );
  }
}
