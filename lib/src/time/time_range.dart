import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../utils.dart';
import 'controller.dart';

/// The value held by [TimeController].
@immutable
class TimeRange {
  TimeRange(this.startTime, this.endTime)
      : assert(startTime.isValidTimetableTimeOfDay),
        assert(endTime.isValidTimetableTimeOfDay),
        assert(startTime <= endTime);
  factory TimeRange.fromStartAndDuration(
          final Duration startTime, final Duration duration) =>
      TimeRange(startTime, startTime + duration);

  factory TimeRange.centeredAround(
    final Duration center,
    final Duration duration, {
    final bool canShiftIfDoesntFit = true,
  }) {
    assert(duration <= 1.days);

    final halfDuration = duration * (1 / 2);
    if (center - halfDuration < 0.days) {
      assert(canShiftIfDoesntFit);
      return TimeRange(0.days, duration);
    } else if (center + halfDuration > 1.days) {
      assert(canShiftIfDoesntFit);
      return TimeRange(1.days - duration, 1.days);
    } else {
      return TimeRange(center - halfDuration, center + halfDuration);
    }
  }

  static final fullDay = TimeRange(0.days, 1.days);

  final Duration startTime;
  Duration get centerTime => startTime + duration * (1 / 2);
  final Duration endTime;
  Duration get duration => endTime - startTime;

  bool contains(final TimeRange other) =>
      startTime <= other.startTime && other.endTime <= endTime;

  // ignore: prefer_constructors_over_static_methods
  static TimeRange lerp(final TimeRange a, final TimeRange b, final double t) {
    return TimeRange(
      lerpDuration(a.startTime, b.startTime, t),
      lerpDuration(a.endTime, b.endTime, t),
    );
  }

  @override
  int get hashCode => hashValues(startTime, endTime);
  @override
  bool operator ==(final Object other) {
    return other is TimeRange &&
        startTime == other.startTime &&
        endTime == other.endTime;
  }

  @override
  String toString() => 'TimeRange(startTime = $startTime, endTime = $endTime)';
}
