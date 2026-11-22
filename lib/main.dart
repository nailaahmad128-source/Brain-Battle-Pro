import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/ads.dart';
import 'core/audio.dart';
import 'core/config.dart';
import 'core/leaderboard.dart';
import 'core/services.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'l10n/strings.dart';
import 'ui/splash.dart';

/// Startup order matters: only what the first screen needs (local storage) is
/// awaited before runApp. Audio and ads talk to native plugins, so they start
/// after the first frame and can never delay or kill the splash screen.
/// Errors are logged to logcat (tag text "BBP") and never swallowed silently.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('BBP FlutterError: ${details.exceptionAsString()}\n${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('BBP uncaught: $error\n$stack');
    return false; // not handled: default reporting still happens
  };

  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (e) {
    debugPrint('BBP orientation lock failed: $e');
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    Svc.store = Store(await SharedPreferences.getInstance());
    Svc.board = LocalLeaderboard(Svc.store);
  } catch (e, st) {
    // Without local storage nothing can work: show the reason instead of a blank screen.
    debugPrint('BBP storage init failed: $e\n$st');
    runApp(StartupErrorApp(message: '$e'));
    return;
  }

  runApp(const BrainBattleApp());
  WidgetsBinding.instance.addPostFrameCallback((_) => _startServices());
}

Future<void> _startServices() async {
  try {
    await Sfx.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('BBP audio init failed: $e');
  }
  await Future<void>.delayed(const Duration(milliseconds: 800));
  try {
    await AdService.instance.init();
  } catch (e) {
    debugPrint('BBP ads init failed: $e');
  }
}

class StartupErrorApp extends StatelessWidget {
  final String message;
  const StartupErrorApp({super.key, required this.message});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Text(
                '${AppConfig.appName} could not start.\n\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

class BrainBattleApp extends StatelessWidget {
  const BrainBattleApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Svc.store,
        builder: (context, _) {
          final l = Svc.store.lang;
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            // null = follow device language; unsupported device languages fall back to English
            locale: l == null ? null : Locale(l),
            supportedLocales: [for (final x in kLanguages) Locale(x.$1)],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashPage(),
          );
        },
      );
}
