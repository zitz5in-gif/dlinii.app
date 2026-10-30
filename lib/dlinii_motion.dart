import 'package:flutter/material.dart';

/// A drawn D keeps loading controls independent of icon fonts and network assets.
class DliniiLoader extends StatefulWidget {
  final double size;
  final Color color;
  final String label;
  const DliniiLoader({
    super.key,
    this.size = 28,
    this.color = const Color(0xFF101A17),
    this.label = 'جارٍ التحميل',
  });
  @override
  State<DliniiLoader> createState() => _DliniiLoaderState();
}

class _DliniiLoaderState extends State<DliniiLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      _animation.value = 1;
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    liveRegion: true,
    child: SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) =>
            CustomPaint(painter: _DStroke(_animation.value, widget.color)),
      ),
    ),
  );
}

class _DStroke extends CustomPainter {
  final double progress;
  final Color color;
  _DStroke(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final path = Path()
      ..moveTo(6, 27)
      ..lineTo(6, 11)
      ..quadraticBezierTo(6, 8, 9, 8)
      ..lineTo(18, 8)
      ..moveTo(24, 4)
      ..cubicTo(16, 15, 25, 14, 25, 21)
      ..cubicTo(25, 25, 18, 27, 11, 29)
      ..moveTo(20, 5)
      ..lineTo(24, 2)
      ..lineTo(27, 7);
    final pen = Paint()
      ..color = color.withValues(alpha: .15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, pen);
    pen.color = color;
    for (final metric in path.computeMetrics()) {
      final start = progress * metric.length;
      final end = start + metric.length * .65;
      canvas.drawPath(
        metric.extractPath(start, end.clamp(0, metric.length)),
        pen,
      );
      if (end > metric.length)
        canvas.drawPath(metric.extractPath(0, end - metric.length), pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DStroke old) =>
      old.progress != progress || old.color != color;
}
