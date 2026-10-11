import 'package:flutter/widgets.dart';

class SessionLifecycleObserver extends WidgetsBindingObserver {
  SessionLifecycleObserver({
    required this.onBackground,
    required this.onForeground,
  });

  final VoidCallback onBackground;
  final VoidCallback onForeground;

  void start() => WidgetsBinding.instance.addObserver(this);

  void dispose() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      onBackground();
    } else if (state == AppLifecycleState.resumed) {
      onForeground();
    }
  }
}
