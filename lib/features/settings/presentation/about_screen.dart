import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'عن التطبيق' : 'About App'),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          // App Header Card
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: MegaColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'MEGA | ميقا',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic ? 'الإصدار 1.1.0' : 'Version 1.1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? 'تطبيق محلي لمراقبة استهلاك باقات الإنترنت وفحص السرعة مع عداد حي في شريط الحالة.'
                        : 'Offline-first network data monitor and live speed meter for Android.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Developer Note Card
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'المطور' : 'Developer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'المهدي عبدالله (Elmahdi Dev) — السودان'
                        : 'Elmahdi Abdalla (Elmahdi Dev) — Sudan',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'تم تطوير هذا التطبيق لتوفير بديل عملي وخفيف لتطبيقات فحص السرعة ومراقبة البيانات التقليدية التي تستهلك سعات ضخمة من الباقات المحدودة وتحتوي على إعلانات أو أدوات تتبع. التطبيق مجاني، بدون إعلانات، ولا يتطلب أي تسجيل دخول.'
                        : 'Built to provide a lightweight, ad-free alternative to data tracking and speed testing tools that consume excessive bandwidth on metered connections. Free, tracker-free, and requires no account.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technical Specifications Card
          Card(
            child: Column(
              children: [
                _buildInfoTile(
                  title: isArabic ? 'خادم الفحص المعتمد' : 'Default Speed Server',
                  value: 'https://almhdy24.com/mega/speedtest.php',
                  icon: Icons.dns_outlined,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'المستودع المفتوح' : 'Source Code',
                  value: 'github.com/almhdy24/mega',
                  icon: Icons.code,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'الموقع الرسمي' : 'Official Website',
                  value: 'almhdy24.com/products/mega',
                  icon: Icons.public,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'البريد الإلكتروني' : 'Contact',
                  value: 'support@almhdy24.com',
                  icon: Icons.mail_outline,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'الترخيص' : 'License',
                  value: 'Apache License 2.0 / Open Source',
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Terms Links
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: MegaColors.primary),
                  title: Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
                  subtitle: const Text('almhdy24.com/products/mega/privacy.html', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showWebDialog(
                      context,
                      title: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                      url: 'https://almhdy24.com/products/mega/privacy.html',
                      summary: isArabic
                          ? 'تطبيق ميقا لا يجمع، ولا يخزن، ولا يشارك أي بيانات شخصية أو معلومات عن شبكتك. جميع البيانات المقروءة من إحصائيات النظام تحفظ محلياً على هاتفك فقط.'
                          : 'MEGA does not collect, store, or share any personal data or network history. All data is queried from OS APIs and stored strictly on your local device.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: MegaColors.primary),
                  title: Text(isArabic ? 'شروط الاستخدام' : 'Terms of Service'),
                  subtitle: const Text('almhdy24.com/products/mega/terms.html', style: TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showWebDialog(
                      context,
                      title: isArabic ? 'شروط الاستخدام' : 'Terms of Service',
                      url: 'https://almhdy24.com/products/mega/terms.html',
                      summary: isArabic
                          ? 'التطبيق أداة استرشادية مفتوحة المصدر لمساعدتك في إدارة باقاتك. يعتمد التطبيق على قراءات النظام المباشرة.'
                          : 'MEGA is an open-source utility provided as-is to help you manage your data plan based on direct Android system readings.',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: MegaColors.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: SelectableText(
        value,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _showWebDialog(
    BuildContext context, {
    required String title,
    required String url,
    required String summary,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary, style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 11, color: MegaColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق / Close'),
          ),
        ],
      ),
    );
  }
}
