import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Enhanced UI/UX Animations and Micro-interactions
/// For Best UI/UX Award! ✨

// ============== ANIMATED TRANSITIONS ==============

/// Fade + Scale page transition
class FadeScaleTransition extends PageRouteBuilder {
  final Widget page;

  FadeScaleTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeOutCubic;
            var fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            var scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
              CurvedAnimation(parent: animation, curve: curve),
            );
            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
        );
}

/// Slide up transition (for bottom sheets style pages)
class SlideUpTransition extends PageRouteBuilder {
  final Widget page;

  SlideUpTransition({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var curve = Curves.easeOutCubic;
            var offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: curve));
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

// ============== MICRO ANIMATIONS ==============

/// Bouncy button with haptic feedback
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool hapticFeedback;
  final double scaleFactor;

  const BouncyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.hapticFeedback = true,
    this.scaleFactor = 0.95,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor = const Color(0xFF2D2D3A),
    this.highlightColor = const Color(0xFF3D3D4A),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation for notifications/alerts
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.animate = true,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _animation.value : 1.0,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Floating action button with ripple effect
class RippleFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const RippleFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = const Color(0xFF0033AD),
  });

  @override
  State<RippleFAB> createState() => _RippleFABState();
}

class _RippleFABState extends State<RippleFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple rings
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = ((_controller.value + index * 0.33) % 1.0);
              return Container(
                width: 56 + (progress * 40),
                height: 56 + (progress * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: (1 - progress) * 0.5),
                    width: 2,
                  ),
                ),
              );
            },
          );
        }),
        // Main FAB
        FloatingActionButton(
          onPressed: widget.onPressed,
          backgroundColor: widget.color,
          child: Icon(widget.icon, color: Colors.white),
        ),
      ],
    );
  }
}

// ============== ANIMATED CONTAINERS ==============

/// Glass morphism card with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: blur,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Animated counter for stats
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final int decimals;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.decimals = 0,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value.toStringAsFixed(widget.decimals)}${widget.suffix}',
          style: widget.style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}

/// Progress indicator with glow effect
class GlowingProgressIndicator extends StatefulWidget {
  final double progress;
  final Color color;
  final double height;

  const GlowingProgressIndicator({
    super.key,
    required this.progress,
    this.color = const Color(0xFF00D9FF),
    this.height = 8,
  });

  @override
  State<GlowingProgressIndicator> createState() =>
      _GlowingProgressIndicatorState();
}

class _GlowingProgressIndicatorState extends State<GlowingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
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
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            color: Colors.grey[800],
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: widget.progress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    gradient: LinearGradient(
                      colors: [
                        widget.color,
                        widget.color.withValues(alpha: 0.7 + _controller.value * 0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 8 + _controller.value * 4,
                        spreadRadius: _controller.value * 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============== ACCESSIBILITY HELPERS ==============

/// Semantic wrapper for screen readers
class AccessibleWidget extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isButton;

  const AccessibleWidget({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      child: child,
    );
  }
}

/// High contrast text for accessibility
class HighContrastText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool highContrast;

  const HighContrastText({
    super.key,
    required this.text,
    this.style,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final useHighContrast = highContrast || mediaQuery.highContrast;

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        color: useHighContrast ? Colors.white : null,
        fontWeight: useHighContrast ? FontWeight.bold : null,
      ),
    );
  }
}

// ============== PARTICLE EFFECTS ==============

/// Confetti celebration effect
class ConfettiEffect extends StatefulWidget {
  final bool trigger;
  final VoidCallback? onComplete;

  const ConfettiEffect({
    super.key,
    required this.trigger,
    this.onComplete,
  });

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Confetti> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _generateConfetti();
      _controller.forward(from: 0);
    }
  }

  void _generateConfetti() {
    _confetti.clear();
    for (int i = 0; i < 50; i++) {
      _confetti.add(_Confetti(
        x: _random.nextDouble(),
        initialY: -0.1 - _random.nextDouble() * 0.3,
        speed: 0.3 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        color: [
          const Color(0xFF00D9FF),
          const Color(0xFF0033AD),
          const Color(0xFFFFD700),
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECB71),
        ][_random.nextInt(5)],
        size: 8 + _random.nextDouble() * 8,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.trigger && _confetti.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            confetti: _confetti,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Confetti {
  final double x;
  final double initialY;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;

  _Confetti({
    required this.x,
    required this.initialY,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;

  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final y = c.initialY + (c.speed * progress * 1.5);
      if (y > 1.2) continue;

      final paint = Paint()
        ..color = c.color.withValues(alpha: (1 - progress).clamp(0, 1))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(c.x * size.width, y * size.height);
      canvas.rotate(c.rotation + c.rotationSpeed * progress);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size / 2),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Gradient animated border
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<Color> colors;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.colors = const [
      Color(0xFF00D9FF),
      Color(0xFF0033AD),
      Color(0xFF00D9FF),
    ],
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: SweepGradient(
              colors: widget.colors,
              transform: GradientRotation(_controller.value * 2 * pi),
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.circular(
                widget.borderRadius.topLeft.x - widget.borderWidth,
              ),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
