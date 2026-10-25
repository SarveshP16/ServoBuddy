import 'package:flutter/material.dart';

/// Shows a toast, replacing any that's still on screen instead of queueing
/// behind it (rapid deletes would otherwise stack toasts that never go away).
///
/// [onDismissed] runs when it goes away *without* the action being tapped —
/// the moment an undoable delete becomes final.
void showAppSnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  VoidCallback? onDismissed,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      action: actionLabel == null
          ? null
          : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
  if (onDismissed != null) {
    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) onDismissed();
    });
  }
}
