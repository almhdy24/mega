class DailyUsage {
  final String day; // 'YYYY-MM-DD'
  final int mobileRx;
  final int mobileTx;
  final int wifiRx;
  final int wifiTx;
  final int updatedAt; // epoch ms

  const DailyUsage({
    required this.day,
    required this.mobileRx,
    required this.mobileTx,
    required this.wifiRx,
    required this.wifiTx,
    required this.updatedAt,
  });

  int get mobileTotal => mobileRx + mobileTx;
  int get wifiTotal => wifiRx + wifiTx;
  int get total => mobileTotal + wifiTotal;

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'mobile_rx': mobileRx,
      'mobile_tx': mobileTx,
      'wifi_rx': wifiRx,
      'wifi_tx': wifiTx,
      'updated_at': updatedAt,
    };
  }

  factory DailyUsage.fromMap(Map<String, dynamic> map) {
    return DailyUsage(
      day: map['day'] as String,
      mobileRx: (map['mobile_rx'] as num).toInt(),
      mobileTx: (map['mobile_tx'] as num).toInt(),
      wifiRx: (map['wifi_rx'] as num).toInt(),
      wifiTx: (map['wifi_tx'] as num).toInt(),
      updatedAt: (map['updated_at'] as num).toInt(),
    );
  }
}
