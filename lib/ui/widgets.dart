import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B0A14), Color(0xFF120F26)],
              ),
            ),
          ),
        ),
        const Positioned(top: -120, left: -80, child: _Glow(C.purple, 320)),
        const Positioned(bottom: -140, right: -100, child: _Glow(C.cyan, 320)),
        Positioned.fill(child: child),
      ]);
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow(this.color, this.size);
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.0),
            ]),
          ),
        ),
      );
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final double radius;
  final Color? border;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.radius = 22,
    this.border,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.white.withValues(alpha: 0.06) : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border ?? Colors.white.withValues(alpha: 0.10)),
        ),
        child: child,
      );
}

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      );
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;
  final Gradient gradient;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.outlined = false,
    this.gradient = C.brand,
  });
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: outlined ? null : gradient,
            color: outlined ? Colors.white.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(18),
            border: outlined
                ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: C.purple.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      );
}

class XpBar extends StatelessWidget {
  final double progress;
  final double height;
  const XpBar({super.key, required this.progress, this.height = 10});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(height),
          ),
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v.clamp(0.02, 1.0).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                gradient: C.brand,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      );
}

/// Lightweight confetti (no packages, ~46 particles).
class Confetti extends StatefulWidget {
  const Confetti({super.key});
  @override
  State<Confetti> createState() => _ConfettiState();
}

class _P {
  final double x, delay, speed, size, drift;
  final int color;
  _P(this.x, this.delay, this.speed, this.size, this.drift, this.color);
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2800))
    ..forward();
  late final List<_P> _parts = () {
    final r = Random(7);
    return List.generate(
        46,
        (_) => _P(r.nextDouble(), r.nextDouble() * 0.5, 0.7 + r.nextDouble() * 0.6,
            4 + r.nextDouble() * 5, r.nextDouble() * 6, r.nextInt(5)));
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(_parts, _c.value),
            size: Size.infinite,
          ),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  final List<_P> parts;
  final double v;
  _ConfettiPainter(this.parts, this.v);
  static const _colors = [C.purple, C.cyan, C.pink, C.gold, C.green];
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in parts) {
      final t = ((v - p.delay) / (1 - p.delay)).clamp(0.0, 1.0).toDouble();
      if (t <= 0) continue;
      final x = p.x * size.width + sin(t * 6 + p.drift) * 22;
      final y = -20 + t * (size.height + 40) * p.speed;
      final paint = Paint()
        ..color = _colors[p.color].withValues(alpha: (1 - t * t).clamp(0.0, 1.0).toDouble());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size * 1.6),
            const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.v != v;
}
