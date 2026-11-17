import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navUsage),
      ),
      body: Center(
        child: Text(l10n.navUsage),
      ),
    );
  }
}
