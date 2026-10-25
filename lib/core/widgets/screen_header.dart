import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// A screen's top row: optional leading button, title in condensed capitals,
/// optional trailing action.
///
/// With a leading button the title is centred, as on a pushed screen. Without
/// one and with [centerTitle] off it's a tab's big page title ("EXPENSES").
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerTitle = true,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pageTitle = leading == null && !centerTitle;
    final text = Text(
      title.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: centerTitle ? TextAlign.center : TextAlign.start,
      style: (pageTitle ? AppText.pageTitle : AppText.screenTitle).copyWith(
        color: c.ink,
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(20, pageTitle ? 22 : 16, 20, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            ?leading,
            if (leading != null && !centerTitle) const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: centerTitle && leading != null ? 10 : 0,
                ),
                child: text,
              ),
            ),
            // Keeps a centred title centred when only one side has a button.
            if (trailing != null)
              trailing!
            else if (centerTitle && leading != null)
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }
}
