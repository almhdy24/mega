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

enum UsageResultStatus {
  ok,
  denied,
  unsupported,
  error,
}

class UsageResult {
  final UsageResultStatus status;
  final UsageTotals totals;
  final String? message;

  const UsageResult({
    required this.status,
    this.totals = const UsageTotals.zero(),
    this.message,
  });

  const UsageResult.ok(this.totals)
      : status = UsageResultStatus.ok,
        message = null;

  const UsageResult.denied()
      : status = UsageResultStatus.denied,
        totals = const UsageTotals.zero(),
        message = null;

  const UsageResult.unsupported([this.totals = const UsageTotals.zero(mobileSupported: false)])
      : status = UsageResultStatus.unsupported,
        message = null;

  const UsageResult.error(this.message)
      : status = UsageResultStatus.error,
        totals = const UsageTotals.zero();
}

class AppUsageItem {
  final int uid;
  final String packageName;
  final String appName;
  final int mobileBytes;
  final int wifiBytes;

  const AppUsageItem({
    required this.uid,
    required this.packageName,
    required this.appName,
    required this.mobileBytes,
    required this.wifiBytes,
  });

  int get totalBytes => mobileBytes + wifiBytes;
}

abstract class UsageSource {
  Future<bool> hasAccess();
  Future<void> openAccessSettings();
  Future<UsageResult> queryRange(DateTime startLocal, DateTime endLocal);
  Future<List<AppUsageItem>> queryTopApps({
    required DateTime startLocal,
    required DateTime endLocal,
    int limit = 10,
  });
  Future<String> networkType();
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
    } catch (e) {
      throw PlatformException(code: 'SETTINGS_ERROR', message: e.toString());
    }
  }

  @override
  Future<String> networkType() async {
    try {
      final res = await _channel.invokeMethod<String>('networkType');
      return res ?? 'none';
    } catch (_) {
      return 'none';
    }
  }

  @override
  Future<UsageResult> queryRange(DateTime startLocal, DateTime endLocal) async {
    try {
      final access = await hasAccess();
      if (!access) {
        return const UsageResult.denied();
      }

      final res = await _channel.invokeMapMethod<String, dynamic>('queryRange', {
        'startMs': startLocal.millisecondsSinceEpoch,
        'endMs': endLocal.millisecondsSinceEpoch,
      });

      if (res == null) {
        return const UsageResult.error('استجابة فارغة من النظام');
      }

      final mobileSupported = (res['mobileSupported'] as bool?) ?? true;
      final totals = UsageTotals(
        mobileRx: (res['mobileRx'] as num?)?.toInt() ?? 0,
        mobileTx: (res['mobileTx'] as num?)?.toInt() ?? 0,
        wifiRx: (res['wifiRx'] as num?)?.toInt() ?? 0,
        wifiTx: (res['wifiTx'] as num?)?.toInt() ?? 0,
        mobileSupported: mobileSupported,
      );

      if (!mobileSupported) {
        return UsageResult.unsupported(totals);
      }

      return UsageResult.ok(totals);
    } on PlatformException catch (e) {
      return UsageResult.error(e.message ?? e.code);
    } catch (e) {
      return UsageResult.error(e.toString());
    }
  }

  @override
  Future<List<AppUsageItem>> queryTopApps({
    required DateTime startLocal,
    required DateTime endLocal,
    int limit = 10,
  }) async {
    try {
      final access = await hasAccess();
      if (!access) return [];

      final list = await _channel.invokeListMethod<Map<dynamic, dynamic>>('queryTopApps', {
        'startMs': startLocal.millisecondsSinceEpoch,
        'endMs': endLocal.millisecondsSinceEpoch,
        'limit': limit,
      });

      if (list == null) return [];

      return list.map((item) {
        final map = Map<String, dynamic>.from(item);
        return AppUsageItem(
          uid: (map['uid'] as num?)?.toInt() ?? 0,
          packageName: map['packageName']?.toString() ?? '',
          appName: map['appName']?.toString() ?? '',
          mobileBytes: (map['mobileBytes'] as num?)?.toInt() ?? 0,
          wifiBytes: (map['wifiBytes'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> scheduleAlertWorker() async {
    try {
      await _channel.invokeMethod<void>('scheduleAlertWorker');
    } catch (e) {
      throw PlatformException(code: 'WORKER_ERROR', message: e.toString());
    }
  }

  @override
  Future<void> cancelAlertWorker() async {
    try {
      await _channel.invokeMethod<void>('cancelAlertWorker');
    } catch (e) {
      throw PlatformException(code: 'WORKER_ERROR', message: e.toString());
    }
  }
}
