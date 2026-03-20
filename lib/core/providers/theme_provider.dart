import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/hive_service.dart';

const _kThemeModeKey = 'themeMode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  void _load() {
    final stored = HiveService.settings.get(_kThemeModeKey, defaultValue: 'dark') as String;
    state = stored == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await HiveService.settings.put(_kThemeModeKey, next == ThemeMode.light ? 'light' : 'dark');
    state = next;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (_) => ThemeModeNotifier(),
);
