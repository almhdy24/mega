import 'package:flutter/services.dart';

class LiveMonitorChannel {
  static const MethodChannel _channel = MethodChannel('dev.elmahdi.mega/live_monitor');

  static Future<bool> start() async {
    try {
      final res = await _channel.invokeMethod<bool>('start');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      final res = await _channel.invokeMethod<bool>('stop');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> apply() async {
    try {
      final res = await _channel.invokeMethod<bool>('apply');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isRunning() async {
    try {
      final res = await _channel.invokeMethod<bool>('isRunning');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } catch (_) {}
  }

  static Future<void> openAppDetailsSettings() async {
    try {
      await _channel.invokeMethod<void>('openAppDetailsSettings');
    } catch (_) {}
  }
}
