import 'package:flutter/material.dart';

/// Light or dark Road Sign, or whichever the phone is using.
enum ThemeChoice {
  system('Match phone', ThemeMode.system),
  light('Light', ThemeMode.light),
  dark('Dark', ThemeMode.dark);

  const ThemeChoice(this.label, this.mode);

  final String label;
  final ThemeMode mode;
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeChoice = ThemeChoice.system,
    this.notificationPermissionsAsked = false,
    this.garageTitle = defaultGarageTitle,
    this.lastBackupAt,
  });

  static const defaultGarageTitle = 'Your Garage';

  /// Room for a name plus "Garage", short enough to stay on one line.
  static const garageTitleMaxLength = 24;

  final ThemeChoice themeChoice;

  /// The exact-alarm grant is a full-screen trip to system Settings, so it's
  /// only ever offered automatically once; Settings has a row to retry.
  final bool notificationPermissionsAsked;

  /// The big heading on Home.
  final String garageTitle;

  /// When a backup file was last saved from this phone; null if never.
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    ThemeChoice? themeChoice,
    bool? notificationPermissionsAsked,
    String? garageTitle,
    DateTime? lastBackupAt,
  }) => AppSettings(
    themeChoice: themeChoice ?? this.themeChoice,
    notificationPermissionsAsked:
        notificationPermissionsAsked ?? this.notificationPermissionsAsked,
    garageTitle: garageTitle ?? this.garageTitle,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
  );
}
