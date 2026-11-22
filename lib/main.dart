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
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  Svc.store = Store(await SharedPreferences.getInstance());
  Svc.board = LocalLeaderboard(Svc.store);
  await Sfx.init();
  runApp(const BrainBattleApp());
  unawaited(AdService.instance.init());
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
