import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';
import '../../../core/app_info.dart';

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
                  Text(
                    '${AppInfo.appName} | ${AppInfo.appNameAr}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic ? 'الإصدار ${AppInfo.version}' : 'Version ${AppInfo.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic
                        ? 'تطبيق محلي لمراقبة استهلاك باقات الجوال مع عداد سرعة حي في شريط الحالة.'
                        : 'Offline-first mobile data monitor and live meter for Android.',
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
                    isArabic ? 'تطوير ${AppInfo.developerBrand}' : 'Developed by ${AppInfo.developerBrand}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? '${AppInfo.developerFull} — السودان'
                        : 'Elmahdi Abdalla (${AppInfo.developerBrand}) — Sudan',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isArabic
                        ? 'طوّرت هذا التطبيق لتوفير بديل عملي، نظيف وخفيف لتطبيقات مراقبة البيانات التي تمتلئ بالإعلانات وأدوات التتبع. التطبيق مجاني، مفتوح المصدر، ولا يتطلب أي تسجيل دخول أو اتصال بخوادم خارجية.'
                        : 'Built to provide a clean, lightweight alternative to commercial data trackers filled with ads and analytics. Free, open source, and operates completely on-device without remote servers.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.all(12),
                    decoration: BoxDecoration(
                      color: MegaColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: MegaColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'عندك فكرة تطبيق أو محتاج نظام يساعدك في شغلك؟ تواصل معي.'
                              : 'Have an app idea or need a software system tailored to your workflow? Get in touch.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          AppInfo.email,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MegaColors.primary,
                          ),
                        ),
                      ],
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
                  title: isArabic ? 'موقع المطور' : "Developer's Website",
                  value: 'almhdy24.com',
                  icon: Icons.language,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'الموقع الرسمي للتطبيق' : 'App Official Page',
                  value: 'almhdy24.com/products/mega',
                  icon: Icons.public,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'المستودع المفتوح' : 'Source Code',
                  value: 'github.com/almhdy24/mega',
                  icon: Icons.code,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'الدعم الفني' : 'Support',
                  value: AppInfo.supportEmail,
                  icon: Icons.support_agent,
                ),
                const Divider(height: 1),
                _buildInfoTile(
                  title: isArabic ? 'الترخيص' : 'License',
                  value: '${AppInfo.licenseName} (مفتوح المصدر)',
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
                      url: AppInfo.privacyPolicyUrl,
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
                      url: AppInfo.termsUrl,
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
