import 'dart:async';
import 'package:flutter/material.dart';
import '../core/config.dart';
import '../core/theme.dart';
import 'home.dart';
import 'widgets.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(fadeRoute(const HomeShell()));
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AppBackground(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    gradient: C.brand,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: C.purple.withValues(alpha: 0.5), blurRadius: 40)],
                  ),
                  child: const Icon(Icons.psychology_rounded, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text('BRAIN BATTLE PRO',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 6),
                const Text('by ${AppConfig.studio}',
                    style: TextStyle(color: C.cyan, letterSpacing: 2, fontSize: 12)),
              ]),
            ),
          ),
        ),
      );
}
