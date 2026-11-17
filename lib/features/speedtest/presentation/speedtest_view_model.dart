import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/platform/usage_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../data/speed_backends.dart';
import '../data/speed_test_engine.dart';
import '../data/speedtest_repository.dart';
import '../domain/speed_server.dart';
import '../domain/speed_test_record.dart';

class SpeedTestViewModel extends ChangeNotifier {
  final SpeedTestRepository repository;
  final SettingsStore settings;
  final UsageSource? usageSource;
  final SpeedTestEngine _engine = SpeedTestEngine();

  SpeedTestViewModel({
    required this.repository,
    required this.settings,
    this.usageSource,
  }) {
    _subscription = _engine.progressStream.listen(_onProgress);
  }

  StreamSubscription<SpeedTestProgress>? _subscription;

  SpeedTestProgress _progress = const SpeedTestProgress(phase: SpeedTestPhase.idle);
  SpeedTestProgress get progress => _progress;

  String _currentNetworkType = 'mobile';
  String get currentNetworkType => _currentNetworkType;

  List<SpeedTestRecord> _history = [];
  List<SpeedTestRecord> get history => _history;

  SpeedTestRecord? _latest;
  SpeedTestRecord? get latestRecord => _latest;

  Map<String, double> _serverLatencies = {};
  Map<String, double> get serverLatencies => _serverLatencies;
  bool _isProbingServers = false;
  bool get isProbingServers => _isProbingServers;

  bool get isRunning =>
      _progress.phase == SpeedTestPhase.pinging ||
      _progress.phase == SpeedTestPhase.downloading ||
      _progress.phase == SpeedTestPhase.uploading;

  SpeedServer get selectedServer => settings.selectedServer;
  SpeedTestMode get selectedMode => settings.testMode;

  Future<void> init() async {
    await loadHistory();
    await detectNetworkType();
  }

  Future<String> detectNetworkType() async {
    if (usageSource != null) {
      _currentNetworkType = await usageSource!.networkType();
      notifyListeners();
    }
    return _currentNetworkType;
  }

  Future<void> loadHistory() async {
    _history = await repository.getHistory();
    _latest = await repository.getLatest();
    notifyListeners();
  }

  void selectServer(SpeedServer server) {
    settings.selectedServer = server;
    notifyListeners();
  }

  void setTestMode(SpeedTestMode mode) {
    settings.testMode = mode;
    notifyListeners();
  }

  Future<void> probeAllServers() async {
    _isProbingServers = true;
    notifyListeners();

    final results = <String, double>{};
    for (final server in SpeedServers.candidatesForAuto) {
      final rtt = await ServerProber.pingServer(server);
      results[server.id] = rtt;
    }
    _serverLatencies = results;
    _isProbingServers = false;
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
    final serverName = p.server?.name ?? selectedServer.name;
    final record = SpeedTestRecord(
      ts: DateTime.now().millisecondsSinceEpoch,
      pingMs: p.pingMs,
      jitterMs: p.jitterMs,
      downMbps: p.downMbps,
      upMbps: p.upMbps,
      networkType: _currentNetworkType,
      server: serverName,
    );
    await repository.insertTest(record);
    await loadHistory();
  }

  Future<void> startTest({
    String? networkType,
    SpeedServer? server,
    SpeedTestMode? mode,
  }) async {
    if (isRunning) return;
    if (networkType != null) {
      _currentNetworkType = networkType;
    } else if (usageSource != null) {
      _currentNetworkType = await usageSource!.networkType();
    }
    final targetServer = server ?? selectedServer;
    final targetMode = mode ?? selectedMode;

    _progress = SpeedTestProgress(
      phase: SpeedTestPhase.pinging,
      server: targetServer,
      mode: targetMode,
    );
    notifyListeners();

    await _engine.runTest(server: targetServer, mode: targetMode);
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
