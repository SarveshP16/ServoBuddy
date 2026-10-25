import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The Road Sign look: NSW sign green and number-plate yellow, in light and
/// dark.
abstract final class AppPalettes {
  static const all = [light, dark];

  static const light = AppPalette(
    background: Color(0xFFF2F3EF),
    surface: Color(0xFFFFFFFF),
    cardBorder: Color(0x00FFFFFF),
    border: Color(0xFFCBD3CB),
    tile: Color(0xFFE3EFE7),
    tileBorder: Color(0x00FFFFFF),
    primary: Color(0xFF0A5C36),
    onPrimary: Color(0xFFFFFFFF),
    primaryText: Color(0xFF0A5C36),
    hero: Color(0xFF0A5C36),
    onHero: Color(0xFFFFFFFF),
    highlight: Color(0xFFFFD200),
    onHighlight: Color(0xFF111111),
    ink: Color(0xFF0F1A14),
    muted: Color(0xFF4B5A51),
    subtle: Color(0xFF4B5A51),
    faint: Color(0xFF7D8A82),
    positive: Color(0xFF0A7A45),
    track: Color(0xFFE3E8E2),
    warn: Color(0xFFB45309),
    warnInk: Color(0xFF6B3305),
    warnMuted: Color(0xFF6B5A40),
    warnTint: Color(0xFFFFF8D6),
    warnTile: Color(0xFFFFE98A),
    warnBorder: Color(0xFFE0B400),
    badge: Color(0xFFFFD200),
    onBadge: Color(0xFF111111),
    navBar: Color(0xFFFFFFFF),
    serviceBar: Color(0xFFFFD200),
    regoBar: Color(0xFF111111),
    insuranceBar: Color(0xFF2F7FA8),
    otherBar: Color(0xFF9AA59E),
  );

  /// The same signage at night: the green panel stays deep, text and
  /// accents brighten so they hold up on near-black.
  static const dark = AppPalette(
    background: Color(0xFF0D1310),
    surface: Color(0xFF161E19),
    cardBorder: Color(0xFF24302A),
    border: Color(0xFF34443A),
    tile: Color(0xFF1D2A23),
    tileBorder: Color(0xFF2C3A32),
    primary: Color(0xFF3DBE7A),
    onPrimary: Color(0xFF04140B),
    primaryText: Color(0xFF4CC786),
    hero: Color(0xFF0E5A36),
    onHero: Color(0xFFFFFFFF),
    highlight: Color(0xFFFFD200),
    onHighlight: Color(0xFF111111),
    ink: Color(0xFFE9EFEA),
    muted: Color(0xFFA3B2A8),
    subtle: Color(0xFFA3B2A8),
    faint: Color(0xFF75857B),
    positive: Color(0xFF4CC786),
    track: Color(0xFF24302A),
    warn: Color(0xFFFFC83D),
    warnInk: Color(0xFFFFE7A3),
    warnMuted: Color(0xFFC9B98A),
    warnTint: Color(0xFF2A2410),
    warnTile: Color(0xFF3A3112),
    warnBorder: Color(0xFF8A7020),
    badge: Color(0xFFFFD200),
    onBadge: Color(0xFF111111),
    navBar: Color(0xFF111814),
    serviceBar: Color(0xFFFFD200),
    regoBar: Color(0xFFE9EFEA),
    insuranceBar: Color(0xFF5AB0DA),
    otherBar: Color(0xFF75857B),
  );
}
