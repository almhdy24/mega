# MEGA | ميقا 🇸🇩

> **ميقابايتك محسوبة** · Every byte counts  
> **Owner**: Elmahdi Dev · **License**: MIT · **Target Platform**: Android (minSdk 26+)

---

## English Overview

**MEGA** is a 100% free, open-source, ultra-lightweight Android app built with Flutter and Kotlin to test internet speed and accurately monitor data consumption. It was built specifically as a reliable, honest alternative to bloated, ad-filled proprietary network tools.

### Core Principles
- **100% Free & Open Source**: No ads, subscriptions, logins, accounts, analytics, or background telemetry.
- **Offline-First**: Usage history and data logs are stored locally on your device via SQLite.
- **Ultra-Lightweight**: Target arm64 release APK size is **< 10 MB**.
- **Privacy First**: Network usage stats are read directly from Android's `NetworkStatsManager` via a local platform channel. No user data ever leaves your device.

---

## نظرة عامة بالعربية

**ميقا (MEGA)** هو تطبيق أندرويد مجاني ومفتوح المصدر وخفيف للغاية، مبني باستخدام Flutter و Kotlin لاختبار سرعة الإنترنت ومراقبة استهلاك البيانات بدقة. صُمم التطبيق كبديل سوداني وعربي خالص لأدوات قياس السرعة التجارية الممتلئة بالإعلانات والتتبع.

### المبادئ الأساسية
- **مجاني 100% ومفتوح المصدر**: لا إعلانات، لا حسابات، لا تتبع، ولا جمع لأي بيانات شخصية.
- **يعمل بدون إنترنت (Offline-First)**: يتم حفظ سجل الاستهلاك واختبارات السرعة محلياً في قاعدة بيانات SQLite داخل هاتفك.
- **حجم فائق الصغر**: حجم ملف التثبيت (arm64 APK) **أقل من 10 ميجابايت**.
- **أقصى درجات الخصوصية**: يتم استخراج إحصائيات الاستهلاك مباشرة عبر نظام أندرويد (`NetworkStatsManager`) دون إرسال أي معلومة خارج هاتفك على الإطلاق.

---

## Features (v1.0 MVP) | المميزات

1. **Internet Speed Test | اختبار سرعة الإنترنت**:
   - Pure Dart implementation using standard `HttpClient` (zero bloated native dependencies).
   - Measures Ping, Jitter, Download speed, and Upload speed.
   - Live real-time Mbps gauge with TCP slow-start warm-up filtering and trimmed-mean calculation.
   - Data consumption warning before launching test on mobile connections.
   
2. **Data Usage Monitoring | مراقبة الاستهلاك**:
   - Live query of Android system traffic statistics.
   - Separation of Mobile data vs. Wi-Fi traffic.
   - Snapshot MAX persistence: device data expiration will never overwrite stored historical records.

3. **Daily & Monthly Statistics | إحصائيات يومية وشهرية**:
   - Clear views for Today, Current Billing Cycle, and Current Calendar Month.
   - Custom 30-day interactive bar chart powered by Flutter `CustomPainter` (0 KB added library overhead).

4. **Bundle & Cycle Tracking | متابعة الباقة ودورة الفاتورة**:
   - Configurable bundle size (GB/MB) and renewal day (1-31).
   - Hero dashboard showing remaining data, used percentage, and days remaining.
   - Daily pace analysis: compares current daily average with the target daily rate needed to make your bundle last.

5. **Data Alerts & Background Worker | تنبيهات الاستهلاك الذكية**:
   - Configurable alerts (default at 50%, 80%, and 100% of bundle).
   - Native Android `WorkManager` worker runs in the background every 15 minutes.
   - Fires system notifications only when new thresholds are crossed, with zero battery drain (no persistent foreground services).

6. **Speed Test History | سجل الاختبارات**:
   - Chronological list of previous speed tests.
   - Trend chart rendered with `CustomPainter`.

---

## Tech Stack & Architecture | البنية التقنية

- **UI & Framework**: Flutter 3 (Dart 3) with Material 3.
- **Architecture**: Feature-first MVVM with `ChangeNotifier` ViewModels and `provider`.
- **Database**: `sqflite` with hand-written SQL and automated migration versioning.
- **Internationalization (i18n)**: Native ARB localization with Arabic (default RTL) and English.
- **Native Android**: Kotlin plugins with `AppOpsManager`, `NetworkStatsManager`, and `WorkManager`.

### Dependency License & Size Audit | تدقيق الحزم والتراخيص

| Package | License | Estimated Size | Purpose |
|---|---|---|---|
| `provider` | MIT | ~30 KB | State management & dependency injection |
| `sqflite` | BSD-2-Clause | ~60 KB | Local SQLite storage |
| `path` | BSD-3-Clause | ~15 KB | Cross-platform file paths |
| `shared_preferences` | BSD-3-Clause | ~30 KB | Persistent user settings |
| `intl` / `flutter_localizations` | BSD-3-Clause | ~100 KB | Formatting and Arabic/English localization |
| `androidx.work:work-runtime-ktx` | Apache-2.0 | Android Jetpack | Background alert worker |

*Total added package size: ~235 KB (well within the < 10 MB APK budget).*

---

## Build & Release | البناء والإصدار عبر GitHub Actions

As per project rules, release APKs are compiled exclusively in **GitHub Actions** with ProGuard/R8 shrinking and ABI splitting enabled.

### Required GitHub Repository Secrets
To sign production APKs, add the following secrets to your GitHub repository under **Settings > Secrets and variables > Actions**:

- `KEYSTORE_BASE64`: Base64-encoded string of your Android release keystore (`.jks`).
- `KEYSTORE_PASSWORD`: Keystore password.
- `KEY_ALIAS`: Keystore key alias.
- `KEY_PASSWORD`: Keystore alias password.

*If secrets are omitted, CI builds the APK using the default debug signature.*

### GitHub Actions Workflow
The workflow at `.github/workflows/build.yml` triggers on:
- Every push to `main`
- Every pull request
- Git tags matching `v*` (automatically drafts a GitHub Release with the split APKs)

Build commands executed on CI:
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols
```

---

## Local Development & Testing | التطوير المحلي والاختبارات

To run static analysis and tests locally:

```bash
# Verify code quality
flutter analyze

# Run unit and integration tests
flutter test
```

### Test Coverage
- `test/billing_cycle_test.dart`: Cycle boundaries, February leap/non-leap years, day 31 rollover, year transition.
- `test/alerts_test.dart`: Threshold evaluation, jump handling, duplicate notification prevention.
- `test/speed_math_test.dart`: Pure math verification for median, jitter, bitrate, and trimmed mean.
- `test/usage_repository_test.dart`: SQLite snapshot MAX rule, non-zero preservation, and range queries.

---

## License | الترخيص

This project is open-source software licensed under the [MIT License](LICENSE).  
Copyright (c) 2026 Elmahdi Dev.
