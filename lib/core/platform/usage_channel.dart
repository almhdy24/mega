import 'package:flutter/services.dart';

class UsageTotals {
  final int mobileRx;
  final int mobileTx;
  final int wifiRx;
  final int wifiTx;

  const UsageTotals({
    required this.mobileRx,
    required this.mobileTx,
    required this.wifiRx,
    required this.wifiTx,
  });

  const UsageTotals.zero()
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
  }) {
    return UsageTotals(
      mobileRx: mobileRx ?? this.mobileRx,
      mobileTx: mobileTx ?? this.mobileTx,
      wifiRx: wifiRx ?? this.wifiRx,
      wifiTx: wifiTx ?? this.wifiTx,
    );
  }

  UsageTotals operator +(UsageTotals other) {
    return UsageTotals(
      mobileRx: mobileRx + other.mobileRx,
      mobileTx: mobileTx + other.mobileTx,
      wifiRx: wifiRx + other.wifiRx,
      wifiTx: wifiTx + other.wifiTx,
    );
  }
}

abstract class UsageSource {
  Future<bool> hasAccess();
  Future<void> openAccessSettings();
  Future<UsageTotals> queryRange(DateTime startLocal, DateTime endLocal);
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
      );
    } catch (_) {
      return const UsageTotals.zero();
    }
  }
}
