# Google Play Store Listing & Reviewer Notes — MEGA (ميقا)

## 1. Metadata & Character Count Verification

| Asset | File | Character Count | Google Play Limit | Status |
| :--- | :--- | :---: | :---: | :---: |
| Short Description (AR) | `short-description-ar.txt` | 73 | 80 | PASS |
| Short Description (EN) | `short-description-en.txt` | 75 | 80 | PASS |
| Full Description (AR) | `full-description-ar.txt` | 2,623 | 4,000 | PASS |
| Full Description (EN) | `full-description-en.txt` | 3,057 | 4,000 | PASS |
| Release Notes (AR) | `release-notes-ar.txt` | 424 | 500 | PASS |
| Release Notes (EN) | `release-notes-en.txt` | 450 | 500 | PASS |
| App Icon (Play Store) | `icon-playstore-512.png` | 512x512 (14 KB) | 512x512 (< 1 MB) | PASS |

---

## 2. Store Categorization & Tags

- **Application Category:** Tools / Utilities (`APPLICATION_CATEGORY_UTILITIES`)
- **Content Rating:** Everyone (3+)
- **Primary Language:** Arabic (`ar-SA`, `ar-EG`, `ar-SD`)
- **Secondary Language:** English (`en-US`)
- **Key Search Tags:**
  - AR: `مراقبة البيانات`, `باقة الإنترنت`, `عداد السرعة`, `استهلاك الرصيد`, `بيانات الجوال`, `حفظ البيانات`
  - EN: `data monitor`, `data usage`, `network speed meter`, `data tracker`, `bundle manager`, `bandwidth`

---

## 3. Data Safety Form Responses (Google Play Console)

| Question | Value | Details |
| :--- | :--- | :--- |
| **Does your app collect or share user data?** | **No** | No user data is collected, stored remotely, or transmitted off-device. |
| **Is data transferred over a secure connection?** | N/A | App makes zero background network requests. |
| **Do you provide a way for users to request data deletion?** | **Yes** | Users can reset bundles locally or clear app storage via Android Settings. |
| **Does the app contain advertising?** | **No** | 100% ad-free. |
| **Does the app contain trackers/analytics SDKs?** | **No** | No Firebase, Google Analytics, or Crashlytics SDKs. |

---

## 4. Permission Declarations for Google Play Reviewers

### A. `android.permission.PACKAGE_USAGE_STATS` (Special App Access)
- **User-Facing Purpose:** To read local cellular and Wi-Fi data traffic counters recorded by Android OS (`NetworkStatsManager`), calculate remaining bundle quotas, and compute safe daily allowances.
- **Privacy Assurance:** Only aggregate byte counters are read. Packet inspection, browsing history, or message contents are never accessed.

### B. `android.permission.FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_SPECIAL_USE` (Android 14+)
- **Subtype:** `Displays ongoing network speed meter in status bar and live data usage stats for user awareness`
- **User-Facing Purpose:** Displays a persistent, user-controllable real-time download/upload speed indicator in the Android status bar and notification tray.
- **Battery Optimization:** Polling automatically pauses when the device screen is powered off.

### C. `android.permission.POST_NOTIFICATIONS` (Android 13+)
- **User-Facing Purpose:** Delivers the ongoing status bar notification and threshold alerts (at 50%, 80%, and 100% of bundle capacity) to prevent accidental bill shock.

---

## 5. Contact & Attribution

- **Developer:** Elmahdi Abdalla (المهدي عبدالله)
- **Brand:** Elmahdi Dev
- **Official Website:** `https://almhdy24.com/products/mega`
- **Contact Email:** `hello@almhdy24.com`
- **Support Email:** `support@almhdy24.com`
- **Privacy Policy:** `https://almhdy24.com/products/mega/privacy.html`
- **Source Code Repository:** `https://github.com/almhdy24/mega`
