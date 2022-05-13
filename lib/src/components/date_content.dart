import 'package:flutter/widgets.dart';

import '../callbacks.dart';
import '../event/event.dart';
import '../time/overlay.dart';
import '../utils.dart';
import 'date_events.dart';
import 'time_overlays.dart';

/// A widget that displays [Event]s and [TimeOverlay]s.
///
/// If [onBackgroundTap] is not supplied, [DefaultTimetableCallbacks]'s
/// `onDateTimeBackgroundTap` is used if it's provided above in the widget tree.
///
/// See also:
///
/// * [DateEvents] and [TimeOverlays], which are used to actually layout
///   [Event]s and [TimeOverlay]s. [DateEvents] can be styled.
/// * [DefaultTimetableCallbacks], which provides callbacks to descendant
///   Timetable widgets.
class DateContent<E extends Event> extends StatelessWidget {
  DateContent({
    final Key? key,
    required this.date,
    required final List<E> events,
    this.overlays = const [],
    this.onBackgroundTap,
  })  : assert(date.isValidTimetableDate),
        assert(
          events.every((final e) => e.interval.intersects(date.fullDayInterval)),
          'All events must intersect the given date',
        ),
        assert(
          events.toSet().length == events.length,
          'Events may not contain duplicates',
        ),
        events = events.sortedByStartLength(),
        super(key: key);

  final DateTime date;

  final List<E> events;
  final List<TimeOverlay> overlays;

  final DateTimeTapCallback? onBackgroundTap;

  @override
  Widget build(final BuildContext context) {
    final onBackgroundTap = this.onBackgroundTap ??
        DefaultTimetableCallbacks.of(context)?.onDateTimeBackgroundTap;

    return LayoutBuilder(builder: (final context, final constraints) {
      final height = constraints.maxHeight;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: onBackgroundTap != null
            ? (final details) =>
                onBackgroundTap(date + (details.localPosition.dy / height).days)
            : null,
        child: Stack(children: [
          _buildOverlaysForPosition(TimeOverlayPosition.behindEvents),
          DateEvents<E>(date: date, events: events),
          _buildOverlaysForPosition(TimeOverlayPosition.inFrontOfEvents),
        ]),
      );
    });
  }

  Widget _buildOverlaysForPosition(final TimeOverlayPosition position) {
    return Positioned.fill(
      child: TimeOverlays(
        overlays: overlays.where((final it) => it.position == position).toList(),
      ),
    );
  }
}
