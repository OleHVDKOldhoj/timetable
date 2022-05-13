import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../localization.dart';
import '../theme.dart';
import '../utils.dart';

/// A widget that displays the weekday for the given date.
///
/// See also:
///
/// * [WeekdayIndicatorStyle], which defines visual properties for this widget.
/// * [TimetableTheme] (and [TimetableConfig]), which provide styles to
///   descendant Timetable widgets.
class WeekdayIndicator extends StatelessWidget {
  WeekdayIndicator(
    this.date, {
    final Key? key,
    this.style,
  })  : assert(date.isValidTimetableDate),
        super(key: key);

  final DateTime date;
  final WeekdayIndicatorStyle? style;

  @override
  Widget build(final BuildContext context) {
    final style = this.style ??
        TimetableTheme.orDefaultOf(context).weekdayIndicatorStyleProvider(date);

    return DecoratedBox(
      decoration: style.decoration,
      child: Padding(
        padding: style.padding,
        child: Text(style.label, style: style.textStyle),
      ),
    );
  }
}

/// Defines visual properties for [WeekdayIndicator].
///
/// See also:
///
/// * [TimetableThemeData], which bundles the styles for all Timetable widgets.
@immutable
class WeekdayIndicatorStyle {
  factory WeekdayIndicatorStyle(
    final BuildContext context,
    final DateTime date, {
    final Decoration? decoration,
    final EdgeInsetsGeometry? padding,
    final TextStyle? textStyle,
    final String? label,
  }) {
    assert(date.isValidTimetableDate);

    final theme = context.theme;
    return WeekdayIndicatorStyle.raw(
      decoration: decoration ?? BoxDecoration(),
      padding: padding ?? EdgeInsets.zero,
      textStyle: textStyle ??
          theme.textTheme.caption!.copyWith(
            color: date.isToday
                ? theme.colorScheme.primary
                : theme.colorScheme.background.mediumEmphasisOnColor,
          ),
      label: label ??
          () {
            context.dependOnTimetableLocalizations();
            return DateFormat('EEE').format(date);
          }(),
    );
  }

  const WeekdayIndicatorStyle.raw({
    required this.decoration,
    required this.padding,
    required this.textStyle,
    required this.label,
  });

  final Decoration decoration;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final String label;

  WeekdayIndicatorStyle copyWith({
    final Decoration? decoration,
    final EdgeInsetsGeometry? padding,
    final TextStyle? textStyle,
    final String? label,
  }) {
    return WeekdayIndicatorStyle.raw(
      decoration: decoration ?? this.decoration,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      label: label ?? this.label,
    );
  }

  @override
  int get hashCode => hashValues(decoration, padding, textStyle, label);
  @override
  bool operator ==(final Object other) {
    return other is WeekdayIndicatorStyle &&
        decoration == other.decoration &&
        padding == other.padding &&
        textStyle == other.textStyle &&
        label == other.label;
  }
}
