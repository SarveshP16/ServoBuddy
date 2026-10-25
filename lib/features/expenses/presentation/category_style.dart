import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_palette.dart';
import '../domain/expense_category.dart';

extension CategoryStyle on ExpenseCategory {
  IconData get icon => switch (this) {
    ExpenseCategory.fuel => LucideIcons.fuel,
    ExpenseCategory.service => LucideIcons.wrench,
    ExpenseCategory.rego => LucideIcons.fileText,
    ExpenseCategory.insurance => LucideIcons.shieldCheck,
    ExpenseCategory.repairs => LucideIcons.hammer,
    ExpenseCategory.tolls => LucideIcons.ticket,
    ExpenseCategory.parking => LucideIcons.squareParking,
    ExpenseCategory.carWash => LucideIcons.droplets,
    ExpenseCategory.other => LucideIcons.receipt,
  };

  /// Bar colour in the spend breakdown.
  Color barColor(AppPalette c) => switch (this) {
    ExpenseCategory.fuel => c.primary,
    ExpenseCategory.service => c.serviceBar,
    ExpenseCategory.rego => c.regoBar,
    ExpenseCategory.insurance => c.insuranceBar,
    ExpenseCategory.other => c.otherBar,
    // The newer categories share one set per brightness rather than adding
    // four more colours to each palette.
    ExpenseCategory.repairs => _extra(c, 0),
    ExpenseCategory.tolls => _extra(c, 1),
    ExpenseCategory.parking => _extra(c, 2),
    ExpenseCategory.carWash => _extra(c, 3),
  };
}

Color _extra(AppPalette c, int i) => (c.brightness == Brightness.dark
    ? const [
        Color(0xFFF59E0B),
        Color(0xFF9DB2FF),
        Color(0xFF7FD8C4),
        Color(0xFFC6D96B),
      ]
    : const [
        Color(0xFFB45309),
        Color(0xFF3B5BB5),
        Color(0xFF2E8B78),
        Color(0xFF7A8F1F),
      ])[i];
