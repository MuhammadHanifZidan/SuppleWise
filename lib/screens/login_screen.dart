import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

/// Login screen — mengikuti design web login page.
/// Saat ini menggunakan dev login. Google Sign-In akan diaktifkan
/// setelah SHA-1 + Android Client ID dikonfigurasi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late final AnimationController _entryCtrl;
  late final List<Animation<double>> _entryFades;
  late final List<Animation<Offset>> _entrySlides;
  static const int _sectionCount = 4;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFades = List.generate(_sectionCount, (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _entrySlides = List.generate(_sectionCount, (i) => Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.15, (i * 0.15 + 0.5).clamp(0, 1), curve: Curves.easeOut))));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimated(int index, Widget child) {
    return FadeTransition(opacity: _entryFades[index], child: SlideTransition(position: _entrySlides[index], child: child));
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      // TODO: Ganti dengan real Google Sign-In setelah SHA-1 ready
      await AuthService.googleLogin();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  _buildAnimated(0, Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.analytics,
                      color: Colors.white,
                      size: 40,
                    ),
                  )),
                  const SizedBox(height: 24),

                  // ── App name ──
                  _buildAnimated(1, Column(children: [
                    const Text(
                      'SuppleWise',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SUPPLY CHAIN INTELLIGENCE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.50,
                        ),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ])),

                  const SizedBox(height: 48),

                  // ── Welcome text ──
                  _buildAnimated(2, Column(children: [
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masuk untuk mengelola dan menganalisis\nperforma rantai pasok Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.70,
                        ),
                        height: 20 / 14,
                      ),
                    ),
                  ])),

                  const SizedBox(height: 40),

                  // ── Google Login Button & Footer ──
                  _buildAnimated(3, Column(children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.40,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google icon
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Login dengan Google',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'v1.0.4 — SuppleWise',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                  ])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

