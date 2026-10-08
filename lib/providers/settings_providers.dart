import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main() before runApp()');
});

enum WeightUnit { kg, lb }

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_key);
    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class WeightUnitNotifier extends Notifier<WeightUnit> {
  static const _key = 'weight_unit';

  @override
  WeightUnit build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key) == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  }

  Future<void> setUnit(WeightUnit unit) async {
    state = unit;
    await ref.read(sharedPreferencesProvider).setString(_key, unit.name);
  }
}

final weightUnitProvider =
    NotifierProvider<WeightUnitNotifier, WeightUnit>(WeightUnitNotifier.new);
