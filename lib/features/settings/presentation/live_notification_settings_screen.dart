import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/platform/live_monitor_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../l10n/app_localizations.dart';

class LiveNotificationSettingsScreen extends StatelessWidget {
  const LiveNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final settings = context.watch<SettingsStore>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.liveNotificationTitle),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          // Main Toggle Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: settings.liveMonitorEnabled
                    ? MegaColors.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: settings.liveMonitorEnabled ? 1.5 : 1,
              ),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsetsDirectional.all(16),
              secondary: CircleAvatar(
                backgroundColor: settings.liveMonitorEnabled
                    ? MegaColors.primaryContainerLight
                    : Colors.transparent,
                child: Icon(
                  Icons.speed,
                  color: settings.liveMonitorEnabled
                      ? MegaColors.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              title: Text(
                l10n.liveNotificationTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Text(
                  l10n.liveNotificationDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              value: settings.liveMonitorEnabled,
              activeThumbColor: MegaColors.primary,
              activeTrackColor: MegaColors.primaryContainerLight,
              onChanged: (val) async {
                settings.liveMonitorEnabled = val;
                if (val) {
                  await LiveMonitorChannel.start();
                } else {
                  await LiveMonitorChannel.stop();
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Customization Options
          if (settings.liveMonitorEnabled) ...[
            Text(
              isArabic ? 'خيارات العرض والعداد' : 'Display & Meter Options',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  // Update Interval
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: MegaColors.primary),
                    title: Text(isArabic ? 'معدل التحديث' : 'Update Interval'),
                    subtitle: Text(
                      isArabic
                          ? '${settings.liveMonitorIntervalSec} ثانية'
                          : '${settings.liveMonitorIntervalSec}s',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1s', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 2, label: Text('2s', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 5, label: Text('5s', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {settings.liveMonitorIntervalSec},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          settings.liveMonitorIntervalSec = set.first;
                          LiveMonitorChannel.apply();
                        }
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Speed Unit
                  ListTile(
                    leading: const Icon(Icons.swap_vert, color: MegaColors.primary),
                    title: Text(isArabic ? 'وحدة السرعة' : 'Speed Unit'),
                    subtitle: Text(
                      settings.liveMonitorUnit == 'bits'
                          ? (isArabic ? 'بت (Kbps / Mbps)' : 'Bits (Kbps / Mbps)')
                          : (isArabic ? 'بايت (KB/s / MB/s)' : 'Bytes (KB/s / MB/s)'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'bytes',
                          label: Text(isArabic ? 'بايت' : 'Bytes', style: const TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: 'bits',
                          label: Text(isArabic ? 'بت' : 'Bits', style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {settings.liveMonitorUnit},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          settings.liveMonitorUnit = set.first;
                          LiveMonitorChannel.apply();
                        }
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Status Bar Icon
                  SwitchListTile(
                    secondary: const Icon(Icons.art_track, color: MegaColors.primary),
                    title: Text(isArabic ? 'عداد السرعة في شريط الحالة' : 'Status Bar Speed Icon'),
                    subtitle: Text(
                      isArabic
                          ? 'يعرض رقم السرعة مباشرة في الشريط العلوي (مثل 1.2M أو 80K)'
                          : 'Renders dynamic speed number in status bar',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: settings.liveMonitorIconStyle == 'dynamic',
                    activeThumbColor: MegaColors.primary,
                    activeTrackColor: MegaColors.primaryContainerLight,
                    onChanged: (val) {
                      settings.liveMonitorIconStyle = val ? 'dynamic' : 'static';
                      LiveMonitorChannel.apply();
                    },
                  ),
                  const Divider(height: 1),

                  // Mobile Only
                  SwitchListTile(
                    secondary: const Icon(Icons.signal_cellular_alt, color: MegaColors.primary),
                    title: Text(isArabic ? 'حساب بيانات الجوال فقط' : 'Count Mobile Data Only'),
                    subtitle: Text(
                      isArabic
                          ? 'استثناء سرعة الواي فاي وحساب باقة الشريحة فقط'
                          : 'Tracks only cellular network traffic',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: settings.liveMonitorMobileOnly,
                    activeThumbColor: MegaColors.primary,
                    activeTrackColor: MegaColors.primaryContainerLight,
                    onChanged: (val) {
                      settings.liveMonitorMobileOnly = val;
                      LiveMonitorChannel.apply();
                    },
                  ),
                  const Divider(height: 1),

                  // Hide on Wi-Fi
                  SwitchListTile(
                    secondary: const Icon(Icons.wifi_off, color: MegaColors.primary),
                    title: Text(isArabic ? 'إخفاء الإشعار عند اتصال الواي فاي' : 'Hide When On Wi-Fi'),
                    subtitle: Text(
                      isArabic
                          ? 'يختفي الإشعار تلقائياً عند الاتصال بشبكة واي فاي'
                          : 'Notification hides automatically on Wi-Fi',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: settings.liveMonitorHideOnWifi,
                    activeThumbColor: MegaColors.primary,
                    activeTrackColor: MegaColors.primaryContainerLight,
                    onChanged: (val) {
                      settings.liveMonitorHideOnWifi = val;
                      LiveMonitorChannel.apply();
                    },
                  ),
                  const Divider(height: 1),

                  // Screen Off Update
                  SwitchListTile(
                    secondary: const Icon(Icons.battery_saver, color: MegaColors.primary),
                    title: Text(isArabic ? 'الاستمرار في التحديث مع إطفاء الشاشة' : 'Keep Updating With Screen Off'),
                    subtitle: Text(
                      isArabic
                          ? 'إيقافه يوفر طاقة البطارية ويستأنف فور تشغيل الشاشة'
                          : 'Pauses live sampling when screen is off to save battery',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: settings.liveMonitorScreenOff,
                    activeThumbColor: MegaColors.primary,
                    activeTrackColor: MegaColors.primaryContainerLight,
                    onChanged: (val) {
                      settings.liveMonitorScreenOff = val;
                      LiveMonitorChannel.apply();
                    },
                  ),
                  const Divider(height: 1),

                  // Start on Boot
                  SwitchListTile(
                    secondary: const Icon(Icons.restart_alt, color: MegaColors.primary),
                    title: Text(isArabic ? 'البدء تلقائياً بعد إعادة التشغيل' : 'Start After Device Reboot'),
                    value: settings.liveMonitorStartBoot,
                    activeThumbColor: MegaColors.primary,
                    activeTrackColor: MegaColors.primaryContainerLight,
                    onChanged: (val) {
                      settings.liveMonitorStartBoot = val;
                      LiveMonitorChannel.apply();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Battery Optimization Help Card
          Text(
            isArabic ? 'استقرار العداد في الخلفية' : 'Background Stability',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: MegaColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.liveNotificationBatteryHelp,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'تطبق أنظمة مثل Xiaomi (MIUI/HyperOS), Tecno (HiOS), Infinix (XOS), Samsung (OneUI) إغلاقاً صارماً للتطبيقات العاملة في الخلفية لتوفير البطارية. لضمان بقاء عداد السرعة مستمراً:'
                        : 'Custom Android skins (MIUI, HyperOS, HiOS, OneUI) may kill background services. To ensure continuous live meter:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? '1. استثنِ ميقا من تحسين البطارية (غير مقيد / Unrestricted).\n2. فعّل التشغيل التلقائي (Auto-start) من إعدادات الهاتف.'
                        : '1. Set battery optimization to Unrestricted.\n2. Enable Auto-start in phone settings.',
                    style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => LiveMonitorChannel.openBatterySettings(),
                          icon: const Icon(Icons.battery_charging_full, size: 16),
                          label: Text(
                            isArabic ? 'إعدادات البطارية' : 'Battery Settings',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => LiveMonitorChannel.openAppDetailsSettings(),
                          icon: const Icon(Icons.settings_applications, size: 16),
                          label: Text(
                            isArabic ? 'معلومات التطبيق' : 'App Details',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
