import 'package:flutter/widgets.dart' hide Interval;

import 'all_day.dart';
import 'event.dart';

typedef EventBuilder<E extends Event> = Widget Function(
  BuildContext context,
  E event,
);

class DefaultEventBuilder<E extends Event> extends InheritedWidget {
  DefaultEventBuilder({
    required this.builder,
    final AllDayEventBuilder<E>? allDayBuilder,
    required final Widget child,
  })  : allDayBuilder =
            allDayBuilder ?? ((final context, final event, final _) => builder(context, event)),
        super(child: child);

  final EventBuilder<E> builder;
  final AllDayEventBuilder<E> allDayBuilder;

  @override
  bool updateShouldNotify(final DefaultEventBuilder<E> oldWidget) =>
      builder != oldWidget.builder || allDayBuilder != oldWidget.allDayBuilder;

  static EventBuilder<E>? of<E extends Event>(final BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DefaultEventBuilder<E>>()
        ?.builder;
  }

  static AllDayEventBuilder<E>? allDayOf<E extends Event>(
    final BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<DefaultEventBuilder<E>>()
        ?.allDayBuilder;
  }
}
