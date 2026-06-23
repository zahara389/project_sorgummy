import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:email_validator/email_validator.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/helpers/database_helper.dart';
import '../../../../data/helpers/shared_prefs_helper.dart';
import 'widgets/auth_background_painter.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _doResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim().toLowerCase();
    final String newPassword = _passwordController.text.trim();

    try {
      // 1. Ambil data user dari SQLite berdasarkan email
      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user == null) {
        if (mounted) {
          _showErrorSnack('Email tidak terdaftar di sistem kami.');
        }
        return;
      }

      // 2. Update password di SQLite (updatePassword akan men-hash password secara otomatis)
      final int result = await DatabaseHelper.instance.updatePassword(email, newPassword);

      if (result > 0) {
        // Catat aktivitas ke SharedPrefs
        await SharedPrefsHelper.saveActivity('Mereset kata sandi akun', userEmail: email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password berhasil diperbarui! Silakan login kembali.'),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman Login
        }
      } else {
        if (mounted) {
          _showErrorSnack('Gagal mereset kata sandi. Silakan coba lagi.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Waves Painter
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(),
            ),
          ),
          
          // Form Area
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Logo
                        Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(
                              Iconsax.key,
                              size: 40,
                              color: AppColors.primaryGreen,
                            ),
                          ).animate().scale(
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ),
                        const SizedBox(height: 24.0),
                        
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                        
                        const SizedBox(height: 6),
                        const Text(
                          'Masukkan informasi terdaftar untuk mereset kata sandi Anda.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 36.0),

                        // Form Fields Container
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // Email Input
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'Registered Email',
                                prefixIcon: Iconsax.sms,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!EmailValidator.validate(value.trim())) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),



                              // New Password Input
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'New Password',
                                prefixIcon: Iconsax.lock,
                                isPasswordField: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Password baru wajib diisi';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Confirm Password Input
                              AuthTextField(
                                controller: _confirmPasswordController,
                                hintText: 'Confirm New Password',
                                prefixIcon: Iconsax.key,
                                isPasswordField: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Konfirmasi password wajib diisi';
                                  }
                                  if (value.trim() != _passwordController.text.trim()) {
                                    return 'Konfirmasi password tidak cocok';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Submit Button
                              AuthButton(
                                text: 'Reset Password',
                                isLoading: _isLoading,
                                onPressed: _doResetPassword,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                        const SizedBox(height: 20),
                        
                        // Back to Login Button
                        Center(
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Iconsax.arrow_left_2, size: 16),
                            label: const Text(
                              'Kembali ke Login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
