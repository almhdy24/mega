import 'package:flutter_test/flutter_test.dart';
import 'package:mega/features/speedtest/data/speed_backends.dart';
import 'package:mega/features/speedtest/domain/speed_math.dart';
import 'package:mega/features/speedtest/domain/speed_server.dart';

void main() {
  group('Speed Server Domain & Backends', () {
    test('SpeedServers.verifiedList contains auto and verified backends', () {
      expect(SpeedServers.verifiedList.isNotEmpty, isTrue);
      expect(SpeedServers.verifiedList.any((s) => s.id == 'auto'), isTrue);
      expect(SpeedServers.verifiedList.any((s) => s.id == 'mega-sd'), isTrue);
      expect(SpeedServers.verifiedList.any((s) => s.id == 'cloudflare'), isTrue);
    });

    test('SpeedServers.findById returns correct server or custom fallback', () {
      final mega = SpeedServers.findById('mega-sd');
      expect(mega.protocol, SpeedBackendProtocol.mega);
      expect(mega.baseUrl, contains('almhdy24.com'));

      final custom = SpeedServers.findById('custom', customUrl: 'https://test.local/backend');
      expect(custom.protocol, SpeedBackendProtocol.custom);
      expect(custom.baseUrl, 'https://test.local/backend');
    });

    test('stabilityRating categorizes jitter accurately', () {
      expect(stabilityRating(0), SpeedStability.excellent);
      expect(stabilityRating(10.5), SpeedStability.excellent);
      expect(stabilityRating(15.0), SpeedStability.good);
      expect(stabilityRating(45.0), SpeedStability.good);
      expect(stabilityRating(50.0), SpeedStability.good);
      expect(stabilityRating(50.1), SpeedStability.unstable);
      expect(stabilityRating(120.0), SpeedStability.unstable);
    });

    test('estimateDataUsage formats quick and full modes in ar and en', () {
      expect(estimateDataUsage(SpeedTestMode.quick, true), contains('3–8'));
      expect(estimateDataUsage(SpeedTestMode.quick, false), contains('3–8 MB'));
      expect(estimateDataUsage(SpeedTestMode.full, true), contains('15–25'));
      expect(estimateDataUsage(SpeedTestMode.full, false), contains('15–25 MB'));
    });

    test('MegaBackend builds correct URIs for empty and garbage', () async {
      const backend = MegaBackend();
      final base = Uri.parse('https://almhdy24.com/mega/speedtest.php');

      final ping = await backend.getPingUri(base);
      expect(ping.queryParameters['op'], 'empty');

      final down = await backend.getDownloadUri(base, ckSize: 4);
      expect(down.queryParameters['op'], 'garbage');
      expect(down.queryParameters['ckSize'], '4');

      final up = await backend.getUploadUri(base);
      expect(up.queryParameters['op'], 'empty');
    });

    test('CloudflareBackend builds correct down and up URIs', () async {
      const backend = CloudflareBackend();
      final base = Uri.parse('https://speed.cloudflare.com');

      final ping = await backend.getPingUri(base);
      expect(ping.path, '/__down');
      expect(ping.queryParameters['bytes'], '0');

      final down = await backend.getDownloadUri(base, ckSize: 4);
      expect(down.path, '/__down');
      expect(int.parse(down.queryParameters['bytes']!), greaterThanOrEqualTo(1024 * 1024));

      final up = await backend.getUploadUri(base);
      expect(up.path, '/__up');
    });
  });
}
