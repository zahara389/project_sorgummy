import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:email_validator/email_validator.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../data/helpers/database_helper.dart';
import '../../data/helpers/shared_prefs_helper.dart';
import '../../admin/admin_dashboard_page.dart';
import 'main_navigation.dart';
import 'register_screen.dart';
import 'authentication/forgot_password_screen.dart';
import 'authentication/widgets/auth_background_painter.dart';
import 'authentication/widgets/auth_text_field.dart';
import 'authentication/widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMeEmail();
  }

  Future<void> _loadRememberMeEmail() async {
    final String? savedEmail = await SharedPrefsHelper.getRememberMeEmail();
    debugPrint('🔍 LoadRememberMeEmail: savedEmail = $savedEmail');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
      setState(() {
        _rememberMe = true;
      });
      debugPrint('✅ Email auto-filled dari saved data');
    } else {
      debugPrint('❌ Tidak ada email yang tersimpan');
    }
  }

  Future<void> _saveRememberMeEmail(String email) async {
    debugPrint('💾 SaveRememberMeEmail: _rememberMe = $_rememberMe, email = $email');
    if (_rememberMe) {
      await SharedPrefsHelper.setRememberMeEmail(email);
      debugPrint('✅ Email berhasil disimpan: $email');
    } else {
      await SharedPrefsHelper.clearRememberMeEmail();
      debugPrint('❌ Email dihapus karena checkbox OFF');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // KREDENSIAL ADMIN
  static const String _kAdminEmail    = 'admin123@gmail.com';
  static const String _kAdminPassword = 'admin123';

  bool _isAdminCredential(String email, String password) {
    final inputEmail    = email.trim().toLowerCase();
    final inputPassword = password.trim();
    final targetEmail   = _kAdminEmail.trim().toLowerCase();
    final targetPass    = _kAdminPassword.trim();

    debugPrint('╔══ ADMIN CHECK ══════════════════════════════');
    debugPrint('║  inputEmail    : "$inputEmail"');
    debugPrint('║  targetEmail   : "$targetEmail"');
    debugPrint('║  emailMatch    : ${inputEmail == targetEmail}');
    debugPrint('║  inputPassword : "$inputPassword"');
    debugPrint('║  targetPass    : "$targetPass"');
    debugPrint('║  passMatch     : ${inputPassword == targetPass}');
    debugPrint('╚═════════════════════════════════════════════');

    return inputEmail == targetEmail && inputPassword == targetPass;
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String emailInput    = _emailController.text.trim();
    final String passwordInput = _passwordController.text.trim();

    debugPrint('🔐 Sign In ditekan — email="$emailInput", rememberMe=$_rememberMe');

    try {
      // 1. Cek Admin
      if (_isAdminCredential(emailInput, passwordInput)) {
        debugPrint('🛡️ ADMIN TERDETEKSI — Memproses sesi admin...');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', 'admin');
        await prefs.setBool('is_logged_in', true);
        await SharedPrefsHelper.setLoggedUserEmail(_kAdminEmail);

        if (_rememberMe) {
          await SharedPrefsHelper.setRememberMeEmail(_kAdminEmail);
          debugPrint('💾 Remember-me: email admin disimpan');
        } else {
          await SharedPrefsHelper.clearRememberMeEmail();
          debugPrint('🗑️ Remember-me: email admin dihapus');
        }

        await SharedPrefsHelper.saveActivity('Admin berhasil masuk ke panel admin');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => false,
        );

        return;
      }

      // 2. Login User Biasa via Database
      debugPrint('👤 Bukan admin — mencoba login user biasa...');

      final String passwordHash = _hashPassword(passwordInput);
      final bool success = await DatabaseHelper.instance.loginUser(
        emailInput.toLowerCase(),
        passwordHash,
      );

      if (success) {
        debugPrint('✅ Login user biasa BERHASIL');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_role', 'user');
        await prefs.setBool('is_logged_in', true);
        await SharedPrefsHelper.setLoggedIn(true);
        await SharedPrefsHelper.setLoggedUserEmail(emailInput.toLowerCase());
        await SharedPrefsHelper.setFirstTime(false);
        await _saveRememberMeEmail(emailInput.toLowerCase());
        await SharedPrefsHelper.saveActivity('Berhasil masuk ke dalam aplikasi');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      } else {
        debugPrint('❌ Login GAGAL: email atau password tidak cocok di DB');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email atau password salah.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔥 Exception saat login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Painter (Assessment Kriteria #2)
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(),
            ),
          ),
          
          // App Bar Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: const BackButton(color: Colors.white),
          ),

          // Main Form Content
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
                          child: Image.asset(
                            'assets/images/login.png',
                            height: 110.0,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 110.0,
                                width: 110.0,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.shield_security,
                                  size: 55.0,
                                  color: AppColors.primaryGreen,
                                ),
                              );
                            },
                          ),
                        ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 16.0),
                        
                        // Welcome Text (in White color to overlay the green waves)
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                        
                        const SizedBox(height: 4),
                        const Text(
                          'Please Sign in to continue.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 28),

                        // Form Container Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Field (Assessment Kriteria #1 - Custom Widget & Package Validator)
                              AuthTextField(
                                controller: _emailController,
                                hintText: 'Email',
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

                              // Password Field with Gesture Peek (Assessment Kriteria #1 & #3)
                              AuthTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                prefixIcon: Iconsax.lock,
                                isPasswordField: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Remember Me Switch Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Reminder me nextime',
                                    style: TextStyle(
                                      color: Color(0xFF263238),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.75,
                                    child: Switch(
                                      value: _rememberMe,
                                      activeColor: Colors.white,
                                      activeTrackColor: AppColors.primaryGreen,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: Colors.grey.shade300,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _rememberMe = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Forgot Password link (Navigates to ForgotPasswordScreen)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // AuthButton (Assessment Kriteria #1)
                              AuthButton(
                                text: 'Sign In',
                                isLoading: _isLoading,
                                onPressed: _doLogin,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),

                        // Go to Register Screen Link
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontFamily: 'sans-serif',
                                ),
                                children: [
                                  TextSpan(text: "Don't have account? "),
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                        const SizedBox(height: 10),
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
