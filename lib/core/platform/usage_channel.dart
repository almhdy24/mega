import 'package:flutter/services.dart';

class UsageTotals {
  final int mobileRx;
  final int mobileTx;
  final int wifiRx;
  final int wifiTx;
  final bool mobileSupported;

  const UsageTotals({
    required this.mobileRx,
    required this.mobileTx,
    required this.wifiRx,
    required this.wifiTx,
    this.mobileSupported = true,
  });

  const UsageTotals.zero({this.mobileSupported = true})
      : mobileRx = 0,
        mobileTx = 0,
        wifiRx = 0,
        wifiTx = 0;

  int get mobileTotal => mobileRx + mobileTx;
  int get wifiTotal => wifiRx + wifiTx;
  int get grandTotal => mobileTotal + wifiTotal;

  UsageTotals copyWith({
    int? mobileRx,
    int? mobileTx,
    int? wifiRx,
    int? wifiTx,
    bool? mobileSupported,
  }) {
    return UsageTotals(
      mobileRx: mobileRx ?? this.mobileRx,
      mobileTx: mobileTx ?? this.mobileTx,
      wifiRx: wifiRx ?? this.wifiRx,
      wifiTx: wifiTx ?? this.wifiTx,
      mobileSupported: mobileSupported ?? this.mobileSupported,
    );
  }

  UsageTotals operator +(UsageTotals other) {
    return UsageTotals(
      mobileRx: mobileRx + other.mobileRx,
      mobileTx: mobileTx + other.mobileTx,
      wifiRx: wifiRx + other.wifiRx,
      wifiTx: wifiTx + other.wifiTx,
      mobileSupported: mobileSupported && other.mobileSupported,
    );
  }
}

abstract class UsageSource {
  Future<bool> hasAccess();
  Future<void> openAccessSettings();
  Future<UsageTotals> queryRange(DateTime startLocal, DateTime endLocal);
  Future<void> scheduleAlertWorker();
  Future<void> cancelAlertWorker();
}

class PlatformUsageSource implements UsageSource {
  static const MethodChannel _channel = MethodChannel('dev.elmahdi.mega/usage');

  @override
  Future<bool> hasAccess() async {
    try {
      final res = await _channel.invokeMethod<bool>('hasUsageAccess');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } catch (_) {}
  }

  @override
  Future<UsageTotals> queryRange(DateTime startLocal, DateTime endLocal) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('queryRange', {
        'startMs': startLocal.millisecondsSinceEpoch,
        'endMs': endLocal.millisecondsSinceEpoch,
      });

      if (res == null) return const UsageTotals.zero();

      return UsageTotals(
        mobileRx: (res['mobileRx'] as num?)?.toInt() ?? 0,
        mobileTx: (res['mobileTx'] as num?)?.toInt() ?? 0,
        wifiRx: (res['wifiRx'] as num?)?.toInt() ?? 0,
        wifiTx: (res['wifiTx'] as num?)?.toInt() ?? 0,
        mobileSupported: (res['mobileSupported'] as bool?) ?? true,
      );
    } catch (_) {
      return const UsageTotals.zero();
    }
  }

  @override
  Future<void> scheduleAlertWorker() async {
    try {
      await _channel.invokeMethod<void>('scheduleAlertWorker');
    } catch (_) {}
  }

  @override
  Future<void> cancelAlertWorker() async {
    try {
      await _channel.invokeMethod<void>('cancelAlertWorker');
    } catch (_) {}
  }
}
