import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/colors.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPasswordField;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPasswordField = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPasswordField;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textCharcoal),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: AppColors.textLight.withOpacity(0.6),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          color: AppColors.textLight.withOpacity(0.8),
          size: 20,
        ),
        suffixIcon: widget.isPasswordField
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                onLongPressStart: (_) {
                  setState(() {
                    _obscureText = false;
                  });
                },
                onLongPressEnd: (_) {
                  setState(() {
                    _obscureText = true;
                  });
                },
                child: Icon(
                  _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                  color: AppColors.textLight.withOpacity(0.8),
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF5F6F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
