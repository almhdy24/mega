enum SpeedBackendProtocol {
  mega,
  librespeed,
  cloudflare,
  custom,
}

enum SpeedTestMode {
  quick,
  full,
}

enum SpeedStability {
  excellent,
  good,
  unstable,
}

class SpeedServer {
  final String id;
  final String name;
  final String nameAr;
  final String baseUrl;
  final SpeedBackendProtocol protocol;
  final String country;
  final bool isVerified;
  final String verifiedDate;

  const SpeedServer({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.baseUrl,
    required this.protocol,
    required this.country,
    this.isVerified = true,
    this.verifiedDate = '2026-11-17',
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : name;

  SpeedServer copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? baseUrl,
    SpeedBackendProtocol? protocol,
    String? country,
    bool? isVerified,
    String? verifiedDate,
  }) {
    return SpeedServer(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      baseUrl: baseUrl ?? this.baseUrl,
      protocol: protocol ?? this.protocol,
      country: country ?? this.country,
      isVerified: isVerified ?? this.isVerified,
      verifiedDate: verifiedDate ?? this.verifiedDate,
    );
  }
}

class SpeedServers {
  static const auto = SpeedServer(
    id: 'auto',
    name: 'Auto (Lowest Latency)',
    nameAr: 'تلقائي (الأقل تأخيراً)',
    baseUrl: '',
    protocol: SpeedBackendProtocol.mega,
    country: 'AUTO',
    isVerified: true,
  );

  static const megaServer = SpeedServer(
    id: 'mega-sd',
    name: 'MEGA Server (Port Sudan)',
    nameAr: 'خادم ميقا (بورتسودان)',
    baseUrl: 'https://almhdy24.com/mega/speedtest.php',
    protocol: SpeedBackendProtocol.mega,
    country: 'SD',
    isVerified: true,
  );

  static const cloudflare = SpeedServer(
    id: 'cloudflare',
    name: 'Cloudflare (Global Anycast)',
    nameAr: 'كلاودفلير (شبكة عالمية)',
    baseUrl: 'https://speed.cloudflare.com',
    protocol: SpeedBackendProtocol.cloudflare,
    country: 'GLOBAL',
    isVerified: true,
  );

  static const librespeedFra = SpeedServer(
    id: 'librespeed-fra',
    name: 'Frankfurt (Clouvider)',
    nameAr: 'فرانكفورت (Clouvider)',
    baseUrl: 'https://fra.speedtest.clouvider.net/backend',
    protocol: SpeedBackendProtocol.librespeed,
    country: 'DE',
    isVerified: true,
  );

  static const librespeedAms = SpeedServer(
    id: 'librespeed-ams',
    name: 'Amsterdam (Clouvider)',
    nameAr: 'أمستردام (Clouvider)',
    baseUrl: 'https://ams.speedtest.clouvider.net/backend',
    protocol: SpeedBackendProtocol.librespeed,
    country: 'NL',
    isVerified: true,
  );

  static const librespeedRome = SpeedServer(
    id: 'librespeed-rome',
    name: 'Rome (GARR)',
    nameAr: 'روما (GARR)',
    baseUrl: 'https://st-be-rm2.infra.garr.it',
    protocol: SpeedBackendProtocol.librespeed,
    country: 'IT',
    isVerified: true,
  );

  static const List<SpeedServer> candidatesForAuto = [
    megaServer,
    cloudflare,
    librespeedFra,
    librespeedAms,
    librespeedRome,
  ];

  static const List<SpeedServer> verifiedList = [
    auto,
    megaServer,
    cloudflare,
    librespeedFra,
    librespeedAms,
    librespeedRome,
  ];

  static SpeedServer findById(String id, {String? customUrl}) {
    if (id == 'auto') return auto;
    for (final s in verifiedList) {
      if (s.id == id) return s;
    }
    return SpeedServer(
      id: 'custom',
      name: 'Custom Server',
      nameAr: 'خادم مخصص',
      baseUrl: customUrl ?? id,
      protocol: SpeedBackendProtocol.custom,
      country: 'CUSTOM',
      isVerified: false,
    );
  }
}
