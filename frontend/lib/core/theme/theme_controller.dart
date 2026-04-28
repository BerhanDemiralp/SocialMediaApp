import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the current app [ThemeMode].
///
/// Defaults to light theme. The Profile screen can update this to
/// toggle between light and dark modes.
final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);
