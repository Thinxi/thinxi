import 'dart:async';

class GameTimer {
  Duration duration;
  Timer? timer;
  Function onTick;
  Function onTimeUp;

  GameTimer(
      {required this.duration, required this.onTick, required this.onTimeUp});

  void start() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (duration.inSeconds > 0) {
        duration = Duration(seconds: duration.inSeconds - 1);
        onTick(duration);
      } else {
        timer?.cancel();
        onTimeUp();
      }
    });
  }

  void stop() {
    timer?.cancel();
  }
}
