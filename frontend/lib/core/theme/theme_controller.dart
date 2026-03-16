import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the current app [ThemeMode].
///
/// Defaults to dark theme. The Profile screen can update this to
/// toggle between light and light modes.
final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.dark);
