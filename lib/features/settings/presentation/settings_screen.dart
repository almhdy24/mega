import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/home_view_model.dart';
import '../../speedtest/presentation/server_selector_sheet.dart';
import '../../usage/data/usage_repository.dart';
import '../../usage/presentation/usage_view_model.dart';

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

      final usageRepo = context.read<UsageRepository>();
      if (settings.alertsEnabled && bytes > 0) {
        usageRepo.usageSource.scheduleAlertWorker();
      } else {
        usageRepo.usageSource.cancelAlertWorker();
      }
      context.read<HomeViewModel>().refresh();
    }
  }

  Future<void> _editCycleDay(SettingsStore settings, AppLocalizations l10n) async {
    final day = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsCycleStart),
        children: List.generate(31, (i) {
          final d = i + 1;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, d),
            child: Text(
              l10n.settingsCycleDay(d),
              style: TextStyle(
                fontWeight: d == settings.cycleStartDay ? FontWeight.bold : FontWeight.normal,
                color: d == settings.cycleStartDay ? MegaColors.primary : null,
              ),
            ),
          );
        }),
      ),
    );

    if (day != null && mounted) {
      settings.cycleStartDay = day;
      context.read<HomeViewModel>().refresh();
      context.read<UsageViewModel>().refresh();
    }
  }

  Future<void> _editServerUrl(SettingsStore settings, AppLocalizations l10n) async {
    await ServerSelectorSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final settings = context.watch<SettingsStore>();
    final usageVm = context.watch<UsageViewModel>();
    final usageRepo = context.read<UsageRepository>();

    final bundleGb = settings.bundleBytes > 0
        ? '${(settings.bundleBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ${l10n.commonGb}'
        : l10n.homeNoBundle;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        children: [
          // Section: Bundle & Cycle
          ListTile(
            leading: const Icon(Icons.pie_chart, color: MegaColors.primary),
            title: Text(l10n.settingsBundleSize),
            subtitle: Text(bundleGb),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editBundle(settings, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: MegaColors.primary),
            title: Text(l10n.settingsCycleStart),
            subtitle: Text(l10n.settingsCycleDay(settings.cycleStartDay)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editCycleDay(settings, l10n),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active, color: MegaColors.primary),
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
          const Divider(),

          // Section: Preferences
          ListTile(
            leading: const Icon(Icons.brightness_6, color: MegaColors.primary),
            title: Text(l10n.settingsTheme),
            subtitle: Text(_themeLabel(settings.themeMode, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseTheme(settings, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: MegaColors.primary),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(settings.locale?.languageCode == 'en' ? 'English' : 'العربية'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseLanguage(settings),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined, color: MegaColors.primary),
            title: Text(l10n.speedServer),
            subtitle: Text(
              '${settings.selectedServer.flagEmoji} ${settings.selectedServer.localizedName(isArabic)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editServerUrl(settings, l10n),
          ),
          const Divider(),

          // Section: Permissions & Info
          ListTile(
            leading: Icon(
              usageVm.hasAccess ? Icons.check_circle : Icons.warning_amber_rounded,
              color: usageVm.hasAccess ? MegaColors.success : MegaColors.warning,
            ),
            title: Text(l10n.settingsUsagePermission),
            subtitle: Text(
              usageVm.hasAccess ? l10n.usagePermissionGranted : l10n.usagePermissionMissing,
            ),
            trailing: OutlinedButton(
              onPressed: () => usageVm.openSettings(),
              child: Text(l10n.usageOpenSettings),
            ),
          ),
          const Divider(),

          // Section: About
          Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.all(6),
                          decoration: BoxDecoration(
                            color: MegaColors.primaryContainerLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.info_outline, color: MegaColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.settingsAbout,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.settingsAboutDesc,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.settingsLicense,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
