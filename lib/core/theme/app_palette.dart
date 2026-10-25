import 'package:flutter/material.dart';

/// Every colour a theme draws with. Read it with `context.colors` so widgets
/// follow the active theme. The light and dark Road Sign palettes are in
/// app_palettes.dart.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.cardBorder,
    required this.border,
    required this.tile,
    required this.tileBorder,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.hero,
    required this.onHero,
    required this.highlight,
    required this.onHighlight,
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.faint,
    required this.positive,
    required this.track,
    required this.warn,
    required this.warnInk,
    required this.warnMuted,
    required this.warnTint,
    required this.warnTile,
    required this.warnBorder,
    required this.badge,
    required this.onBadge,
    required this.navBar,
    required this.serviceBar,
    required this.regoBar,
    required this.insuranceBar,
    required this.otherBar,
  });

  final Color background;

  /// Cards, inputs, chips at rest.
  final Color surface;

  /// Outline around cards (invisible in light, where cards sit on grey).
  final Color cardBorder;

  /// Chip and input outlines.
  final Color border;

  /// Behind car icons and list-row icons.
  final Color tile;
  final Color tileBorder;

  /// Sign green: selected chips, primary buttons, active nav item.
  final Color primary;
  final Color onPrimary;

  /// [primary] when used as text on [surface] (links, "See all").
  final Color primaryText;

  /// The road-sign panel behind the main car on Home and the vehicle page.
  final Color hero;
  final Color onHero;

  /// Number-plate yellow: the plate badge, the log button, call-outs.
  /// Always paired with [onHighlight], and outlined in ink so it reads on
  /// white as well as on green.
  final Color highlight;
  final Color onHighlight;

  /// Titles and amounts.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Inactive nav items.
  final Color subtle;

  /// Chevrons, placeholder text.
  final Color faint;

  /// "on 2 vehicles".
  final Color positive;

  /// Empty part of a progress bar.
  final Color track;

  /// Due-soon / overdue accents.
  final Color warn;
  final Color warnInk;
  final Color warnMuted;
  final Color warnTint;
  final Color warnTile;
  final Color warnBorder;

  /// "Service overdue" pill.
  final Color badge;
  final Color onBadge;

  final Color navBar;

  /// Spend-breakdown bars per category (fuel uses [primary]).
  final Color serviceBar;
  final Color regoBar;
  final Color insuranceBar;
  final Color otherBar;

  Brightness get brightness =>
      background.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light;

  @override
  AppPalette copyWith() => this;

  /// Themes switch instantly; there's nothing to animate between.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette && t >= 0.5 ? other : this;
}

extension AppPaletteContext on BuildContext {
  /// The palette for the active theme.
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
