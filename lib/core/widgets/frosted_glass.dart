import 'dart:ui';
import 'package:flutter/material.dart';

/// Apple translucent frosted material:
/// Approximates iOS translucent chrome with BackdropFilter,
/// subtle tint, saturation, and a hairline border where light catches the edge.
class FrostedGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const FrostedGlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.backgroundColor = const Color(0xCCFFFFFF), // 80% white
    this.borderRadius,
    this.border,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ??
                  Border.all(
                    color: const Color(0x33FFFFFF), // subtle light border
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Frosted Glass AppBar that blends smoothly with scrolling content
class FrostedGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double height;
  final bool showBottomBorder;

  const FrostedGlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.height = kToolbarHeight,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xD9FFFFFF), // 85% translucent white
            border: showBottomBorder
                ? const Border(
                    bottom: BorderSide(
                      color: Color(0x14000000), // hairline border
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: height,
              child: NavigationToolbar(
                leading: leading,
                middle: title,
                trailing: actions != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    : null,
                centerMiddle: false,
                middleSpacing: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
