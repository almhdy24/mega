import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../../../core/platform/live_monitor_channel.dart';
import '../../../core/prefs/settings_store.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/home_view_model.dart';

class OnboardingSheet extends StatefulWidget {
  const OnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const OnboardingSheet(),
    );
  }

  @override
  State<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<OnboardingSheet> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Bundle setup state
  final TextEditingController _sizeController = TextEditingController(text: '10');
  bool _isGb = true;
  int _validityDays = 30;
  bool _autoRenew = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentPage == 1) {
      // Recheck permissions when user returns from settings
      context.read<HomeViewModel>().refresh();
    }
  }

  void _finishOnboarding() async {
    final settings = context.read<SettingsStore>();
    final parsed = double.tryParse(_sizeController.text.trim()) ?? 0;
    final bytes = (_isGb ? (parsed * 1024 * 1024 * 1024) : (parsed * 1024 * 1024)).round();

    if (bytes > 0) {
      settings.bundleBytes = bytes;
      settings.bundleValidityDays = _validityDays;
      settings.bundleAutoRenew = _autoRenew;
      settings.bundleStartMs = DateTime.now().millisecondsSinceEpoch;
      settings.bundleId = 1;
    }

    settings.hasSeenOnboarding = true;

    // Auto enable status bar notification by default if notifications are allowed
    if (settings.liveMonitorEnabled) {
      final hasNotif = await LiveMonitorChannel.hasNotificationPermission();
      if (hasNotif) {
        await LiveMonitorChannel.start();
      }
    }

    if (!mounted) return;
    context.read<HomeViewModel>().refresh();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<SettingsStore>().hasSeenOnboarding = true;
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.onboardingSkip),
                  ),
                  Row(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? MegaColors.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 48), // balance skip button
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildScreen1(context, l10n),
                  _buildScreen2(context, l10n),
                  _buildScreen3(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen1(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MegaColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.signal_cellular_alt, size: 56, color: MegaColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWhyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingWhyDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.onboardingNext),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen2(BuildContext context, AppLocalizations l10n) {
    final vm = context.watch<HomeViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPermissionsTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPermissionsDesc,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Permission Card 1: Data Usage Access
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: vm.hasAccess
                    ? MegaColors.success.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (vm.hasAccess ? MegaColors.success : MegaColors.primary).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      vm.hasAccess ? Icons.check_circle_outline : Icons.data_usage,
                      color: vm.hasAccess ? MegaColors.success : MegaColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.onboardingUsagePermTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.onboardingUsagePermDesc,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (vm.hasAccess)
                    Chip(
                      label: Text(l10n.onboardingPermGranted, style: const TextStyle(fontSize: 11)),
                      backgroundColor: MegaColors.success.withValues(alpha: 0.15),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      avatar: const Icon(Icons.check, size: 14, color: MegaColors.success),
                    )
                  else
                    FilledButton(
                      onPressed: () => vm.usageRepository.usageSource.openAccessSettings(),
                      style: FilledButton.styleFrom(
                        backgroundColor: MegaColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: Text(l10n.onboardingPermGrantAction),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Permission Card 2: Notifications & Status Bar Speed
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: vm.hasNotificationAccess
                    ? MegaColors.success.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (vm.hasNotificationAccess ? MegaColors.success : MegaColors.primary).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      vm.hasNotificationAccess ? Icons.notifications_active_outlined : Icons.notifications_none,
                      color: vm.hasNotificationAccess ? MegaColors.success : MegaColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.onboardingNotifPermTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.onboardingNotifPermDesc,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (vm.hasNotificationAccess)
                    Chip(
                      label: Text(l10n.onboardingPermGranted, style: const TextStyle(fontSize: 11)),
                      backgroundColor: MegaColors.success.withValues(alpha: 0.15),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      avatar: const Icon(Icons.check, size: 14, color: MegaColors.success),
                    )
                  else
                    FilledButton(
                      onPressed: () async {
                        await LiveMonitorChannel.requestNotificationPermission();
                        if (!context.mounted) return;
                        await vm.refresh();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MegaColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: Text(l10n.onboardingPermGrantAction),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: MegaColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.onboardingAutoStartLiveNotice,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.onboardingNext),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen3(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bundleSetupTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Bundle size input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.settingsBundleSize,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(value: true, label: Text(l10n.commonGb)),
                  ButtonSegment<bool>(value: false, label: Text(l10n.commonMb)),
                ],
                selected: {_isGb},
                onSelectionChanged: (s) => setState(() => _isGb = s.first),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Validity
          Text(
            l10n.bundleValidityDays,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.bundleValidity1Day),
                selected: _validityDays == 1,
                onSelected: (s) => setState(() => _validityDays = 1),
              ),
              ChoiceChip(
                label: Text(l10n.bundleValidity7Days),
                selected: _validityDays == 7,
                onSelected: (s) => setState(() => _validityDays = 7),
              ),
              ChoiceChip(
                label: Text(l10n.bundleValidity30Days),
                selected: _validityDays == 30,
                onSelected: (s) => setState(() => _validityDays = 30),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Auto renew
          SwitchListTile(
            title: Text(l10n.bundleAutoRenewLabel, style: const TextStyle(fontSize: 14)),
            value: _autoRenew,
            onChanged: (v) => setState(() => _autoRenew = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _finishOnboarding,
              style: FilledButton.styleFrom(
                backgroundColor: MegaColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.onboardingStartUsing),
            ),
          ),
        ],
      ),
    );
  }
}
