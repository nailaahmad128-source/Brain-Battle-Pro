import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupGate());
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  Object? error;
  StackTrace? details;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: C.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ));

      Svc.store = Store(await SharedPreferences.getInstance());
      Svc.board = LocalLeaderboard(Svc.store);
      await Sfx.init();

      if (!mounted) return;
      setState(() => ready = true);
      unawaited(AdService.instance.init());
    } catch (e, st) {
      debugPrint('STARTUP ERROR: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        error = e;
        details = st;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF15132A),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                'BRAIN BATTLE PRO - STARTUP ERROR

'
                'ERROR:
$error

'
                'DETAILS:
${details ?? "No details available"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0B0A14),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return const BrainBattleApp();
  }
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
