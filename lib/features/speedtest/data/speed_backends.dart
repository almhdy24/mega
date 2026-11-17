import 'dart:async';
import 'dart:io';
import '../domain/speed_server.dart';

abstract class SpeedBackend {
  Future<Uri> getPingUri(Uri base);
  Future<Uri> getDownloadUri(Uri base, {required int ckSize});
  Future<Uri> getUploadUri(Uri base);

  static SpeedBackend forProtocol(SpeedBackendProtocol protocol) {
    switch (protocol) {
      case SpeedBackendProtocol.mega:
        return const MegaBackend();
      case SpeedBackendProtocol.cloudflare:
        return const CloudflareBackend();
      case SpeedBackendProtocol.librespeed:
        return const LibreSpeedBackend();
      case SpeedBackendProtocol.custom:
        return const CustomBackend();
    }
  }
}

class MegaBackend implements SpeedBackend {
  const MegaBackend();

  @override
  Future<Uri> getPingUri(Uri base) async {
    final query = Map<String, String>.from(base.queryParameters);
    query['op'] = 'empty';
    return base.replace(queryParameters: query);
  }

  @override
  Future<Uri> getDownloadUri(Uri base, {required int ckSize}) async {
    final query = Map<String, String>.from(base.queryParameters);
    query['op'] = 'garbage';
    query['ckSize'] = ckSize.toString();
    return base.replace(queryParameters: query);
  }

  @override
  Future<Uri> getUploadUri(Uri base) async {
    final query = Map<String, String>.from(base.queryParameters);
    query['op'] = 'empty';
    return base.replace(queryParameters: query);
  }
}

class CloudflareBackend implements SpeedBackend {
  const CloudflareBackend();

  @override
  Future<Uri> getPingUri(Uri base) async {
    return _resolve(base, '/__down?bytes=0');
  }

  @override
  Future<Uri> getDownloadUri(Uri base, {required int ckSize}) async {
    // ckSize * 1 MB or 2.5 MB
    final bytes = (ckSize * 1024 * 1024).clamp(1024 * 1024, 25 * 1024 * 1024);
    return _resolve(base, '/__down?bytes=$bytes');
  }

  @override
  Future<Uri> getUploadUri(Uri base) async {
    return _resolve(base, '/__up');
  }

  Uri _resolve(Uri base, String path) {
    final cleanBase = base.toString().endsWith('/')
        ? base.toString().substring(0, base.toString().length - 1)
        : base.toString();
    return Uri.parse('$cleanBase$path');
  }
}

class LibreSpeedBackend implements SpeedBackend {
  const LibreSpeedBackend();

  @override
  Future<Uri> getPingUri(Uri base) async {
    return _resolve(base, '/empty');
  }

  @override
  Future<Uri> getDownloadUri(Uri base, {required int ckSize}) async {
    return _resolve(base, '/garbage?ckSize=$ckSize');
  }

  @override
  Future<Uri> getUploadUri(Uri base) async {
    return _resolve(base, '/empty');
  }

  Uri _resolve(Uri base, String path) {
    final cleanBase = base.toString().endsWith('/')
        ? base.toString().substring(0, base.toString().length - 1)
        : base.toString();
    return Uri.parse('$cleanBase$path');
  }
}

class CustomBackend implements SpeedBackend {
  const CustomBackend();

  @override
  Future<Uri> getPingUri(Uri base) async {
    final path = base.path;
    if (path.endsWith('.php')) {
      final query = Map<String, String>.from(base.queryParameters);
      query['op'] = 'empty';
      return base.replace(queryParameters: query);
    }
    final cleanBase = base.toString().endsWith('/')
        ? base.toString().substring(0, base.toString().length - 1)
        : base.toString();
    return Uri.parse('$cleanBase/empty');
  }

  @override
  Future<Uri> getDownloadUri(Uri base, {required int ckSize}) async {
    final path = base.path;
    if (path.endsWith('.php')) {
      final query = Map<String, String>.from(base.queryParameters);
      query['op'] = 'garbage';
      query['ckSize'] = ckSize.toString();
      return base.replace(queryParameters: query);
    }
    final cleanBase = base.toString().endsWith('/')
        ? base.toString().substring(0, base.toString().length - 1)
        : base.toString();
    return Uri.parse('$cleanBase/garbage?ckSize=$ckSize');
  }

  @override
  Future<Uri> getUploadUri(Uri base) async {
    final path = base.path;
    if (path.endsWith('.php')) {
      final query = Map<String, String>.from(base.queryParameters);
      query['op'] = 'empty';
      return base.replace(queryParameters: query);
    }
    final cleanBase = base.toString().endsWith('/')
        ? base.toString().substring(0, base.toString().length - 1)
        : base.toString();
    return Uri.parse('$cleanBase/empty');
  }
}

/// Helper to probe servers and find the fastest one.
class ServerProber {
  static Future<double> pingServer(SpeedServer server, {Duration timeout = const Duration(seconds: 3)}) async {
    if (server.id == 'auto' || server.baseUrl.isEmpty) return double.infinity;
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final backend = SpeedBackend.forProtocol(server.protocol);
      final pingUri = await backend.getPingUri(Uri.parse(server.baseUrl));
      final sw = Stopwatch()..start();
      final req = await client.getUrl(pingUri).timeout(timeout);
      final res = await req.close().timeout(timeout);
      await res.drain<void>().timeout(timeout);
      sw.stop();
      if (res.statusCode >= 200 && res.statusCode < 400) {
        return sw.elapsedMicroseconds / 1000.0;
      }
      return double.infinity;
    } catch (_) {
      return double.infinity;
    } finally {
      client.close(force: true);
    }
  }

  static Future<SpeedServer> autoSelectBestServer({
    List<SpeedServer> candidates = SpeedServers.candidatesForAuto,
  }) async {
    final results = await Future.wait(
      candidates.map((s) async {
        final rtt = await pingServer(s);
        return MapEntry(s, rtt);
      }),
    );

    SpeedServer? bestServer;
    double minRtt = double.infinity;

    for (final entry in results) {
      if (entry.value < minRtt) {
        minRtt = entry.value;
        bestServer = entry.key;
      }
    }

    return bestServer ?? SpeedServers.megaServer;
  }
}
