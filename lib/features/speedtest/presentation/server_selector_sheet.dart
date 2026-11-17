import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/colors.dart';
import '../domain/speed_server.dart';
import 'speedtest_view_model.dart';

class ServerSelectorSheet extends StatefulWidget {
  const ServerSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ServerSelectorSheet(),
    );
  }

  @override
  State<ServerSelectorSheet> createState() => _ServerSelectorSheetState();
}

class _ServerSelectorSheetState extends State<ServerSelectorSheet> {
  final _customUrlController = TextEditingController();

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _showCustomUrlDialog(BuildContext context, SpeedTestViewModel vm) async {
    _customUrlController.text = vm.settings.testCustomUrl;
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خادم مخصص / Custom Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل رابط خادم فحص السرعة (LibreSpeed أو MEGA backend):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customUrlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com/backend',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء / Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _customUrlController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: MegaColors.primary),
            child: const Text('حفظ / Save'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      final customServer = SpeedServers.findById('custom', customUrl: url);
      vm.selectServer(customServer);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SpeedTestViewModel>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final selected = vm.selectedServer;
    final latencies = vm.serverLatencies;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              const Icon(Icons.dns_outlined, color: MegaColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? 'اختيار خادم الفحص' : 'Select Speed Test Server',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (vm.isProbingServers)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: MegaColors.primary),
                )
              else
                TextButton.icon(
                  onPressed: () => vm.probeAllServers(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(
                    isArabic ? 'قياس الاستجابة' : 'Ping All',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // 1. Auto option
                _buildServerCard(
                  server: SpeedServers.auto,
                  isSelected: selected.id == 'auto',
                  isArabic: isArabic,
                  latency: null,
                  onTap: () {
                    vm.selectServer(SpeedServers.auto);
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 16),

                // 2. Verified servers
                ...SpeedServers.candidatesForAuto.map((s) {
                  final latency = latencies[s.id];
                  return _buildServerCard(
                    server: s,
                    isSelected: selected.id == s.id,
                    isArabic: isArabic,
                    latency: latency,
                    onTap: () {
                      vm.selectServer(s);
                      Navigator.pop(context);
                    },
                  );
                }),

                const Divider(height: 16),

                // 3. Custom Server option
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 4),
                  leading: const CircleAvatar(
                    backgroundColor: MegaColors.primaryContainerLight,
                    child: Text('⚙️', style: TextStyle(fontSize: 18)),
                  ),
                  title: Text(
                    isArabic ? 'خادم مخصص' : 'Custom Server',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    selected.id == 'custom' && selected.baseUrl.isNotEmpty
                        ? selected.baseUrl
                        : (isArabic ? 'أدخل رابط خادم خاص بك' : 'Enter a custom speed test URL'),
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: selected.id == 'custom'
                      ? const Icon(Icons.check_circle, color: MegaColors.primary)
                      : const Icon(Icons.chevron_right),
                  onTap: () => _showCustomUrlDialog(context, vm),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildServerCard({
    required SpeedServer server,
    required bool isSelected,
    required bool isArabic,
    required double? latency,
    required VoidCallback onTap,
  }) {
    String? latencyText;
    Color? latencyColor;
    if (latency != null) {
      if (latency.isInfinite) {
        latencyText = isArabic ? 'غير متاح' : 'Offline';
        latencyColor = MegaColors.danger;
      } else {
        latencyText = '${latency.toStringAsFixed(0)} ms';
        latencyColor = latency < 80
            ? MegaColors.success
            : (latency < 160 ? MegaColors.warning : MegaColors.danger);
      }
    }

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: MegaColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      tileColor: isSelected
          ? MegaColors.primaryContainerLight.withValues(alpha: 0.3)
          : null,
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Text(server.flagEmoji, style: const TextStyle(fontSize: 22)),
      ),
      title: Text(
        server.localizedName(isArabic),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: server.id == 'auto'
          ? Text(
              isArabic
                  ? 'يختار الخادم الأقل زمناً تلقائياً قبل كل فحص'
                  : 'Automatically selects fastest server before test',
              style: const TextStyle(fontSize: 11),
            )
          : Text(
              server.baseUrl,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (latencyText != null) ...[
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: latencyColor?.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                latencyText,
                style: TextStyle(
                  color: latencyColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isSelected)
            const Icon(Icons.check_circle, color: MegaColors.primary, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}
