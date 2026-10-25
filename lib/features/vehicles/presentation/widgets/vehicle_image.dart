import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/car_glyph.dart';

/// A car's photo, or the car glyph on a tinted tile when it has none.
class VehicleImage extends StatelessWidget {
  const VehicleImage({
    super.key,
    required this.photoPath,
    this.width = double.infinity,
    required this.height,
    this.radius = 12,
    this.glyphSize,
  });

  final String? photoPath;
  final double width;
  final double height;
  final double radius;
  final double? glyphSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = Center(
      child: CarGlyph(size: glyphSize ?? height * 0.42, color: c.primary),
    );
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.tile,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.tileBorder),
      ),
      child: photoPath == null
          ? placeholder
          : Image.file(
              File(photoPath!),
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}
