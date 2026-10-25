import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/app_settings.dart';

/// Edits the Home heading. Resolves to the new text ("" means reset), or
/// null if cancelled.
Future<String?> askGarageTitle(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (_) => _GarageTitleDialog(current: current),
    );

class _GarageTitleDialog extends StatefulWidget {
  const _GarageTitleDialog({required this.current});

  final String current;

  @override
  State<_GarageTitleDialog> createState() => _GarageTitleDialogState();
}

class _GarageTitleDialogState extends State<_GarageTitleDialog> {
  late final _text = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: const Text('Home title'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The heading at the top of Home.',
            style: AppText.sub.copyWith(color: c.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            maxLength: AppSettings.garageTitleMaxLength,
            textCapitalization: TextCapitalization.words,
            style: AppText.body.copyWith(color: c.ink),
            decoration: const InputDecoration(
              hintText: AppSettings.defaultGarageTitle,
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text('Reset', style: TextStyle(color: c.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: c.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text('Save', style: TextStyle(color: c.primaryText)),
        ),
      ],
    );
  }
}
