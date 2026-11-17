import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import '../domain/speed_math.dart';

enum SpeedTestPhase {
  idle,
  pinging,
  downloading,
  uploading,
  completed,
  failed,
  cancelled,
}

class SpeedTestProgress {
  final SpeedTestPhase phase;
  final double currentMbps;
  final double pingMs;
  final double jitterMs;
  final double downMbps;
  final double upMbps;
  final double progressPercent; // 0.0 to 1.0
  final String? errorMessage;

  const SpeedTestProgress({
    required this.phase,
    this.currentMbps = 0.0,
    this.pingMs = 0.0,
    this.jitterMs = 0.0,
    this.downMbps = 0.0,
    this.upMbps = 0.0,
    this.progressPercent = 0.0,
    this.errorMessage,
  });

  SpeedTestProgress copyWith({
    SpeedTestPhase? phase,
    double? currentMbps,
    double? pingMs,
    double? jitterMs,
    double? downMbps,
    double? upMbps,
    double? progressPercent,
    String? errorMessage,
  }) {
    return SpeedTestProgress(
      phase: phase ?? this.phase,
      currentMbps: currentMbps ?? this.currentMbps,
      pingMs: pingMs ?? this.pingMs,
      jitterMs: jitterMs ?? this.jitterMs,
      downMbps: downMbps ?? this.downMbps,
      upMbps: upMbps ?? this.upMbps,
      progressPercent: progressPercent ?? this.progressPercent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SpeedTestEngine {
  HttpClient? _client;
  bool _isCancelled = false;

  final StreamController<SpeedTestProgress> _controller =
      StreamController<SpeedTestProgress>.broadcast();

  Stream<SpeedTestProgress> get progressStream => _controller.stream;

  void cancel() {
    _isCancelled = true;
    _closeClient();
    _controller.add(const SpeedTestProgress(phase: SpeedTestPhase.cancelled));
  }

  void _closeClient() {
    try {
      _client?.close(force: true);
    } catch (_) {}
    _client = null;
  }

  Future<SpeedTestProgress> runTest({
    required String baseUrl,
    String pingEndpoint = '/empty',
    String downloadEndpoint = '/garbage?ckSize=20',
    String uploadEndpoint = '/empty',
  }) async {
    _isCancelled = false;
    _closeClient();

    _client = HttpClient();
    _client!.connectionTimeout = const Duration(seconds: 8);
    _client!.idleTimeout = const Duration(seconds: 15);

    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    var progress = const SpeedTestProgress(
      phase: SpeedTestPhase.pinging,
      progressPercent: 0.05,
    );
    _controller.add(progress);

    try {
      // Auto-detect LibreSpeed PHP backends if /empty returns 404
      var effectivePing = pingEndpoint;
      var effectiveDown = downloadEndpoint;
      var effectiveUp = uploadEndpoint;

      var pingUrl = Uri.parse('$cleanBase$effectivePing');
      try {
        final probeReq = await _client!.getUrl(pingUrl);
        final probeRes = await probeReq.close();
        await probeRes.drain<void>();
        if (probeRes.statusCode == 404) {
          effectivePing = '/empty.php';
          effectiveDown = '/garbage.php?ckSize=20';
          effectiveUp = '/empty.php';
          pingUrl = Uri.parse('$cleanBase$effectivePing');
        }
      } catch (_) {}

      // 1. PING & JITTER
      // 10 sequential requests over ONE kept-alive connection, discard first
      final rtts = <double>[];

      for (var i = 0; i < 10; i++) {
        if (_isCancelled) return progress;
        final sw = Stopwatch()..start();
        final req = await _client!.getUrl(pingUrl);
        req.persistentConnection = true;
        final res = await req.close();
        await res.drain<void>();
        sw.stop();

        final rtt = sw.elapsedMicroseconds / 1000.0;
        if (i > 0) {
          // Discard first setup RTT
          rtts.add(rtt);
        }

        progress = progress.copyWith(
          progressPercent: 0.05 + (0.15 * (i + 1) / 10),
        );
        _controller.add(progress);
      }

      final finalPing = medianMs(rtts);
      final finalJitter = jitterMs(rtts);

      progress = progress.copyWith(
        phase: SpeedTestPhase.downloading,
        pingMs: finalPing,
        jitterMs: finalJitter,
        progressPercent: 0.2,
      );
      _controller.add(progress);

      // 2. DOWNLOAD TEST
      // 4 parallel streams, 10s cap, discard first 1.5s warm-up, sample every 200ms
      final downUrl = Uri.parse('$cleanBase$effectiveDown');
      final downMbps = await _runDownload(downUrl, progress);
      if (_isCancelled) return progress;

      progress = progress.copyWith(
        phase: SpeedTestPhase.uploading,
        downMbps: downMbps,
        progressPercent: 0.6,
      );
      _controller.add(progress);

      // 3. UPLOAD TEST
      // 3 parallel POST streams, 8s cap, same warm-up & 200ms sampling, reuse one pre-generated buffer
      final upUrl = Uri.parse('$cleanBase$effectiveUp');
      final upMbps = await _runUpload(upUrl, progress);
      if (_isCancelled) return progress;

      progress = progress.copyWith(
        phase: SpeedTestPhase.completed,
        upMbps: upMbps,
        currentMbps: 0.0,
        progressPercent: 1.0,
      );
      _controller.add(progress);
      return progress;
    } catch (e) {
      if (_isCancelled) {
        return const SpeedTestProgress(phase: SpeedTestPhase.cancelled);
      }
      progress = progress.copyWith(
        phase: SpeedTestPhase.failed,
        errorMessage: e.toString(),
      );
      _controller.add(progress);
      return progress;
    } finally {
      _closeClient();
    }
  }

  Future<double> _runDownload(Uri url, SpeedTestProgress currentProgress) async {
    const durationCap = Duration(seconds: 10);
    const warmUp = Duration(milliseconds: 1500);
    const sampleInterval = Duration(milliseconds: 200);

    var totalBytesTransferred = 0;
    var warmUpBytes = 0;
    final samples = <double>[];
    final sw = Stopwatch()..start();

    var warmUpPassed = false;
    var lastSampleTime = Duration.zero;
    var lastSampleBytes = 0;

    // Periodic sampling timer
    Timer? sampleTimer;
    sampleTimer = Timer.periodic(sampleInterval, (_) {
      if (_isCancelled || sw.elapsed >= durationCap) {
        sampleTimer?.cancel();
        return;
      }

      final elapsed = sw.elapsed;
      if (!warmUpPassed && elapsed >= warmUp) {
        warmUpPassed = true;
        warmUpBytes = totalBytesTransferred;
        lastSampleTime = elapsed;
        lastSampleBytes = totalBytesTransferred;
      } else if (warmUpPassed) {
        final deltaBytes = totalBytesTransferred - lastSampleBytes;
        final deltaTime = elapsed - lastSampleTime;
        if (deltaTime > Duration.zero) {
          final instantSpeed = mbps(deltaBytes, deltaTime);
          samples.add(instantSpeed);

          final progressRatio = 0.2 + (0.4 * (elapsed.inMilliseconds / durationCap.inMilliseconds));
          _controller.add(currentProgress.copyWith(
            currentMbps: instantSpeed,
            progressPercent: progressRatio.clamp(0.2, 0.6),
          ));
        }
        lastSampleTime = elapsed;
        lastSampleBytes = totalBytesTransferred;
      }
    });

    // 4 parallel download streams
    Future<void> downloadWorker() async {
      while (sw.elapsed < durationCap && !_isCancelled) {
        try {
          final req = await _client!.getUrl(url);
          final res = await req.close();
          await for (final chunk in res) {
            totalBytesTransferred += chunk.length;
            if (sw.elapsed >= durationCap || _isCancelled) {
              await res.drain<void>();
              break;
            }
          }
        } catch (_) {
          break;
        }
      }
    }

    await Future.wait([
      downloadWorker(),
      downloadWorker(),
      downloadWorker(),
      downloadWorker(),
    ]);

    sampleTimer.cancel();
    sw.stop();

    if (samples.isEmpty) {
      final totalValidBytes = max(0, totalBytesTransferred - warmUpBytes);
      final validDuration = sw.elapsed - warmUp;
      return mbps(totalValidBytes, validDuration > Duration.zero ? validDuration : sw.elapsed);
    }

    return trimmedMean(samples, trim: 0.1);
  }

  Future<double> _runUpload(Uri url, SpeedTestProgress currentProgress) async {
    const durationCap = Duration(seconds: 8);
    const warmUp = Duration(milliseconds: 1500);
    const sampleInterval = Duration(milliseconds: 200);

    // Reuse one pre-generated 256 KB chunk
    const chunkSize = 256 * 1024;
    final random = Random(42);
    final chunk = Uint8List(chunkSize);
    for (var i = 0; i < chunkSize; i++) {
      chunk[i] = random.nextInt(256);
    }

    var totalBytesUploaded = 0;
    var warmUpBytes = 0;
    final samples = <double>[];
    final sw = Stopwatch()..start();

    var warmUpPassed = false;
    var lastSampleTime = Duration.zero;
    var lastSampleBytes = 0;

    Timer? sampleTimer;
    sampleTimer = Timer.periodic(sampleInterval, (_) {
      if (_isCancelled || sw.elapsed >= durationCap) {
        sampleTimer?.cancel();
        return;
      }

      final elapsed = sw.elapsed;
      if (!warmUpPassed && elapsed >= warmUp) {
        warmUpPassed = true;
        warmUpBytes = totalBytesUploaded;
        lastSampleTime = elapsed;
        lastSampleBytes = totalBytesUploaded;
      } else if (warmUpPassed) {
        final deltaBytes = totalBytesUploaded - lastSampleBytes;
        final deltaTime = elapsed - lastSampleTime;
        if (deltaTime > Duration.zero) {
          final instantSpeed = mbps(deltaBytes, deltaTime);
          samples.add(instantSpeed);

          final progressRatio = 0.6 + (0.4 * (elapsed.inMilliseconds / durationCap.inMilliseconds));
          _controller.add(currentProgress.copyWith(
            currentMbps: instantSpeed,
            progressPercent: progressRatio.clamp(0.6, 1.0),
          ));
        }
        lastSampleTime = elapsed;
        lastSampleBytes = totalBytesUploaded;
      }
    });

    // Cap request body at 2.5 MB (10 chunks of 256 KB) to stay under PHP post_max_size
    const chunksPerRequest = 10;
    const bodySize = chunkSize * chunksPerRequest;

    // 3 parallel upload streams
    Future<void> uploadWorker() async {
      while (sw.elapsed < durationCap && !_isCancelled) {
        try {
          final req = await _client!.postUrl(url);
          req.headers.contentType = ContentType.binary;
          req.contentLength = bodySize;

          for (var i = 0; i < chunksPerRequest; i++) {
            if (_isCancelled) {
              req.abort();
              return;
            }
            req.add(chunk);
            await req.flush();
            totalBytesUploaded += chunkSize;
          }

          final res = await req.close();
          await res.drain<void>();
        } catch (_) {
          break;
        }
      }
    }

    await Future.wait([
      uploadWorker(),
      uploadWorker(),
      uploadWorker(),
    ]);

    sampleTimer.cancel();
    sw.stop();

    if (samples.isEmpty) {
      final totalValidBytes = max(0, totalBytesUploaded - warmUpBytes);
      final validDuration = sw.elapsed - warmUp;
      return mbps(totalValidBytes, validDuration > Duration.zero ? validDuration : sw.elapsed);
    }

    return trimmedMean(samples, trim: 0.1);
  }

  void dispose() {
    _closeClient();
    _controller.close();
  }
}
