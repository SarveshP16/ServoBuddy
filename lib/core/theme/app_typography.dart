import 'package:flutter/material.dart';

/// Archivo throughout, like road signage: condensed and heavy for headings,
/// normal width for everything you read. It's a variable font, so weights
/// come from `fontWeight` and the narrow headings from the `wdth` axis.
abstract final class AppText {
  static const family = 'Archivo';

  static const _narrow = [FontVariation('wdth', 75)];
  static const _semiNarrow = [FontVariation('wdth', 85)];

  /// "SARVESH", "EXPENSES". Set in capitals by the widgets that use it.
  static const pageTitle = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: FontWeight.w900,
    fontVariations: _narrow,
    letterSpacing: 0.3,
    height: 1.05,
  );

  /// Title in a screen header ("HONDA CIVIC").
  static const screenTitle = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    fontVariations: _narrow,
    letterSpacing: 0.4,
    height: 1.15,
  );

  /// The car's name on its road-sign panel.
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    fontVariations: _narrow,
    letterSpacing: 0.3,
    height: 1.0,
  );

  /// Sheet and dialog titles, empty-state headlines.
  static const section = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// Small green capitals over a group: "RECENT", "SERVICE HISTORY".
  static const eyebrow = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    height: 1.2,
  );

  /// Vehicle names, list-row titles.
  static const cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const body = TextStyle(
    fontFamily: family,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// Secondary lines under a title ("2019 · 42,180 km").
  static const sub = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Form labels, bold small captions.
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Chip text.
  static const chip = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// "$1,240", "850 km".
  static const stat = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    fontVariations: _semiNarrow,
    height: 1.1,
  );

  /// Right-aligned money in list rows.
  static const amount = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// Badges, the plate's "NSW".
  static const tiny = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
}
