import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';

enum AuthTab { login, register }

class AuthDialogCard extends ConsumerStatefulWidget {
  final AuthTab initialTab;
  final VoidCallback? onClose;

  const AuthDialogCard({
    super.key,
    this.initialTab = AuthTab.login,
    this.onClose,
  });

  @override
  ConsumerState<AuthDialogCard> createState() => _AuthDialogCardState();
}

class _AuthDialogCardState extends ConsumerState<AuthDialogCard> {
  late AuthTab _activeTab;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailOrPhoneController.text.trim();
    String email;
    String? phone;

    if (input.contains('@')) {
      email = input;
    } else {
      final digits = input.replaceAll(RegExp(r'\D'), '');
      phone = digits;
      email = '$digits@physioprime.user';
    }

    final password = _passwordController.text;

    if (_activeTab == AuthTab.login) {
      final success = await ref.read(authStateProvider.notifier).login(email, password);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to PhysioPrime!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        _handleClose();
      }
    } else {
      final name = _nameController.text.trim();
      final success = await ref.read(authStateProvider.notifier).register(
            email: email,
            password: password,
            fullName: name,
            phone: phone,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to PhysioPrime.'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        _handleClose();
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    await ref.read(authStateProvider.notifier).loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isLogin = _activeTab == AuthTab.login;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 36,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Close Button Row
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _handleClose,
                  ),
                ),

                // Center Icon: Shield with Checkmark
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488), // Teal Emerald
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3D0D9488),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  isLogin ? 'Welcome back' : 'Create your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  isLogin
                      ? 'Book and manage your physiotherapy care.'
                      : 'Join PhysioPrime for personalized recovery.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),

                // Tabs: "Log in" and "Create account"
                Column(
                  children: [
                    Row(
                      children: [
                        // Log In Tab
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_activeTab != AuthTab.login) {
                                setState(() {
                                  _activeTab = AuthTab.login;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Log in',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isLogin ? FontWeight.w700 : FontWeight.w600,
                                      color: isLogin ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: isLogin ? const Color(0xFF0D9488) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Create Account Tab
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (_activeTab != AuthTab.register) {
                                setState(() {
                                  _activeTab = AuthTab.register;
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Create account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: !isLogin ? FontWeight.w700 : FontWeight.w600,
                                      color: !isLogin ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: !isLogin ? const Color(0xFF0D9488) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Error alert banner if any
                if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Full Name Field (Only in Register mode)
                if (!isLogin) ...[
                  _buildLabel('Full name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                    decoration: _buildInputDecoration(
                      hint: 'John Doe',
                      prefixIcon: LucideIcons.user,
                    ),
                    validator: (v) {
                      if (!isLogin && (v == null || v.trim().isEmpty)) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email or Phone Number Field
                _buildLabel('Email or phone number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailOrPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                  decoration: _buildInputDecoration(
                    hint: 'you@example.com or 9876543210',
                    prefixIcon: LucideIcons.mail,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email or phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildLabel('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
                  decoration: _buildInputDecoration(
                    hint: isLogin ? 'Your password' : 'At least 8 characters',
                    prefixIcon: LucideIcons.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: const Color(0xFF94A3B8),
                        size: 19,
                      ),
                      splashRadius: 18,
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!isLogin && v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                // Forgot Password link (Only in Login mode)
                if (isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Submit Button: "Log in" or "Create account"
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7B75),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLogin ? 'Log in' : 'Create account',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // "OR CONTINUE WITH" Divider
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // "Continue with Google" Button
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _handleGoogleAuth,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        GoogleLogoIcon(size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 19),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
    );
  }
}

/// Official colored Google 'G' icon drawn crisply with CustomPaint
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double stroke = s * 0.22;
    final center = Offset(s / 2, s / 2);
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Blue arc (top-right to bottom-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.65, 1.3, false, paint);

    // Green arc (bottom-right to bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.65, 1.45, false, paint);

    // Yellow arc (bottom-left to top-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.1, 1.1, false, paint);

    // Red arc (top-left to top-right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.2, 1.55, false, paint);

    // Center cross bar (blue)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx - stroke * 0.1,
      center.dy - stroke / 2,
      radius + stroke / 2 + stroke * 0.1,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper to present this exact modal anywhere in the app
Future<void> showAuthDialog(
  BuildContext context, {
  AuthTab initialTab = AuthTab.login,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x660F172A),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: AuthDialogCard(initialTab: initialTab),
      ),
    ),
  );
}
