import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/platform/live_monitor_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/home_view_model.dart';
import '../../usage/data/usage_repository.dart';
import 'about_screen.dart';
import 'live_notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _editBundle(SettingsStore settings, AppLocalizations l10n) async {
    final currentGb = settings.bundleBytes > 0
        ? (settings.bundleBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)
        : '';
    final controller = TextEditingController(text: currentGb);

    final val = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsBundleSize),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.commonGb,
                hintText: 'e.g. 10.0',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: MegaColors.primary),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    if (val != null && mounted) {
      final gb = double.tryParse(val) ?? 0.0;
      final bytes = (gb * 1024 * 1024 * 1024).round();
      settings.bundleBytes = bytes;
      if (bytes > 0 && settings.bundleStartMs <= 0) {
        settings.bundleStartMs = DateTime.now().millisecondsSinceEpoch;
      }

      final usageRepo = context.read<UsageRepository>();
      if (settings.alertsEnabled && bytes > 0) {
        usageRepo.usageSource.scheduleAlertWorker();
      } else {
        usageRepo.usageSource.cancelAlertWorker();
      }
      context.read<HomeViewModel>().refresh();
    }
  }

  Future<void> _pickStartDate(SettingsStore settings, bool isArabic) async {
    final current = settings.bundleStartMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(settings.bundleStartMs)
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      settings.bundleStartMs = picked.millisecondsSinceEpoch;
      context.read<HomeViewModel>().refresh();
    }
  }

  Future<void> _editValidity(SettingsStore settings, bool isArabic) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(isArabic ? 'مدة صلاحية الباقة' : 'Bundle Validity Period'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 1),
            child: Text(isArabic ? 'يوم واحد (يومي)' : '1 Day (Daily)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 7),
            child: Text(isArabic ? '7 أيام (أسبوعي)' : '7 Days (Weekly)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 30),
            child: Text(isArabic ? '30 يوماً (شهري)' : '30 Days (Monthly)'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              final controller = TextEditingController(text: settings.bundleValidityDays.toString());
              final custom = await showDialog<int>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(isArabic ? 'مدة مخصصة بالأيام' : 'Custom Days'),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isArabic ? 'الأيام' : 'Days',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: Text(isArabic ? 'إلغاء' : 'Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, int.tryParse(controller.text.trim())),
                      child: Text(isArabic ? 'حفظ' : 'Save'),
                    ),
                  ],
                ),
              );
              if (custom != null && custom > 0 && mounted) {
                settings.bundleValidityDays = custom;
                context.read<HomeViewModel>().refresh();
              }
            },
            child: Text(isArabic ? 'مدة مخصصة...' : 'Custom Days...'),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      settings.bundleValidityDays = selected;
      context.read<HomeViewModel>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final settings = context.watch<SettingsStore>();
    final homeVm = context.watch<HomeViewModel>();
    final usageRepo = context.read<UsageRepository>();

    final bundleGb = settings.bundleBytes > 0
        ? '${(settings.bundleBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ${l10n.commonGb}'
        : (isArabic ? 'لم يتم ضبط باقة' : 'Not configured');

    final startDateStr = settings.bundleStartMs > 0
        ? DateFormat('d MMMM yyyy', isArabic ? 'ar' : 'en').format(
            DateTime.fromMillisecondsSinceEpoch(settings.bundleStartMs),
          )
        : (isArabic ? 'غير محدد' : 'Not set');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        children: [
          // -------------------------------------------------------------
          // Group 1: Bundle
          // -------------------------------------------------------------
          _buildSectionHeader(isArabic ? 'الباقة' : 'Bundle'),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline, color: MegaColors.primary),
            title: Text(l10n.settingsBundleSize),
            subtitle: Text(bundleGb),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editBundle(settings, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined, color: MegaColors.primary),
            title: Text(isArabic ? 'تاريخ بدء الباقة' : 'Start Date'),
            subtitle: Text(startDateStr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickStartDate(settings, isArabic),
          ),
          ListTile(
            leading: const Icon(Icons.timelapse_outlined, color: MegaColors.primary),
            title: Text(isArabic ? 'مدة الصلاحية' : 'Validity Period'),
            subtitle: Text(
              isArabic
                  ? '${settings.bundleValidityDays} يوم'
                  : '${settings.bundleValidityDays} days',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editValidity(settings, isArabic),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.autorenew, color: MegaColors.primary),
            title: Text(isArabic ? 'تجديد الباقة تلقائياً' : 'Auto-Renew'),
            subtitle: Text(
              isArabic
                  ? 'بدء دورة جديدة وأرشفة السابقة عند انتهاء الصلاحية'
                  : 'Start a new cycle automatically when validity expires',
              style: const TextStyle(fontSize: 11),
            ),
            value: settings.bundleAutoRenew,
            activeThumbColor: MegaColors.primary,
            activeTrackColor: MegaColors.primaryContainerLight,
            onChanged: (val) {
              settings.bundleAutoRenew = val;
              homeVm.refresh();
            },
          ),
          const Divider(),

          // -------------------------------------------------------------
          // Group 2: Monitoring
          // -------------------------------------------------------------
          _buildSectionHeader(isArabic ? 'المراقبة والإشعارات' : 'Monitoring'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined, color: MegaColors.primary),
            title: Text(l10n.settingsAlerts),
            subtitle: Text(l10n.settingsAlertsDescription),
            value: settings.alertsEnabled,
            activeThumbColor: MegaColors.primary,
            activeTrackColor: MegaColors.primaryContainerLight,
            onChanged: (val) {
              settings.alertsEnabled = val;
              if (val && settings.bundleBytes > 0) {
                usageRepo.usageSource.scheduleAlertWorker();
              } else {
                usageRepo.usageSource.cancelAlertWorker();
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed, color: MegaColors.primary),
            title: Text(l10n.liveNotificationTitle),
            subtitle: Text(l10n.liveNotificationDesc),
            value: settings.liveMonitorEnabled,
            activeThumbColor: MegaColors.primary,
            activeTrackColor: MegaColors.primaryContainerLight,
            onChanged: (val) async {
              settings.liveMonitorEnabled = val;
              if (val) {
                final hasNotif = await LiveMonitorChannel.hasNotificationPermission();
                if (hasNotif) {
                  await LiveMonitorChannel.start();
                }
                homeVm.refresh();
              } else {
                await LiveMonitorChannel.stop();
              }
              if (mounted) setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: MegaColors.primary),
            title: Text(isArabic ? 'خيارات عرض العداد' : 'Notification Display Options'),
            subtitle: Text(
              isArabic
                  ? 'معدل التحديث، وحدة السرعة، استثناء الواي فاي'
                  : 'Update interval, speed unit, Wi-Fi filter',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveNotificationSettingsScreen()),
              );
            },
          ),
          const Divider(),

          // -------------------------------------------------------------
          // Group 3: App
          // -------------------------------------------------------------
          _buildSectionHeader(isArabic ? 'التطبيق' : 'App'),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: MegaColors.primary),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(settings.locale?.languageCode == 'en' ? 'English' : 'العربية'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseLanguage(settings),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined, color: MegaColors.primary),
            title: Text(l10n.settingsTheme),
            subtitle: Text(_themeLabel(settings.themeMode, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseTheme(settings, l10n),
          ),
          ListTile(
            leading: Icon(
              homeVm.hasAccess ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: homeVm.hasAccess ? MegaColors.success : MegaColors.warning,
            ),
            title: Text(l10n.settingsUsagePermission),
            subtitle: Text(
              homeVm.hasAccess ? l10n.usagePermissionGranted : l10n.usagePermissionMissing,
            ),
            trailing: OutlinedButton(
              onPressed: () => homeVm.openSettings(),
              child: Text(l10n.usageOpenSettings),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: MegaColors.primary),
            title: Text(l10n.settingsAbout),
            subtitle: Text(
              l10n.settingsAboutDesc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _chooseTheme(SettingsStore settings, AppLocalizations l10n) async {
    final mode = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ThemeMode.system),
            child: Text(l10n.settingsThemeSystem),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ThemeMode.light),
            child: Text(l10n.settingsThemeLight),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ThemeMode.dark),
            child: Text(l10n.settingsThemeDark),
          ),
        ],
      ),
    );

    if (mode != null) {
      settings.themeMode = mode;
    }
  }

  Future<void> _chooseLanguage(SettingsStore settings) async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language / اللغة'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'ar'),
            child: const Text('العربية (افتراضي)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en'),
            child: const Text('English'),
          ),
        ],
      ),
    );

    if (code != null) {
      settings.locale = Locale(code);
    }
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
    }
  }
}
