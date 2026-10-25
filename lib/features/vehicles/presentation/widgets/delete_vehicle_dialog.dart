import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

enum DeleteVehicleChoice { keepHistory, everything }

/// "Delete Toyota Corolla?" with the two ways to do it. Null if cancelled.
Future<DeleteVehicleChoice?> askDeleteVehicle(
  BuildContext context, {
  required String name,
}) => showDialog<DeleteVehicleChoice>(
  context: context,
  builder: (context) {
    final c = context.colors;
    Widget option(
      DeleteVehicleChoice choice,
      String title,
      String detail, {
      bool destructive = false,
    }) => InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, choice),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppText.cardTitle.copyWith(
                color: destructive ? c.warn : c.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(detail, style: AppText.sub.copyWith(color: c.muted)),
          ],
        ),
      ),
    );

    return AlertDialog(
      title: Text('Delete $name?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          option(
            DeleteVehicleChoice.keepHistory,
            'Delete, keep expense history',
            'Its expenses stay in Expenses and your totals. Service '
                'schedules, reminders and recurring costs are removed.',
          ),
          const Divider(),
          option(
            DeleteVehicleChoice.everything,
            'Delete everything',
            'Removes the car and all its expenses, service records and '
                "photos. Can't be undone.",
            destructive: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: c.muted)),
        ),
      ],
    );
  },
);
