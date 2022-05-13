import 'package:flutter/material.dart';

import '../components/date_header.dart';
import '../components/multi_date_content.dart';
import '../components/multi_date_event_header.dart';
import '../components/time_indicators.dart';
import '../components/week_indicator.dart';
import '../config.dart';
import '../date/controller.dart';
import '../date/date_page_view.dart';
import '../event/builder.dart';
import '../event/event.dart';
import '../event/provider.dart';
import '../theme.dart';
import '../time/controller.dart';
import '../time/zoom.dart';
import '../utils.dart';
import 'recurring_multi_date.dart';

typedef MultiDateTimetableHeaderBuilder = Widget Function(
  BuildContext context,
  double? leadingWidth,
);
typedef MultiDateTimetableContentBuilder = Widget Function(
  BuildContext context,
  ValueChanged<double> onLeadingWidthChanged,
);

/// A Timetable widget that displays multiple consecutive days.
///
/// To configure it, provide a [DateController], [TimeController],
/// [EventProvider], and [EventBuilder] via a [TimetableConfig] widget above in
/// the widget tree. (You can also provide these via `DefaultFoo` widgets
/// directly, like [DefaultDateController].)
///
/// See also:
///
/// * [RecurringMultiDateTimetable], which is a customized variation without
///   scrolling and specific dates – e.g., to show a generic week from Monday to
///   Sunday without dates.
class MultiDateTimetable<E extends Event> extends StatefulWidget {
  MultiDateTimetable({
    final Key? key,
    final MultiDateTimetableHeaderBuilder? headerBuilder,
    final MultiDateTimetableContentBuilder? contentBuilder,
    final Widget? contentLeading,
  })  : headerBuilder = headerBuilder ?? _defaultHeaderBuilder<E>(),
        assert(
          contentBuilder == null || contentLeading == null,
          "`contentLeading` can't be used when `contentBuilder` is specified.",
        ),
        contentBuilder =
            contentBuilder ?? _defaultContentBuilder<E>(contentLeading),
        super(key: key);

  final MultiDateTimetableHeaderBuilder headerBuilder;
  static MultiDateTimetableHeaderBuilder
      _defaultHeaderBuilder<E extends Event>() {
    return (final context, final leadingWidth) => MultiDateTimetableHeader<E>(
          leading: SizedBox(
            width: leadingWidth,
            child: Center(child: WeekIndicator.forController(null)),
          ),
        );
  }

  final MultiDateTimetableContentBuilder contentBuilder;
  static MultiDateTimetableContentBuilder
      _defaultContentBuilder<E extends Event>(final Widget? contentLeading) {
    return (final context, final onLeadingWidthChanged) => MultiDateTimetableContent<E>(
          leading: SizeReportingWidget(
            onSizeChanged: (final size) => onLeadingWidthChanged(size.width),
            child: contentLeading ?? _defaultContentLeading,
          ),
        );
  }

  @override
  _MultiDateTimetableState<E> createState() => _MultiDateTimetableState();
}

class _MultiDateTimetableState<E extends Event>
    extends State<MultiDateTimetable<E>> {
  double? _leadingWidth;

  @override
  Widget build(final BuildContext context) {
    final eventProvider = DefaultEventProvider.of<E>(context) ?? (final _) => [];

    return Column(children: [
      DefaultEventProvider<E>(
        eventProvider: (final visibleDates) =>
            eventProvider(visibleDates).where((final it) => it.isAllDay).toList(),
        child: Builder(
          builder: (final context) => widget.headerBuilder(context, _leadingWidth),
        ),
      ),
      Expanded(
        child: DefaultEventProvider<E>(
          eventProvider: (final visibleDates) =>
              eventProvider(visibleDates).where((final it) => it.isPartDay).toList(),
          child: Builder(
            builder: (final contxt) => widget.contentBuilder(
              context,
              (final newWidth) => setState(() => _leadingWidth = newWidth),
            ),
          ),
        ),
      ),
    ]);
  }
}

class MultiDateTimetableHeader<E extends Event> extends StatelessWidget {
  MultiDateTimetableHeader({
    final Key? key,
    final Widget? leading,
    final DateWidgetBuilder? dateHeaderBuilder,
    final Widget? bottom,
  })  : leading = leading ?? Center(child: WeekIndicator.forController(null)),
        dateHeaderBuilder =
            dateHeaderBuilder ?? ((final context, final date) => DateHeader(date)),
        bottom = bottom ?? MultiDateEventHeader<E>(),
        super(key: key);

  final Widget leading;
  final DateWidgetBuilder dateHeaderBuilder;
  final Widget bottom;

  @override
  Widget build(final BuildContext context) {
    return Row(children: [
      leading,
      Expanded(
        child: Column(children: [
          DatePageView(shrinkWrapInCrossAxis: true, builder: dateHeaderBuilder),
          bottom,
        ]),
      ),
    ]);
  }
}

class MultiDateTimetableContent<E extends Event> extends StatelessWidget {
  MultiDateTimetableContent({
    final Key? key,
    final Widget? leading,
    final Widget? divider,
    final Widget? content,
  })  : leading = leading ?? _defaultContentLeading,
        divider = divider ?? VerticalDivider(width: 0),
        content = content ?? MultiDateContent<E>(),
        super(key: key);

  final Widget leading;
  final Widget divider;
  final Widget content;

  @override
  Widget build(final BuildContext context) {
    return Row(children: [
      leading,
      divider,
      Expanded(child: content),
    ]);
  }
}

// TODO(JonasWanke): Explicitly disable the scrollbar when they're shown by
// default on desktop: https://flutter.dev/docs/release/breaking-changes/default-desktop-scrollbars
// Builder(
//   builder:(context) => ScrollConfiguration(
//   behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
// )

Widget _defaultContentLeading = TimeZoom(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Builder(
      builder: (final context) => TimeIndicators.hours(
        // `TimeIndicators.hours` overwrites the style provider's labels by
        // default, but here we want the user's style provider from the ambient
        // theme to take precedence.
        styleProvider: TimetableTheme.of(context)?.timeIndicatorStyleProvider,
      ),
    ),
  ),
);
