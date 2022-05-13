import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../utils.dart';

/// A widget that displays horizontal dividers betweeen hours of a day.
///
/// See also:
///
/// * [HourDividersStyle], which defines visual properties for this widget.
/// * [TimetableTheme] (and [TimetableConfig]), which provide styles to
///   descendant Timetable widgets.
class HourDividers extends StatelessWidget {
  const HourDividers({
    final Key? key,
    this.style,
    this.child,
  }) : super(key: key);

  final HourDividersStyle? style;
  final Widget? child;

  @override
  Widget build(final BuildContext context) {
    return CustomPaint(
      painter: _HourDividersPainter(
        style: style ?? TimetableTheme.orDefaultOf(context).hourDividersStyle,
      ),
      child: child,
    );
  }
}

/// Defines visual properties for [HourDividers].
///
/// See also:
///
/// * [TimetableThemeData], which bundles the styles for all Timetable widgets.
@immutable
class HourDividersStyle {
  factory HourDividersStyle(
    final BuildContext context, {
    final Color? color,
    final double? width,
  }) {
    final dividerBorderSide = Divider.createBorderSide(context);
    return HourDividersStyle.raw(
      color: color ?? dividerBorderSide.color,
      width: width ?? dividerBorderSide.width,
    );
  }

  const HourDividersStyle.raw({
    required this.color,
    required this.width,
  }) : assert(width >= 0);

  final Color color;
  final double width;

  HourDividersStyle copyWith({final Color? color, final double? width}) {
    return HourDividersStyle.raw(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }

  @override
  int get hashCode => hashValues(color, width);
  @override
  bool operator ==(final Object other) {
    return other is HourDividersStyle &&
        color == other.color &&
        width == other.width;
  }
}

class _HourDividersPainter extends CustomPainter {
  _HourDividersPainter({
    required this.style,
  }) : _paint = Paint()
          ..color = style.color
          ..strokeWidth = style.width;

  final HourDividersStyle style;
  final Paint _paint;

  @override
  void paint(final Canvas canvas, final Size size) {
    final heightPerHour = size.height / Duration.hoursPerDay;
    for (final h in InternalDateTimeTimetable.innerDateHours) {
      final y = h * heightPerHour;
      canvas.drawLine(Offset(-8, y), Offset(size.width, y), _paint);
    }
  }

  @override
  bool shouldRepaint(final _HourDividersPainter oldDelegate) =>
      style != oldDelegate.style;
}
