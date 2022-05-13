import 'package:flutter/material.dart';

import 'callbacks.dart';
import 'date/controller.dart';
import 'event/all_day.dart';
import 'event/builder.dart';
import 'event/event.dart';
import 'event/provider.dart';
import 'theme.dart';
import 'time/controller.dart';
import 'time/overlay.dart';

class TimetableConfig<E extends Event> extends StatefulWidget {
  TimetableConfig({
    final Key? key,
    this.dateController,
    this.timeController,
    final EventProvider<E>? eventProvider,
    this.eventBuilder,
    this.allDayEventBuilder,
    this.timeOverlayProvider,
    this.callbacks,
    this.theme,
    required this.child,
  })  : eventProvider = eventProvider?.debugChecked,
        super(key: key);

  final DateController? dateController;
  final TimeController? timeController;
  final EventProvider<E>? eventProvider;
  final EventBuilder<E>? eventBuilder;
  final AllDayEventBuilder<E>? allDayEventBuilder;
  final TimeOverlayProvider? timeOverlayProvider;
  final TimetableCallbacks? callbacks;
  final TimetableThemeData? theme;
  final Widget child;

  @override
  _TimetableConfigState<E> createState() => _TimetableConfigState<E>();
}

class _TimetableConfigState<E extends Event> extends State<TimetableConfig<E>> {
  late final _dateController = DateController();
  late final _timeController = TimeController();

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    Widget child = DefaultTimetableCallbacks(
      callbacks: widget.callbacks ??
          DefaultTimetableCallbacks.of(context) ??
          TimetableCallbacks(),
      child: TimetableTheme(
        data: widget.theme ??
            TimetableTheme.of(context) ??
            TimetableThemeData(context),
        child: widget.child,
      ),
    );

    child = DefaultTimeOverlayProvider(
      overlayProvider: widget.timeOverlayProvider ??
          DefaultTimeOverlayProvider.of(context) ??
          emptyTimeOverlayProvider,
      child: child,
    );

    child = DefaultEventProvider<E>(
      eventProvider: widget.eventProvider ??
          DefaultEventProvider.of<E>(context) ??
          (final _) => [],
      child: DefaultEventBuilder(
        builder: widget.eventBuilder ?? DefaultEventBuilder.of<E>(context)!,
        allDayBuilder: widget.allDayEventBuilder,
        child: child,
      ),
    );

    return DefaultDateController(
      controller: widget.dateController ??
          DefaultDateController.of(context) ??
          _dateController,
      child: DefaultTimeController(
        controller: widget.timeController ??
            DefaultTimeController.of(context) ??
            _timeController,
        child: child,
      ),
    );
  }
}
