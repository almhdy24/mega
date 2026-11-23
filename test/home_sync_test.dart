import 'package:flutter_test/flutter_test.dart';
import 'package:mega/core/db/migrations.dart';
import 'package:mega/core/platform/usage_channel.dart';
import 'package:mega/core/prefs/settings_store.dart';
import 'package:mega/core/time/day_range.dart';
import 'package:mega/features/home/presentation/home_view_model.dart';
import 'package:mega/features/usage/data/usage_repository.dart';
import 'package:mega/features/usage/domain/past_bundle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockUsageSource implements UsageSource {
  bool accessGranted = true;
  bool shouldFailQuery = false;
  int queryCallCount = 0;
  final Map<String, UsageTotals> dayData = {};

  @override
  Future<bool> hasAccess() async => accessGranted;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> scheduleAlertWorker() async {}

  @override
  Future<void> cancelAlertWorker() async {}

  @override
  Future<String> networkType() async => 'mobile';

  @override
  Future<List<AppUsageItem>> queryTopApps({
    required DateTime startLocal,
    required DateTime endLocal,
    int limit = 10,
  }) async => [];

  @override
  Future<UsageResult> queryRange(DateTime startLocal, DateTime endLocal) async {
    queryCallCount++;
    if (shouldFailQuery) {
      return const UsageResult.error('Temporary platform failure');
    }
    final dayKey = DayRange.formatDay(startLocal);
    final totals = dayData[dayKey] ?? const UsageTotals.zero();
    if (!totals.mobileSupported) {
      return UsageResult.unsupported(totals);
    }
    return UsageResult.ok(totals);
  }
}

class FailingUsageRepository extends UsageRepository {
  FailingUsageRepository({required super.db, required super.usageSource});

  @override
  Future<void> savePastBundle(PastBundle bundle) async {
    throw Exception('Simulated database failure during bundle archival');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late MockUsageSource mockSource;
  late UsageRepository usageRepository;
  late SettingsStore settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsStore(prefs);

    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    for (final migration in migrations) {
      await migration(db);
    }

    mockSource = MockUsageSource();
    usageRepository = UsageRepository(db: db, usageSource: mockSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('Home Usage Synchronization & Integrity', () {
    test('HomeViewModel initializes and populates fresh usage from empty DB without visiting Usage tab', () async {
      final now = DateTime.now();
      final dayKey = DayRange.formatDay(now);

      // System has 500 MB mobile usage today
      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 300 * 1024 * 1024,
        mobileTx: 200 * 1024 * 1024,
        wifiRx: 100 * 1024 * 1024,
        wifiTx: 50 * 1024 * 1024,
      );

      // Configure a 10 GB bundle
      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = now.subtract(const Duration(days: 2)).millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // Ensure database is initially empty
      expect(await usageRepository.isUsageEmpty(), isTrue);
      expect(vm.todayMobileBytes, 0);

      // Refresh Home directly
      await vm.refresh();

      // Home should now have synchronized and read the fresh usage directly
      expect(vm.todayMobileBytes, 500 * 1024 * 1024);
      expect(vm.todayWifiBytes, 150 * 1024 * 1024);
      expect(vm.usedMobileBytes, 500 * 1024 * 1024);
      expect(vm.hasAccess, isTrue);
      expect(vm.isLoading, isFalse);

      // Remaining bundle should have decreased accurately (10 GB - 500 MB)
      expect(vm.remainingBytes, (10 * 1024 * 1024 * 1024) - (500 * 1024 * 1024));

      // Database is no longer empty
      expect(await usageRepository.isUsageEmpty(), isFalse);
    });

    test('Existing snapshots survive failed synchronization without being overwritten by zeros', () async {
      final now = DateTime.now();
      final dayKey = DayRange.formatDay(now);

      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 400 * 1024 * 1024,
        mobileTx: 100 * 1024 * 1024,
        wifiRx: 50 * 1024 * 1024,
        wifiTx: 20 * 1024 * 1024,
      );

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // Initial successful sync
      await vm.refresh();
      expect(vm.todayMobileBytes, 500 * 1024 * 1024);

      // Simulate a subsequent query failure (e.g. system timeout or platform exception)
      mockSource.shouldFailQuery = true;
      await vm.refresh();

      // Valid cached data must survive and not be zeroed out
      expect(vm.todayMobileBytes, 500 * 1024 * 1024);
    });

    test('Concurrent synchronization requests are deduplicated without crashing', () async {
      final now = DateTime.now();
      final dayKey = DayRange.formatDay(now);

      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 1000,
        mobileTx: 500,
        wifiRx: 2000,
        wifiTx: 1000,
      );

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // Trigger multiple simultaneous refreshes
      await Future.wait([
        vm.refresh(),
        vm.refresh(),
        usageRepository.syncAdaptive(lastFullSyncMs: settings.lastFullSyncMs),
      ]);

      expect(vm.todayMobileBytes, 1500);
      expect(vm.isLoading, isFalse);
    });

    test('Wi-Fi traffic does not count towards mobile bundle usage', () async {
      final now = DateTime.now();
      final dayKey = DayRange.formatDay(now);

      // 0 B mobile, 5 GB Wi-Fi
      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 0,
        mobileTx: 0,
        wifiRx: 4 * 1024 * 1024 * 1024,
        wifiTx: 1 * 1024 * 1024 * 1024,
      );

      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      await vm.refresh();

      expect(vm.todayMobileBytes, 0);
      expect(vm.todayWifiBytes, 5 * 1024 * 1024 * 1024);
      expect(vm.usedMobileBytes, 0);
      // Bundle remains completely untouched by Wi-Fi
      expect(vm.remainingBytes, 10 * 1024 * 1024 * 1024);
    });

    test('Permission denied is handled gracefully and does not wipe local state', () async {
      mockSource.accessGranted = false;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      await vm.refresh();

      expect(vm.hasAccess, isFalse);
      expect(vm.todayMobileBytes, 0);
      expect(vm.isLoading, isFalse);
    });

    test('Completed bundle archives actual previous-period mobile usage with Wi-Fi excluded', () async {
      final now = DateTime.now();
      // Bundle started 35 days ago with 30-day validity
      final start35dAgo = now.subtract(const Duration(days: 35));
      final rollover30dAgo = start35dAgo.add(const Duration(days: 30)); // 5 days ago

      // Populate usage during completed period (e.g. 20 days ago)
      final pastDay = DayRange.formatDay(now.subtract(const Duration(days: 20)));
      mockSource.dayData[pastDay] = const UsageTotals(
        mobileRx: 1500 * 1024 * 1024,
        mobileTx: 500 * 1024 * 1024, // 2000 MB mobile
        wifiRx: 3000 * 1024 * 1024,
        wifiTx: 1000 * 1024 * 1024, // 4000 MB wifi
      );

      // Populate usage in the new active period (today)
      final todayKey = DayRange.formatDay(now);
      mockSource.dayData[todayKey] = const UsageTotals(
        mobileRx: 300 * 1024 * 1024,
        mobileTx: 100 * 1024 * 1024, // 400 MB mobile
        wifiRx: 500 * 1024 * 1024,
        wifiTx: 200 * 1024 * 1024,
      );

      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = start35dAgo.millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;
      settings.bundleAutoRenew = true;
      settings.bundleId = 1;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      await vm.refresh();

      // Settings advanced to the new period
      expect(settings.bundleStartMs, rollover30dAgo.millisecondsSinceEpoch);
      expect(settings.bundleId, 2);

      // Active period usage is only today's usage (400 MB), not including the completed period
      expect(vm.usedMobileBytes, 400 * 1024 * 1024);

      // Past bundle archived with exact previous period boundaries and Wi-Fi excluded
      final pastBundles = await usageRepository.getPastBundles();
      expect(pastBundles.length, 1);
      final archived = pastBundles.first;
      expect(archived.id, 1);
      expect(archived.startMs, start35dAgo.millisecondsSinceEpoch);
      expect(archived.endMs, rollover30dAgo.millisecondsSinceEpoch);
      expect(archived.sizeBytes, 10 * 1024 * 1024 * 1024);
      // Exactly 2000 MB mobile, 0 Wi-Fi
      expect(archived.usedBytes, 2000 * 1024 * 1024);
    });

    test('Extended offline: multiple missed bundle cycles archive each period separately', () async {
      final now = DateTime.now();
      // Started 70 days ago with 30-day validity:
      // Period 1: -70d to -40d
      // Period 2: -40d to -10d
      // Active Period: -10d to +20d
      final start70dAgo = now.subtract(const Duration(days: 70));
      final endPeriod1 = start70dAgo.add(const Duration(days: 30));
      final endPeriod2 = endPeriod1.add(const Duration(days: 30));

      // Pre-existing recorded usage in database for Period 1 (-50d)
      final p1Day = DayRange.formatDay(now.subtract(const Duration(days: 50)));
      await db.insert('usage_daily', {
        'day': p1Day,
        'mobile_rx': 1000 * 1024 * 1024,
        'mobile_tx': 500 * 1024 * 1024, // 1500 MB
        'wifi_rx': 9999,
        'wifi_tx': 9999,
        'updated_at': now.millisecondsSinceEpoch,
      });

      // Usage in Period 2 (-25d)
      final p2Day = DayRange.formatDay(now.subtract(const Duration(days: 25)));
      mockSource.dayData[p2Day] = const UsageTotals(
        mobileRx: 2000 * 1024 * 1024,
        mobileTx: 500 * 1024 * 1024, // 2500 MB
        wifiRx: 8888,
        wifiTx: 8888,
      );

      // Usage in active period (today)
      final todayKey = DayRange.formatDay(now);
      mockSource.dayData[todayKey] = const UsageTotals(
        mobileRx: 150 * 1024 * 1024,
        mobileTx: 50 * 1024 * 1024, // 200 MB
        wifiRx: 7777,
        wifiTx: 7777,
      );

      settings.bundleBytes = 5 * 1024 * 1024 * 1024;
      settings.bundleStartMs = start70dAgo.millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;
      settings.bundleAutoRenew = true;
      settings.bundleId = 10;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      await vm.refresh();

      // Active start advanced past both completed cycles to endPeriod2 (-10d)
      expect(settings.bundleStartMs, endPeriod2.millisecondsSinceEpoch);
      expect(settings.bundleId, 12);
      expect(vm.usedMobileBytes, 200 * 1024 * 1024);

      // Both periods archived separately ordered by end_ms DESC
      final pastBundles = await usageRepository.getPastBundles();
      expect(pastBundles.length, 2);

      // Most recent first: Period 2
      expect(pastBundles[0].id, 11);
      expect(pastBundles[0].startMs, endPeriod1.millisecondsSinceEpoch);
      expect(pastBundles[0].endMs, endPeriod2.millisecondsSinceEpoch);
      expect(pastBundles[0].usedBytes, 2500 * 1024 * 1024);

      // Earlier period: Period 1
      expect(pastBundles[1].id, 10);
      expect(pastBundles[1].startMs, start70dAgo.millisecondsSinceEpoch);
      expect(pastBundles[1].endMs, endPeriod1.millisecondsSinceEpoch);
      expect(pastBundles[1].usedBytes, 1500 * 1024 * 1024);
    });

    test('Repeated refreshes do not duplicate bundle archives', () async {
      final now = DateTime.now();
      final start35dAgo = now.subtract(const Duration(days: 35));

      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = start35dAgo.millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;
      settings.bundleAutoRenew = true;
      settings.bundleId = 1;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // First refresh executes rollover
      await vm.refresh();
      final initialBundles = await usageRepository.getPastBundles();
      expect(initialBundles.length, 1);
      expect(settings.bundleId, 2);

      // Repeated refresh must not archive again
      await vm.refresh();
      await vm.refresh();
      final subsequentBundles = await usageRepository.getPastBundles();
      expect(subsequentBundles.length, 1);
      expect(settings.bundleId, 2);
    });

    test('Manual renewBundleNow archives current period usage accurately', () async {
      final now = DateTime.now();
      final start5dAgo = now.subtract(const Duration(days: 5));

      final todayKey = DayRange.formatDay(now);
      mockSource.dayData[todayKey] = const UsageTotals(
        mobileRx: 800 * 1024 * 1024,
        mobileTx: 200 * 1024 * 1024, // 1000 MB
        wifiRx: 5000,
        wifiTx: 5000,
      );

      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = start5dAgo.millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;
      settings.bundleAutoRenew = true;
      settings.bundleId = 5;

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // Initial refresh to sync usage
      await vm.refresh();

      // User manually renews with 20 GB
      await vm.renewBundleNow(newBytes: 20 * 1024 * 1024 * 1024);

      final pastBundles = await usageRepository.getPastBundles();
      expect(pastBundles.length, 1);
      expect(pastBundles.first.id, 5);
      expect(pastBundles.first.usedBytes, 1000 * 1024 * 1024);
      expect(pastBundles.first.sizeBytes, 10 * 1024 * 1024 * 1024);

      // New bundle state active
      expect(settings.bundleId, 6);
      expect(settings.bundleBytes, 20 * 1024 * 1024 * 1024);
      expect(vm.totalBundleBytes, 20 * 1024 * 1024 * 1024);
    });

    test('Concurrent refresh calls queue follow-up without dropping state updates', () async {
      final now = DateTime.now();
      final dayKey = DayRange.formatDay(now);

      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 100,
        mobileTx: 100,
        wifiRx: 0,
        wifiTx: 0,
      );

      final vm = HomeViewModel(
        usageRepository: usageRepository,
        settings: settings,
        usageSource: mockSource,
      );

      // Start initial refresh
      final f1 = vm.refresh();

      // Mutate mock source and trigger second refresh while f1 is still active
      mockSource.dayData[dayKey] = const UsageTotals(
        mobileRx: 500,
        mobileTx: 500,
        wifiRx: 0,
        wifiTx: 0,
      );
      final f2 = vm.refresh();

      await Future.wait([f1, f2]);

      // Both completed, and f2 ran to incorporate the latest data
      expect(vm.isLoading, isFalse);
      expect(vm.todayMobileBytes, 1000);
    });

    test('Archival failure does not advance bundle start or bundleId', () async {
      final now = DateTime.now();
      final start35dAgo = now.subtract(const Duration(days: 35));

      settings.bundleBytes = 10 * 1024 * 1024 * 1024;
      settings.bundleStartMs = start35dAgo.millisecondsSinceEpoch;
      settings.bundleValidityDays = 30;
      settings.bundleAutoRenew = true;
      settings.bundleId = 5;

      final failingRepo = FailingUsageRepository(db: db, usageSource: mockSource);
      final vm = HomeViewModel(
        usageRepository: failingRepo,
        settings: settings,
        usageSource: mockSource,
      );

      await vm.refresh();

      // On failure, sync status reflects error
      expect(vm.syncStatus, UsageResultStatus.error);
      // Settings must NOT have advanced or been corrupted
      expect(settings.bundleStartMs, start35dAgo.millisecondsSinceEpoch);
      expect(settings.bundleId, 5);
      // No past bundles stored
      final past = await usageRepository.getPastBundles();
      expect(past, isEmpty);
    });

    test('Chart label collision logic suppresses day 28 collision on 30-day view', () {
      bool shouldDrawLabel(int i, int count) {
        final isBoundary = (i == 0 || i == count - 1);
        final isInterval = (i % 7 == 0 && i >= 4 && (count - 1 - i) >= 4);
        return isBoundary || isInterval;
      }

      // 30-day view (indices 0..29)
      final drawn30 = <int>[];
      for (var i = 0; i < 30; i++) {
        if (shouldDrawLabel(i, 30)) drawn30.add(i);
      }
      // Index 28 is suppressed because (29 - 28) = 1 < 4
      expect(drawn30, [0, 7, 14, 21, 29]);
      expect(drawn30.contains(28), isFalse);

      // 7-day view (indices 0..6)
      final drawn7 = <int>[];
      for (var i = 0; i < 7; i++) {
        if (shouldDrawLabel(i, 7)) drawn7.add(i);
      }
      expect(drawn7, [0, 6]);
    });
  });
}
