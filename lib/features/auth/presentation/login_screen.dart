import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/fluid_pressable.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsRegister;

  const LoginScreen({
    super.key,
    this.initialIsRegister = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isRegister;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailOrPhoneController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final input = _emailOrPhoneController.text.trim();
    String email;
    String? phone;

    if (input.contains('@')) {
      email = input;
      phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null;
    } else {
      final digits = input.replaceAll(RegExp(r'\D'), '');
      phone = digits;
      email = '$digits@physioprime.user';
    }

    final password = _passwordController.text;

    if (!_isRegister) {
      final success = await ref.read(authStateProvider.notifier).login(email, password);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to PhysioPrime!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        _handleBack();
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
        _handleBack();
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    final success = await ref.read(authStateProvider.notifier).loginWithGoogle();
    if (success && mounted) {
      _handleBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated && mounted) {
        _handleBack();
      }
    });

    final authState = ref.watch(authStateProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB), // Exact bgPrimary from DESIGN.md
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 24, color: Color(0xFF0F172A)),
                    onPressed: _handleBack,
                    splashRadius: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  // Brand Monogram + Wordmark
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/pp_monogram.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          text: 'Physio',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(
                              text: 'Prime',
                              style: TextStyle(
                                color: Color(0xFF0891B2),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Right Spacer to keep logo centered
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Header Hero Section (Shield Badge + Title + Subtitle)
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x330891B2),
                        blurRadius: 14,
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
              const SizedBox(height: 14),

              Text(
                _isRegister ? 'Create your account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                _isRegister
                  ? 'Join PhysioPrime for trusted home & online physiotherapy.'
                  : 'Book and manage your physiotherapy appointments & recovery.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),

              // 3. Segmented Switcher (Log In vs Create Account)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Log In Pill
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (_isRegister) {
                            setState(() => _isRegister = false);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_isRegister ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isRegister
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0F0F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: !_isRegister ? FontWeight.w800 : FontWeight.w600,
                              color: !_isRegister ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Create Account Pill
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          if (!_isRegister) {
                            setState(() => _isRegister = true);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isRegister ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isRegister
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0F0F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _isRegister ? FontWeight.w800 : FontWeight.w600,
                              color: _isRegister ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Main Authentication Form Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name (Only on Create Account)
                      if (_isRegister) ...[
                        _buildFieldLabel('Full Name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: 'e.g. Ramesh Kumar',
                            prefixIcon: LucideIcons.user,
                          ),
                          validator: (val) {
                            if (_isRegister && (val == null || val.trim().length < 2)) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email or Phone
                      _buildFieldLabel(_isRegister ? 'Email Address' : 'Email or Mobile Number'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailOrPhoneController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hint: _isRegister ? 'name@example.com' : 'name@example.com or 10-digit mobile',
                          prefixIcon: _isRegister ? LucideIcons.mail : LucideIcons.userCheck,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email or phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number (Only on Create Account)
                      if (_isRegister) ...[
                        _buildFieldLabel('Mobile Number (Optional)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: '+91 98765 43210',
                            prefixIcon: LucideIcons.phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Password
                      _buildFieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          prefixIcon: LucideIcons.lock,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      // Forgot Password Link (Only on Log In)
                      if (!_isRegister) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => context.push('/forgot-password'),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0891B2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Confirm Password (Only on Create Account)
                      if (_isRegister) ...[
                        const SizedBox(height: 16),
                        _buildFieldLabel('Confirm Password'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            prefixIcon: LucideIcons.shieldCheck,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                size: 18,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                          validator: (val) {
                            if (_isRegister && val != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Error Banner
                      if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),

                      // Submit CTA Button
                      FluidPressable(
                        onTap: isLoading ? null : _handleSubmit,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3D0D9488),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(
                                  _isRegister ? 'Create Account' : 'Log In',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider Row ("Or continue with")
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Google OAuth Button
                      InkWell(
                        onTap: isLoading ? null : _handleGoogleAuth,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              _GoogleLogoIcon(size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
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
              const SizedBox(height: 20),

              // 5. Toggle Prompt at Bottom
              Center(
                child: InkWell(
                  onTap: () => setState(() => _isRegister = !_isRegister),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: RichText(
                      text: TextSpan(
                        text: _isRegister ? 'Already have an account? ' : "Don't have an account? ",
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: _isRegister ? 'Log In' : 'Create Account',
                            style: const TextStyle(
                              color: Color(0xFF0891B2),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 6. Terms & Privacy Notice
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'By continuing, you agree to PhysioPrime\'s ',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.35),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/terms'),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    ' and ',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.35),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/privacy'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    '.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFF0891B2)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0891B2), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

/// Official colored Google 'G' icon drawn crisply with CustomPaint
class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 20});

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

    // Blue arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.65, 1.3, false, paint);

    // Green arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.65, 1.45, false, paint);

    // Yellow arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.1, 1.15, false, paint);

    // Red arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.25, 1.35, false, paint);

    // Horizontal bar of the 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barHeight = stroke;
    final barWidth = s * 0.44;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - barHeight / 2, barWidth, barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
