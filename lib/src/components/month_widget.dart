import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

import '../config.dart';
import '../theme.dart';
import '../utils.dart';
import '../week.dart';
import 'date_indicator.dart';
import 'week_indicator.dart';
import 'weekday_indicator.dart';

/// A widget that displays the days of the given month in a grid, with weekdays
/// at the top and week numbers at the left.
///
/// See also:
///
/// * [MonthWidgetStyle], which defines visual properties for this widget.
/// * [TimetableTheme] (and [TimetableConfig]), which provide styles to
///   descendant Timetable widgets.
class MonthWidget extends StatelessWidget {
  MonthWidget(
    this.month, {
    final DateWidgetBuilder? weekDayBuilder,
    final WeekWidgetBuilder? weekBuilder,
    final DateWidgetBuilder? dateBuilder,
    this.style,
  })  : assert(month.isValidTimetableMonth),
        weekDayBuilder =
            weekDayBuilder ?? ((final context, final date) => WeekdayIndicator(date)),
        weekBuilder = weekBuilder ??
            ((final context, final week) {
              final timetableTheme = TimetableTheme.orDefaultOf(context);
              return WeekIndicator(
                week,
                style: (style ?? timetableTheme.monthWidgetStyleProvider(month))
                        .removeIndividualWeekDecorations
                    ? timetableTheme
                        .weekIndicatorStyleProvider(week)
                        .copyWith(decoration: BoxDecoration())
                    : null,
                alwaysUseNarrowestVariant: true,
              );
            }),
        dateBuilder = dateBuilder ??
            ((final context, final date) {
              assert(date.isValidTimetableDate);

              final timetableTheme = TimetableTheme.orDefaultOf(context);
              DateIndicatorStyle? dateStyle;
              if (date.firstDayOfMonth != month &&
                  (style ?? timetableTheme.monthWidgetStyleProvider(month))
                      .showDatesFromOtherMonthsAsDisabled) {
                final original =
                    timetableTheme.dateIndicatorStyleProvider(date);
                dateStyle = original.copyWith(
                  textStyle: original.textStyle.copyWith(
                    color: context.theme.colorScheme.background.disabledOnColor,
                  ),
                );
              }
              return DateIndicator(date, style: dateStyle);
            });

  final DateTime month;

  final DateWidgetBuilder weekDayBuilder;
  final WeekWidgetBuilder weekBuilder;
  final DateWidgetBuilder dateBuilder;

  final MonthWidgetStyle? style;

  @override
  Widget build(final BuildContext context) {
    final style = this.style ??
        TimetableTheme.orDefaultOf(context).monthWidgetStyleProvider(month);

    final firstDay = month.previousOrSame(style.startOfWeek);
    final minDayCount = month.lastDayOfMonth.difference(firstDay).inDays + 1;
    final weekCount = (minDayCount / DateTime.daysPerWeek).ceil();

    final today = DateTimeTimetable.today();

    Widget buildDate(final int week, final int weekday) {
      final date = firstDay + (DateTime.daysPerWeek * week + weekday).days;
      if (!style.showDatesFromOtherMonths && date.firstDayOfMonth != month) {
        return SizedBox.shrink();
      }

      return Center(
        child: Padding(
          padding: style.datePadding,
          child: dateBuilder(context, date),
        ),
      );
    }

    return LayoutGrid(
      columnSizes: [
        auto,
        ...repeat(DateTime.daysPerWeek, [1.fr]),
      ],
      rowSizes: [
        auto,
        ...repeat(weekCount, [auto]),
      ],
      children: [
        // By using today as the base, highlighting for the current day is
        // applied automatically.
        for (final day in 1.rangeTo(DateTime.daysPerWeek))
          GridPlacement(
            columnStart: day,
            rowStart: 0,
            child: Center(
              child:
                  weekDayBuilder(context, today + (day - today.weekday).days),
            ),
          ),
        GridPlacement(
          columnStart: 0,
          rowStart: 1,
          rowSpan: weekCount,
          child: _buildWeeks(context, style, firstDay, weekCount),
        ),
        for (final week in 0.until(weekCount))
          for (final weekday in 0.until(DateTime.daysPerWeek))
            GridPlacement(
              columnStart: 1 + weekday,
              rowStart: 1 + week,
              child: buildDate(week, weekday),
            ),
      ],
    );
  }

  Widget _buildWeeks(
    final BuildContext context,
    final MonthWidgetStyle style,
    final DateTime firstDay,
    final int weekCount,
  ) {
    assert(firstDay.isValidTimetableDate);

    return DecoratedBox(
      decoration: style.weeksDecoration,
      child: Padding(
        padding: style.weeksPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final index in 0.until(weekCount))
              weekBuilder(
                context,
                (firstDay + (index * DateTime.daysPerWeek).days).week,
              ),
          ],
        ),
      ),
    );
  }
}

/// Defines visual properties for [MonthWidget].
///
/// See also:
///
/// * [TimetableThemeData], which bundles the styles for all Timetable widgets.
@immutable
class MonthWidgetStyle {
  factory MonthWidgetStyle(
    final BuildContext context,
    final DateTime month, {
    final int? startOfWeek,
    final Decoration? weeksDecoration,
    final EdgeInsetsGeometry? weeksPadding,
    bool? removeIndividualWeekDecorations,
    final EdgeInsetsGeometry? datePadding,
    final bool? showDatesFromOtherMonths,
    final bool? showDatesFromOtherMonthsAsDisabled,
  }) {
    assert(startOfWeek.isValidTimetableDayOfWeek);
    assert(month.isValidTimetableMonth);

    final theme = context.theme;
    removeIndividualWeekDecorations ??= true;
    return MonthWidgetStyle.raw(
      startOfWeek: startOfWeek ?? DateTime.monday,
      weeksDecoration: weeksDecoration ??
          (removeIndividualWeekDecorations
              ? BoxDecoration(
                  color: theme.colorScheme.brightness.contrastColor
                      .withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                )
              : BoxDecoration()),
      weeksPadding: weeksPadding ?? EdgeInsets.symmetric(vertical: 12),
      removeIndividualWeekDecorations: removeIndividualWeekDecorations,
      datePadding: datePadding ?? EdgeInsets.all(4),
      showDatesFromOtherMonths: showDatesFromOtherMonths ?? true,
      showDatesFromOtherMonthsAsDisabled:
          showDatesFromOtherMonthsAsDisabled ?? true,
    );
  }

  const MonthWidgetStyle.raw({
    required this.startOfWeek,
    required this.weeksDecoration,
    required this.weeksPadding,
    required this.removeIndividualWeekDecorations,
    required this.datePadding,
    required this.showDatesFromOtherMonths,
    required this.showDatesFromOtherMonthsAsDisabled,
  });

  final int startOfWeek;
  final Decoration weeksDecoration;
  final EdgeInsetsGeometry weeksPadding;
  final bool removeIndividualWeekDecorations;
  final EdgeInsetsGeometry datePadding;

  /// Whether dates from adjacent months are displayed to fill the grid.
  final bool showDatesFromOtherMonths;

  /// Whether dates from adjacent months are displayed with lower text opacity.
  final bool showDatesFromOtherMonthsAsDisabled;

  MonthWidgetStyle copyWith({
    final int? startOfWeek,
    final Decoration? weeksDecoration,
    final EdgeInsetsGeometry? weeksPadding,
    final bool? removeIndividualWeekDecorations,
    final EdgeInsetsGeometry? datePadding,
    final bool? showDatesFromOtherMonths,
    final bool? showDatesFromOtherMonthsAsDisabled,
  }) {
    return MonthWidgetStyle.raw(
      startOfWeek: startOfWeek ?? this.startOfWeek,
      weeksDecoration: weeksDecoration ?? this.weeksDecoration,
      weeksPadding: weeksPadding ?? this.weeksPadding,
      removeIndividualWeekDecorations: removeIndividualWeekDecorations ??
          this.removeIndividualWeekDecorations,
      datePadding: datePadding ?? this.datePadding,
      showDatesFromOtherMonths:
          showDatesFromOtherMonths ?? this.showDatesFromOtherMonths,
      showDatesFromOtherMonthsAsDisabled: showDatesFromOtherMonthsAsDisabled ??
          this.showDatesFromOtherMonthsAsDisabled,
    );
  }

  @override
  int get hashCode => hashValues(
        startOfWeek,
        weeksDecoration,
        weeksPadding,
        removeIndividualWeekDecorations,
        datePadding,
        showDatesFromOtherMonths,
        showDatesFromOtherMonthsAsDisabled,
      );
  @override
  bool operator ==(final Object other) {
    return other is MonthWidgetStyle &&
        startOfWeek == other.startOfWeek &&
        weeksDecoration == other.weeksDecoration &&
        weeksPadding == other.weeksPadding &&
        removeIndividualWeekDecorations ==
            other.removeIndividualWeekDecorations &&
        datePadding == other.datePadding &&
        showDatesFromOtherMonths == other.showDatesFromOtherMonths &&
        showDatesFromOtherMonthsAsDisabled ==
            other.showDatesFromOtherMonthsAsDisabled;
  }
}
