import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "screens/game.dart";
import "screens/game_log.dart";
import "screens/main.dart";
import "screens/roles.dart";
import "screens/login.dart";
import "screens/settings.dart";
import "utils/game_controller.dart";
import "utils/settings.dart";
import "utils/login/login_bloc.dart";
import "router/router.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        Provider<PackageInfo>.value(value: packageInfo),
        ChangeNotifierProvider<GameController>(create: (context) => GameController()),
        BlocProvider<LoginBloc>(create: (context) => LoginBloc()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    const seedColor = Colors.purple;

    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp.router(
        title: "Помощник ведущего",
        theme: ThemeData(
          colorScheme: (settings.colorSchemeType == ColorSchemeType.system ? light : null) ??
              ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: (settings.colorSchemeType == ColorSchemeType.system ? dark : null) ??
              ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
          useMaterial3: true,
        ),
        themeMode: settings.themeMode,
        routerConfig: _appRouter.config(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale("ru"),
        ],
      ),
    );
  }
}
