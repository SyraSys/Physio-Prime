import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/router_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../doctors/providers/doctors_provider.dart';
import '../../home/providers/home_provider.dart';

/// Minimalist, Apple-grade Launch & Loading Screen for PhysioPrime.
/// Strictly displays the PhysioPrime logo and the brand name "PhysioPrime",
/// with zero progress bars, badges, or distracting subtext.
class SplashScreen extends ConsumerStatefulWidget {
  final String? targetLocation;
  final Duration minDuration;
  final bool autoNavigate;
  final bool enableWarmUp;

  const SplashScreen({
    super.key,
    this.targetLocation,
    this.minDuration = const Duration(milliseconds: 1600),
    this.autoNavigate = true,
    this.enableWarmUp = true,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _maxSafetyTimer;
  bool _warmUpCompleted = false;
  bool _animationCompleted = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: widget.minDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCompleted = true;
        _attemptNavigation();
      }
    });

    _animController.forward();

    if (widget.autoNavigate) {
      _maxSafetyTimer = Timer(const Duration(milliseconds: 3800), () {
        if (mounted && !_hasNavigated) {
          _warmUpCompleted = true;
          _animationCompleted = true;
          _attemptNavigation();
        }
      });
    }

    if (widget.enableWarmUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startWarmUp();
      });
    } else {
      _warmUpCompleted = true;
    }
  }

  Future<void> _startWarmUp() async {
    try {
      final precacheFuture = Future.wait([
        precacheImage(const AssetImage('assets/images/pp_monogram.png'), context),
        precacheImage(const AssetImage('assets/images/hero_doctor.png'), context),
      ]);

      final providersFuture = Future.wait([
        ref.read(locationsProvider.future),
        ref.read(categoriesProvider.future),
        ref.read(symptomsProvider.future),
        ref.read(homeDoctorsProvider.future),
      ]);

      await Future.wait([precacheFuture, providersFuture]).timeout(
        const Duration(milliseconds: 2600),
        onTimeout: () => [],
      );
    } catch (_) {
      // Gracefully continue even in offline or slow-network environments
    } finally {
      if (mounted) {
        _warmUpCompleted = true;
        _attemptNavigation();
      }
    }
  }

  void _attemptNavigation() {
    if (!widget.autoNavigate || _hasNavigated || !mounted) return;
    if (!_animationCompleted || !_warmUpCompleted) return;

    _hasNavigated = true;
    _maxSafetyTimer?.cancel();
    markAppInitialized();

    final target = widget.targetLocation;
    if (target != null && target.isNotEmpty && target != '/' && target != '/splash') {
      context.go(target);
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _maxSafetyTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // PhysioPrime Logo
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE2EFEA),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120891B2),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset(
                    'assets/images/pp_monogram.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // Name: PhysioPrime
                RichText(
                  text: const TextSpan(
                    text: 'Physio',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.6,
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
          ),
        ),
      ),
    );
  }
}
