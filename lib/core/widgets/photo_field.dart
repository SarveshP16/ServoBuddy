import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_typography.dart';

/// Pick-a-photo box: shows the photo with Replace/Remove, or an add prompt.
/// [path] is either a stored photo or a freshly picked temp file; the caller
/// imports it into app storage on save.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.path,
    required this.onChanged,
    this.addLabel = 'Add photo',
    this.height = 140,
  });

  final String? path;
  final ValueChanged<String?> onChanged;
  final String addLabel;
  final double height;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) onChanged(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(14);
    if (path == null) {
      return Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.border, width: 1.2),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _pick(context),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.imagePlus, size: 20, color: c.primaryText),
                const SizedBox(width: 8),
                Text(
                  addLabel,
                  style: AppText.cardTitle.copyWith(color: c.primaryText),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Image.file(
              File(path!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: c.tile,
                child: Icon(LucideIcons.image, color: c.muted),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _pick(context),
              child: Text('Replace', style: TextStyle(color: c.primaryText)),
            ),
            TextButton(
              onPressed: () => onChanged(null),
              child: Text('Remove', style: TextStyle(color: c.warn)),
            ),
          ],
        ),
      ],
    );
  }
}
