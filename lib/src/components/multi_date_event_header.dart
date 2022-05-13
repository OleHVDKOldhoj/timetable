import 'dart:ui';

import 'package:black_hole_flutter/black_hole_flutter.dart';
import 'package:flutter/material.dart' hide Interval;
import 'package:flutter/rendering.dart';

import '../callbacks.dart';
import '../config.dart';
import '../date/controller.dart';
import '../date/date_page_view.dart';
import '../date/visible_date_range.dart';
import '../event/all_day.dart';
import '../event/builder.dart';
import '../event/event.dart';
import '../event/provider.dart';
import '../theme.dart';
import '../utils.dart';

/// A widget that displays all-day [Event]s.
///
/// A [DefaultDateController] and [DefaultEventBuilder] must be above in the
/// widget tree.
///
/// If [onBackgroundTap] is not supplied, [DefaultTimetableCallbacks]'s
/// `onDateBackgroundTap` is used if it's provided above in the widget tree.
///
/// See also:
///
/// * [DefaultEventProvider] (and [TimetableConfig]), which provide the [Event]s
///   to be displayed.
/// * [MultiDateEventHeaderStyle], which defines visual properties for this
///   widget.
/// * [TimetableTheme] (and [TimetableConfig]), which provide styles to
///   descendant Timetable widgets.
/// * [DefaultTimetableCallbacks], which provides callbacks to descendant
///   Timetable widgets.
class MultiDateEventHeader<E extends Event> extends StatelessWidget {
  const MultiDateEventHeader({
    final Key? key,
    this.onBackgroundTap,
    this.style,
  }) : super(key: key);

  final DateTapCallback? onBackgroundTap;
  final MultiDateEventHeaderStyle? style;

  @override
  Widget build(final BuildContext context) {
    final style = this.style ??
        TimetableTheme.orDefaultOf(context).multiDateEventHeaderStyle;

    return Stack(children: [
      Positioned.fill(
        child: DatePageView(builder: (final context, final date) => SizedBox()),
      ),
      ClipRect(
        child: Padding(
          padding: style.padding,
          child: LayoutBuilder(
            builder: (final context, final constraints) =>
                ValueListenableBuilder<DatePageValue>(
              valueListenable: DefaultDateController.of(context)!,
              builder: (final context, final pageValue, final __) => _buildContent(
                context,
                style,
                pageValue,
                constraints.maxWidth,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildContent(
    final BuildContext context,
    final MultiDateEventHeaderStyle style,
    final DatePageValue pageValue,
    final double width,
  ) {
    final visibleDates = Interval(
      DateTimeTimetable.dateFromPage(pageValue.page.floor()),
      DateTimeTimetable.dateFromPage(
            (pageValue.page + pageValue.visibleDayCount).ceil(),
          ) -
          1.milliseconds,
    );
    assert(visibleDates.isValidTimetableDateInterval);

    final onBackgroundTap = this.onBackgroundTap ??
        DefaultTimetableCallbacks.of(context)?.onDateBackgroundTap;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: onBackgroundTap != null
          ? (final details) {
              final tappedCell =
                  details.localPosition.dx / width * pageValue.visibleDayCount;
              final page = (pageValue.page + tappedCell).floor();
              onBackgroundTap(DateTimeTimetable.dateFromPage(page));
            }
          : null,
      child: _buildEventLayout(context, style, visibleDates, pageValue),
    );
  }

  Widget _buildEventLayout(
    final BuildContext context,
    final MultiDateEventHeaderStyle style,
    final Interval visibleDates,
    final DatePageValue pageValue,
  ) {
    assert(visibleDates.isValidTimetableDateInterval);

    final events =
        DefaultEventProvider.of<E>(context)?.call(visibleDates) ?? [];

    return _EventsWidget<E>(
      visibleRange: pageValue.visibleRange,
      currentlyVisibleDates: visibleDates,
      page: pageValue.page,
      eventHeight: style.eventHeight,
      children: [
        for (final event in events)
          _EventParentDataWidget<E>(
            key: ValueKey(event),
            event: event,
            child: _buildEvent(context, event, pageValue),
          ),
      ],
    );
  }

  Widget _buildEvent(final BuildContext context, final E event, final DatePageValue pageValue) {
    return DefaultEventBuilder.allDayOf<E>(context)!(
      context,
      event,
      AllDayEventLayoutInfo(
        hiddenStartDays: (pageValue.page - event.start.page).coerceAtLeast(0),
        hiddenEndDays:
            (event.end.page.ceil() - pageValue.page - pageValue.visibleDayCount)
                .coerceAtLeast(0),
      ),
    );
  }
}

/// Defines visual properties for [MultiDateEventHeader].
class MultiDateEventHeaderStyle {
  factory MultiDateEventHeaderStyle(
    // To allow future updates to use the context and align the parameters to
    // other style constructors.
    // ignore: avoid_unused_constructor_parameters
    final BuildContext context, {
    final double? eventHeight,
    final EdgeInsetsGeometry? padding,
  }) {
    return MultiDateEventHeaderStyle.raw(
      eventHeight: eventHeight ?? 24,
      padding: padding ?? EdgeInsets.zero,
    );
  }

  const MultiDateEventHeaderStyle.raw({
    this.eventHeight = 24,
    this.padding = EdgeInsets.zero,
  });

  /// Height of a single all-day event.
  final double eventHeight;

  final EdgeInsetsGeometry padding;

  MultiDateEventHeaderStyle copyWith({
    final double? eventHeight,
    final EdgeInsetsGeometry? padding,
  }) {
    return MultiDateEventHeaderStyle.raw(
      eventHeight: eventHeight ?? this.eventHeight,
      padding: padding ?? this.padding,
    );
  }

  @override
  int get hashCode => hashValues(eventHeight, padding);
  @override
  bool operator ==(final Object other) {
    return other is MultiDateEventHeaderStyle &&
        eventHeight == other.eventHeight &&
        padding == other.padding;
  }
}

class _EventParentDataWidget<E extends Event>
    extends ParentDataWidget<_EventParentData<E>> {
  const _EventParentDataWidget({
    final Key? key,
    required this.event,
    required final Widget child,
  }) : super(key: key, child: child);

  final E event;

  @override
  Type get debugTypicalAncestorWidgetClass => _EventsWidget;

  @override
  void applyParentData(final RenderObject renderObject) {
    assert(renderObject.parentData is _EventParentData<E>);
    final parentData = renderObject.parentData! as _EventParentData<E>;

    if (parentData.event == event) return;

    parentData.event = event;
    final targetParent = renderObject.parent;
    if (targetParent is RenderObject) targetParent.markNeedsLayout();
  }
}

class _EventsWidget<E extends Event> extends MultiChildRenderObjectWidget {
  _EventsWidget({
    required this.visibleRange,
    required this.currentlyVisibleDates,
    required this.page,
    required this.eventHeight,
    required final List<_EventParentDataWidget<E>> children,
  }) : super(children: children);

  final VisibleDateRange visibleRange;
  final Interval currentlyVisibleDates;
  final double page;
  final double eventHeight;

  @override
  RenderObject createRenderObject(final BuildContext context) {
    return _EventsLayout<E>(
      visibleRange: visibleRange,
      currentlyVisibleDates: currentlyVisibleDates,
      page: page,
      eventHeight: eventHeight,
    );
  }

  @override
  void updateRenderObject(final BuildContext context, final _EventsLayout<E> renderObject) {
    renderObject
      ..visibleRange = visibleRange
      ..currentlyVisibleDates = currentlyVisibleDates
      ..page = page
      ..eventHeight = eventHeight;
  }
}

class _EventParentData<E extends Event>
    extends ContainerBoxParentData<RenderBox> {
  E? event;
}

class _EventsLayout<E extends Event> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EventParentData<E>>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EventParentData<E>> {
  _EventsLayout({
    required final VisibleDateRange visibleRange,
    required final Interval currentlyVisibleDates,
    required final double page,
    required final double eventHeight,
  })  : _visibleRange = visibleRange,
        assert(currentlyVisibleDates.isValidTimetableDateInterval),
        _currentlyVisibleDates = currentlyVisibleDates,
        _page = page,
        _eventHeight = eventHeight;

  VisibleDateRange _visibleRange;
  VisibleDateRange get visibleRange => _visibleRange;
  set visibleRange(final VisibleDateRange value) {
    if (_visibleRange == value) return;

    _visibleRange = value;
    markNeedsLayout();
  }

  Interval _currentlyVisibleDates;
  Interval get currentlyVisibleDates => _currentlyVisibleDates;
  set currentlyVisibleDates(final Interval value) {
    assert(value.isValidTimetableDateInterval);
    if (_currentlyVisibleDates == value) return;

    _currentlyVisibleDates = value;
    markNeedsLayout();
  }

  double _page;
  double get page => _page;
  set page(final double value) {
    if (_page == value) return;

    _page = value;
    markNeedsLayout();
  }

  double _eventHeight;
  double get eventHeight => _eventHeight;
  set eventHeight(final double value) {
    if (_eventHeight == value) return;

    _eventHeight = value;
    markNeedsLayout();
  }

  Iterable<E> get _events => children.map((final child) => child.data<E>().event!);

  @override
  void setupParentData(final RenderObject child) {
    if (child.parentData is! _EventParentData<E>) {
      child.parentData = _EventParentData<E>();
    }
  }

  @override
  double computeMinIntrinsicWidth(final double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0;
  }

  @override
  double computeMaxIntrinsicWidth(final double height) {
    assert(_debugThrowIfNotCheckingIntrinsics());
    return 0;
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw Exception("_EventsLayout doesn't have an intrinsic width.");
      }
      return true;
    }());
    return true;
  }

  @override
  double computeMinIntrinsicHeight(final double width) =>
      _parallelEventCount() * eventHeight;
  @override
  double computeMaxIntrinsicHeight(final double width) =>
      _parallelEventCount() * eventHeight;

  final _yPositions = <E, int>{};

  @override
  void performLayout() {
    assert(!sizedByParent);

    if (children.isEmpty) {
      size = Size(constraints.maxWidth, 0);
      return;
    }

    _updateEventPositions();
    size = Size(constraints.maxWidth, _parallelEventCount() * eventHeight);
    _positionEvents();
  }

  void _updateEventPositions() {
    // Remove events outside the current viewport (with some buffer).
    _yPositions.removeWhere((final e, final _) {
      return e.start.page.floor() >= currentlyVisibleDates.end.page.ceil() ||
          e.end.page.ceil() <= currentlyVisibleDates.start.page;
    });

    // Remove old events.
    _yPositions.removeWhere((final e, final _) => !_events.contains(e));

    // Insert new events.
    final sortedEvents = _events
        .where((final it) => !_yPositions.containsKey(it))
        .sortedByStartLength();

    Iterable<E> eventsWithPosition(final int y) {
      return _yPositions.entries.where((final e) => e.value == y).map((final e) => e.key);
    }

    outer:
    for (final event in sortedEvents) {
      var y = 0;
      final interval = event.interval.dateInterval;
      while (true) {
        final intersectingEvents = eventsWithPosition(y);
        if (intersectingEvents
            .every((final e) => !e.interval.dateInterval.intersects(interval))) {
          _yPositions[event] = y;
          continue outer;
        }

        y++;
      }
    }
  }

  void _positionEvents() {
    final dateWidth = size.width / visibleRange.visibleDayCount;
    for (final child in children) {
      final data = child.data<E>();
      final event = data.event!;

      final dateInterval = event.interval.dateInterval;
      final startPage = dateInterval.start.page;
      final left = ((startPage - page) * dateWidth).coerceAtLeast(0);
      final endPage = dateInterval.end.page.ceilToDouble();
      final right = ((endPage - page) * dateWidth).coerceAtMost(size.width);

      child.layout(
        BoxConstraints(
          minWidth: right - left,
          maxWidth: (right - left).coerceAtLeast(dateWidth),
          minHeight: eventHeight,
          maxHeight: eventHeight,
        ),
        parentUsesSize: true,
      );
      final actualLeft = startPage >= page
          ? left
          : left.coerceAtMost(right - child.size.width);
      data.offset = Offset(actualLeft, _yPositions[event]! * eventHeight);
    }
  }

  double _parallelEventCount() {
    int parallelEventsFrom(final int page) {
      final startDate = DateTimeTimetable.dateFromPage(page);
      final interval = Interval(
        startDate,
        (startDate + (visibleRange.visibleDayCount - 1).days).atEndOfDay,
      );
      assert(interval.isValidTimetableDateInterval);

      final maxEventPosition = _yPositions.entries
          .where((final e) => e.key.interval.intersects(interval))
          .map((final e) => e.value)
          .max();
      return maxEventPosition != null ? maxEventPosition + 1 : 0;
    }

    _updateEventPositions();
    final oldParallelEvents = parallelEventsFrom(page.floor());
    final newParallelEvents = parallelEventsFrom(page.ceil());
    final t = page - page.floorToDouble();
    return lerpDouble(oldParallelEvents, newParallelEvents, t)!;
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(final PaintingContext context, final Offset offset) =>
      defaultPaint(context, offset);
}

extension _ParentData on RenderBox {
  _EventParentData<E> data<E extends Event>() =>
      parentData! as _EventParentData<E>;
}
