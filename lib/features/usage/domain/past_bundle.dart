class PastBundle {
  final int id;
  final int startMs;
  final int endMs;
  final int sizeBytes;
  final int usedBytes;

  const PastBundle({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.sizeBytes,
    required this.usedBytes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'start_ms': startMs,
        'end_ms': endMs,
        'size_bytes': sizeBytes,
        'used_bytes': usedBytes,
      };

  factory PastBundle.fromMap(Map<String, dynamic> map) => PastBundle(
        id: (map['id'] as num).toInt(),
        startMs: (map['start_ms'] as num).toInt(),
        endMs: (map['end_ms'] as num).toInt(),
        sizeBytes: (map['size_bytes'] as num).toInt(),
        usedBytes: (map['used_bytes'] as num).toInt(),
      );
}
