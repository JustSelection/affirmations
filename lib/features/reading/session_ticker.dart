import 'dart:async';

class SessionTicker {
  Timer? _timer;

  void start(void Function() onTick) {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
