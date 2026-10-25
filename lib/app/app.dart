import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_palettes.dart';
import '../core/theme/app_theme.dart';
import '../features/reminders/application/reminder_sync.dart';
import '../features/settings/application/settings_controller.dart';
import 'router.dart';

class ServoBuddyApp extends ConsumerWidget {
  const ServoBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kept alive for the app's lifetime: reschedules reminders on every change.
    ref.watch(reminderSyncProvider);
    final choice = ref.watch(settingsProvider.select((s) => s.themeChoice));
    return MaterialApp.router(
      title: 'ServoBuddy',
      debugShowCheckedModeBanner: false,
      theme: themeFor(AppPalettes.light),
      darkTheme: themeFor(AppPalettes.dark),
      themeMode: choice.mode,
      // Switch instantly. The default 200ms cross-fade rebuilt the whole app
      // on every frame of it, and the palette can't blend smoothly anyway.
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => _SystemBars(child: child!),
    );
  }
}

/// Status and navigation bar icons must flip with the theme, or they vanish
/// against the dark background.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: context.colors.navBar,
        systemNavigationBarIconBrightness: icons,
      ),
      child: child,
    );
  }
}
