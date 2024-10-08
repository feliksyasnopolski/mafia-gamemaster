import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum TimerType {
  strict,
  extended,
  disabled,
}

enum ColorSchemeType {
  system,
  app,
}

const defaultTimerType = TimerType.strict;
const defaultThemeMode = ThemeMode.dark;
const defaultColorSchemeType = ColorSchemeType.system;
const defaultToken = "";

Future<SettingsModel> getSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = prefs.getString("timerType") ?? defaultTimerType.name;
  final theme = prefs.getString("theme") ?? defaultThemeMode.name;
  final colorSchemeTypeString =
      prefs.getString("colorSchemeType") ?? defaultColorSchemeType.name;
  final appToken = prefs.getString("appToken") ?? defaultToken;

  final TimerType timerType;
  switch (timerTypeString) {
    case "strict":
      timerType = TimerType.strict;
    case "extended":
      timerType = TimerType.extended;
    case "disabled":
      timerType = TimerType.disabled;
    default:
      assert(
        false,
        "Unknown timer type: $timerTypeString",
      ); // fail for debug builds
      timerType = defaultTimerType; // use default for release builds
      break;
  }

  final ThemeMode themeMode;
  switch (theme) {
    case "system":
      themeMode = ThemeMode.system;
    case "light":
      themeMode = ThemeMode.light;
    case "dark":
      themeMode = ThemeMode.dark;
    default:
      assert(false, "Unknown theme mode: $theme"); // fail for debug builds
      themeMode = defaultThemeMode; // use default for release builds
      break;
  }

  final ColorSchemeType colorSchemeType;
  switch (colorSchemeTypeString) {
    case "system":
      colorSchemeType = ColorSchemeType.system;
    case "app":
      colorSchemeType = ColorSchemeType.app;
    default:
      assert(
        false,
        "Unknown color scheme type: $colorSchemeTypeString",
      ); // fail for debug builds
      colorSchemeType =
          defaultColorSchemeType; // use default for release builds
      break;
  }

  return SettingsModel(
    timerType: timerType,
    themeMode: themeMode,
    colorSchemeType: colorSchemeType,
    appToken: appToken,
  );
}

Future<void> saveSettings(SettingsModel settings) async {
  final prefs = await SharedPreferences.getInstance();
  final timerTypeString = settings.timerType.name;
  final theme = settings.themeMode.name;
  final colorSchemeTypeString = settings.colorSchemeType.name;

  await prefs.setString("timerType", timerTypeString);
  await prefs.setString("theme", theme);
  await prefs.setString("colorSchemeType", colorSchemeTypeString);
  await prefs.setString("appToken", settings.appToken);
}

class SettingsModel with ChangeNotifier {
  TimerType _timerType;
  ThemeMode _themeMode;
  ColorSchemeType _colorSchemeType;
  String _appToken;

  SettingsModel({
    required TimerType timerType,
    required ThemeMode themeMode,
    required ColorSchemeType colorSchemeType,
    required String appToken,
  })  : _timerType = timerType,
        _themeMode = themeMode,
        _colorSchemeType = colorSchemeType,
        _appToken = appToken;

  TimerType get timerType => _timerType;

  ThemeMode get themeMode => _themeMode;

  ColorSchemeType get colorSchemeType => _colorSchemeType;

  String get appToken => _appToken;

  void setAppToken(String value, {bool save = true}) {
    _appToken = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setTimerType(TimerType value, {bool save = true}) {
    _timerType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode value, {bool save = true}) {
    _themeMode = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }

  void setColorSchemeType(ColorSchemeType value, {bool save = true}) {
    _colorSchemeType = value;
    if (save) {
      saveSettings(this);
    }
    notifyListeners();
  }
}
