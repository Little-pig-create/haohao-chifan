import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 直接读取手机自带的计步传感器（TYPE_STEP_COUNTER）。
///
/// 传感器返回「开机以来」的累计步数，所以需要自己维护基线：
/// 跨天时用上一次的读数做基线，把两次打开 App 之间走的路也算进来；
/// 手机重启（读数变小）时则从当前值重新开始。
class StepSensor {
  static const _dateKey = 'haohao.step.date';
  static const _lastKey = 'haohao.step.last';
  static const _baseDateKey = 'haohao.step.baseline.date';
  static const _baseValueKey = 'haohao.step.baseline.value';

  StreamSubscription<StepCount>? _sub;
  int? _sinceBoot;
  int? _baseline;
  String? _baselineDate;
  String? _lastDate;
  int? _lastValue;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);
  bool running = false;
  String? error;

  int? get steps {
    final boot = _sinceBoot;
    final base = _baseline;
    if (boot == null || base == null) return null;
    final diff = boot - base;
    return diff < 0 ? 0 : diff;
  }

  static String _dayKey(DateTime time) =>
      '${time.year}-${time.month}-${time.day}';

  Future<void> start({required void Function(int steps) onUpdate}) async {
    if (running) return;
    running = true;
    final prefs = await SharedPreferences.getInstance();
    _baselineDate = prefs.getString(_baseDateKey);
    _baseline = prefs.getInt(_baseValueKey);
    _lastDate = prefs.getString(_dateKey);
    _lastValue = prefs.getInt(_lastKey);
    try {
      _sub = Pedometer.stepCountStream.listen(
        (event) {
          final today = _dayKey(DateTime.now());
          final now = DateTime.now();
          _sinceBoot = event.steps;
          final rebooted = _lastValue != null && event.steps < _lastValue!;
          var persistBaseline = false;
          if (_baseline == null || _baselineDate != today || rebooted) {
            // 跨天：把上一次读数当基线，补上两次打开之间走的路；
            // 首次使用或重启：从当前读数开始。
            final canCarryOver =
                _baselineDate != today &&
                !rebooted &&
                _lastDate != null &&
                _lastValue != null &&
                event.steps >= _lastValue!;
            _baseline = canCarryOver ? _lastValue! : event.steps;
            _baselineDate = today;
            persistBaseline = true;
          }
          _lastValue = event.steps;
          _lastDate = today;
          // 先把新步数推给界面，落盘放到后面异步做，避免磁盘写入拖慢刷新。
          final value = steps;
          if (value != null) onUpdate(value);
          if (persistBaseline) {
            unawaited(prefs.setString(_baseDateKey, today));
            unawaited(prefs.setInt(_baseValueKey, _baseline!));
          }
          if (now.difference(_lastWrite).inSeconds >= 5) {
            _lastWrite = now;
            unawaited(prefs.setString(_dateKey, today));
            unawaited(prefs.setInt(_lastKey, event.steps));
          }
        },
        onError: (Object e) {
          error = '$e';
          running = false;
        },
        cancelOnError: true,
      );
    } catch (e) {
      error = '$e';
      running = false;
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    running = false;
  }
}
