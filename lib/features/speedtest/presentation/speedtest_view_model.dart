import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/prefs/settings_store.dart';
import '../data/speed_test_engine.dart';
import '../data/speedtest_repository.dart';
import '../domain/speed_test_record.dart';

class SpeedTestViewModel extends ChangeNotifier {
  final SpeedTestRepository repository;
  final SettingsStore settings;
  final SpeedTestEngine _engine = SpeedTestEngine();

  SpeedTestViewModel({
    required this.repository,
    required this.settings,
  }) {
    _subscription = _engine.progressStream.listen(_onProgress);
  }

  StreamSubscription<SpeedTestProgress>? _subscription;

  SpeedTestProgress _progress = const SpeedTestProgress(phase: SpeedTestPhase.idle);
  SpeedTestProgress get progress => _progress;

  List<SpeedTestRecord> _history = [];
  List<SpeedTestRecord> get history => _history;

  SpeedTestRecord? _latest;
  SpeedTestRecord? get latestRecord => _latest;

  bool get isRunning =>
      _progress.phase == SpeedTestPhase.pinging ||
      _progress.phase == SpeedTestPhase.downloading ||
      _progress.phase == SpeedTestPhase.uploading;

  Future<void> init() async {
    await loadHistory();
  }

  Future<void> loadHistory() async {
    _history = await repository.getHistory();
    _latest = await repository.getLatest();
    notifyListeners();
  }

  void _onProgress(SpeedTestProgress p) {
    _progress = p;
    notifyListeners();

    if (p.phase == SpeedTestPhase.completed) {
      _saveRecord(p);
    }
  }

  Future<void> _saveRecord(SpeedTestProgress p) async {
    final record = SpeedTestRecord(
      ts: DateTime.now().millisecondsSinceEpoch,
      pingMs: p.pingMs,
      jitterMs: p.jitterMs,
      downMbps: p.downMbps,
      upMbps: p.upMbps,
      networkType: 'mobile', // Saved with active network context
      server: settings.testBaseUrl,
    );
    await repository.insertTest(record);
    await loadHistory();
  }

  Future<void> startTest({String networkType = 'mobile'}) async {
    if (isRunning) return;
    _progress = const SpeedTestProgress(phase: SpeedTestPhase.pinging);
    notifyListeners();

    await _engine.runTest(baseUrl: settings.testBaseUrl);
  }

  void cancelTest() {
    _engine.cancel();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
