import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../format/dates.dart';
import '../theme/app_palette.dart';
import '../theme/app_typography.dart';
import '../utils/calendar.dart';

/// Looks like a text field; tapping opens the date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Pick a date',
    this.firstDate,
    this.lastDate,
    this.clearable = false,
  });

  final DateTime? value;

  /// Called with null when cleared.
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Optional dates (rego expiry) get a clear button.
  final bool clearable;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 30),
      lastDate: lastDate ?? DateTime(now.year + 10),
    );
    if (picked != null) onChanged(dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.border, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? placeholder : formatDate(value!),
                  style: AppText.body.copyWith(
                    color: value == null ? c.faint : c.ink,
                  ),
                ),
              ),
              if (clearable && value != null)
                IconButton(
                  onPressed: () => onChanged(null),
                  tooltip: 'Clear',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(LucideIcons.x, size: 18, color: c.muted),
                )
              else
                Icon(LucideIcons.calendar, size: 20, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }
}
