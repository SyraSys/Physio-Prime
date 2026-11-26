import 'package:flutter/material.dart';

/// Apple-grade Shimmer Controller that sweeps across all child skeleton widgets.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Shifts gradient smoothly from left (-1.0) to right (+2.0)
    return Matrix4.translationValues(bounds.width * (slidePercent * 3.0 - 1.0), 0.0, 0.0);
  }
}

/// Primitive skeleton rectangular or rounded box.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Primitive skeleton circular widget (e.g. avatars, icons).
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({super.key, required this.size, this.margin});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: size,
      height: size,
      shape: BoxShape.circle,
      margin: margin,
    );
  }
}

/// Primitive skeleton text line placeholder.
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 4,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

/// Full-page skeleton placeholder for clinic and home dashboard loading.
/// Displays top app bar, search bar, banner, category pills, and appointment/doctor cards.
class ClinicLoadingSkeletonScreen extends StatelessWidget {
  const ClinicLoadingSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Material(
      color: const Color(0xFFF8FAFB),
      child: ShimmerLoading(
        child: SafeArea(
          top: false,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 24),
            children: [
              // Top Header (Avatar + Greeting + Bell)
              Row(
                children: [
                  const SkeletonCircle(size: 46),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 90, height: 12),
                        SizedBox(height: 6),
                        SkeletonLine(width: 140, height: 16),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 40, height: 40, borderRadius: 12),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar Skeleton
              const SkeletonBox(width: double.infinity, height: 50, borderRadius: 16),
              const SizedBox(height: 20),

              // Hero Banner Skeleton
              const SkeletonBox(width: double.infinity, height: 140, borderRadius: 20),
              const SizedBox(height: 24),

              // Categories Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLine(width: 130, height: 18),
                  SkeletonLine(width: 50, height: 14),
                ],
              ),
              const SizedBox(height: 14),

              // Horizontal Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: List.generate(
                    4,
                    (i) => const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SkeletonBox(width: 100, height: 42, borderRadius: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Title
              const SkeletonLine(width: 150, height: 18),
              const SizedBox(height: 14),

              // Doctor / Appointment Cards
              ...List.generate(
                3,
                (i) => const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: DoctorCardSkeleton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page skeleton placeholder for Doctor Detail Screen.
class DoctorDetailSkeletonScreen extends StatelessWidget {
  const DoctorDetailSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: ShimmerLoading(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 40, height: 40, borderRadius: 12),
                  SkeletonLine(width: 120, height: 18),
                  SkeletonBox(width: 40, height: 40, borderRadius: 12),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Doctor Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        SkeletonBox(width: 80, height: 80, borderRadius: 16),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLine(width: 160, height: 18),
                              SizedBox(height: 8),
                              SkeletonLine(width: 120, height: 13),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  SkeletonBox(width: 54, height: 22, borderRadius: 6),
                                  SizedBox(width: 8),
                                  SkeletonBox(width: 64, height: 22, borderRadius: 6),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stats Row (3 rounded boxes: Rating, Experience, Patients)
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 70, borderRadius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 70, borderRadius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 70, borderRadius: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // About Section Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 80, height: 16),
                        SizedBox(height: 12),
                        SkeletonLine(width: double.infinity, height: 12),
                        SizedBox(height: 8),
                        SkeletonLine(width: double.infinity, height: 12),
                        SizedBox(height: 8),
                        SkeletonLine(width: 200, height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Consultation Modes Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 140, height: 16),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: SkeletonBox(height: 60, borderRadius: 14)),
                            SizedBox(width: 10),
                            Expanded(child: SkeletonBox(height: 60, borderRadius: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Action Bar Skeleton
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SkeletonLine(width: 50, height: 12),
                      SizedBox(height: 4),
                      SkeletonLine(width: 70, height: 20),
                    ],
                  ),
                  SizedBox(width: 24),
                  Expanded(child: SkeletonBox(height: 48, borderRadius: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for individual doctor cards in lists.
class DoctorCardSkeleton extends StatelessWidget {
  const DoctorCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 68, height: 68, borderRadius: 16),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140, height: 16),
                SizedBox(height: 6),
                SkeletonLine(width: 100, height: 12),
                SizedBox(height: 8),
                Row(
                  children: [
                    SkeletonBox(width: 44, height: 20, borderRadius: 6),
                    SizedBox(width: 8),
                    SkeletonBox(width: 60, height: 20, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-page skeleton placeholder for Appointment Detail screen.
class AppointmentDetailSkeletonScreen extends StatelessWidget {
  const AppointmentDetailSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const SkeletonLine(width: 150, height: 17),
      ),
      body: ShimmerLoading(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 40),
          children: [
            // Status banner skeleton
            const SkeletonBox(width: double.infinity, height: 64, borderRadius: 18),
            const SizedBox(height: 14),

            // Doctor card skeleton
            const DoctorCardSkeleton(),
            const SizedBox(height: 14),

            // Schedule card skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLine(width: 60, height: 14),
                      SkeletonLine(width: 120, height: 14),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLine(width: 60, height: 14),
                      SkeletonLine(width: 100, height: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Patient card skeleton
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLine(width: 50, height: 14),
                      SkeletonLine(width: 80, height: 14),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLine(width: 50, height: 14),
                      SkeletonLine(width: 110, height: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
