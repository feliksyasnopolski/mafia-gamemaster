import "dart:convert";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:json_theme/json_theme.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:provider/provider.dart";

import "router/router.dart";
import "utils/game_controller.dart";
import "utils/login/login_bloc.dart";
import "utils/settings.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await getSettings();
  final packageInfo = await PackageInfo.fromPlatform();
  final themeStr = await rootBundle.loadString("assets/appainter_theme.json");
  final themeJson = json.decode(themeStr);
  final theme = ThemeDecoder.decodeThemeData(themeJson)!;

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsModel>.value(value: settings),
        Provider<PackageInfo>.value(value: packageInfo),
        ChangeNotifierProvider<GameController>(
          create: (context) => GameController(),
        ),
        BlocProvider<LoginBloc>(create: (context) => LoginBloc()),
      ],
      child: MyApp(theme: theme),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeData theme;

  MyApp({super.key, required this.theme});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsModel>();
    const seedColor = Colors.purple;

    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp.router(
        title: "Помощник ведущего",
        theme: theme,
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
