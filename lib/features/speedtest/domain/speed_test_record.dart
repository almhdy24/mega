class SpeedTestRecord {
  final int? id;
  final int ts; // epoch ms
  final double pingMs;
  final double jitterMs;
  final double downMbps;
  final double upMbps;
  final String networkType; // 'wifi' | 'mobile' | 'unknown'
  final String server;

  const SpeedTestRecord({
    this.id,
    required this.ts,
    required this.pingMs,
    required this.jitterMs,
    required this.downMbps,
    required this.upMbps,
    required this.networkType,
    required this.server,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ts': ts,
      'ping_ms': pingMs,
      'jitter_ms': jitterMs,
      'down_mbps': downMbps,
      'up_mbps': upMbps,
      'network_type': networkType,
      'server': server,
    };
  }

  factory SpeedTestRecord.fromMap(Map<String, dynamic> map) {
    return SpeedTestRecord(
      id: map['id'] as int?,
      ts: (map['ts'] as num).toInt(),
      pingMs: (map['ping_ms'] as num).toDouble(),
      jitterMs: (map['jitter_ms'] as num).toDouble(),
      downMbps: (map['down_mbps'] as num).toDouble(),
      upMbps: (map['up_mbps'] as num).toDouble(),
      networkType: map['network_type'] as String,
      server: map['server'] as String,
    );
  }
}
