import 'package:flutter/material.dart';

/// The mockups' car mark: a flat-roofed cabin with two wheels, drawn as a
/// stroke so it scales from a nav icon to the vehicle-detail hero.
class CarGlyph extends StatelessWidget {
  const CarGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _CarPainter(color)),
  );
}

class _CarPainter extends CustomPainter {
  _CarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = (w * 0.085).clamp(1.6, 7.0);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Body: roof line, sloping windscreen/rear, straight sides, floor.
    final body = Path()
      ..moveTo(w * 0.14, h * 0.74)
      ..lineTo(w * 0.14, h * 0.40)
      ..lineTo(w * 0.24, h * 0.18)
      ..lineTo(w * 0.76, h * 0.18)
      ..lineTo(w * 0.86, h * 0.40)
      ..lineTo(w * 0.86, h * 0.74)
      ..moveTo(w * 0.14, h * 0.66)
      ..lineTo(w * 0.86, h * 0.66);
    canvas.drawPath(body, paint);

    final wheel = w * 0.085;
    canvas.drawCircle(Offset(w * 0.25, h * 0.74), wheel, paint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.74), wheel, paint);
  }

  @override
  bool shouldRepaint(_CarPainter old) => old.color != color;
}
