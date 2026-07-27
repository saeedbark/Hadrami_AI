import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/content_shell.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  static const _appVersion = '2.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController =
        useTextEditingController(text: ApiConfig.baseUrl);
    final testing = useState(false);
    final testResult = useState<String?>(null);
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(appThemeModeProvider);

    Future<void> testConnection() async {
      testing.value = true;
      testResult.value = null;
      try {
        final stats = await ref.read(apiServiceProvider).getStats();
        if (stats.isNotEmpty) {
          testResult.value =
              'الاتصال ناجح! ${stats['total_words']} كلمة متاحة';
        } else {
          testResult.value = 'الخادم لا يستجيب';
        }
      } catch (e) {
        testResult.value = 'خطأ: $e';
      }
      testing.value = false;
    }

    return AppScaffold(
      appBar: const AppAppBar(title: Text('الإعدادات')),
      body: ContentShell(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _SectionCard(
            icon: Icons.palette_rounded,
            title: 'المظهر',
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                  label: Text('فاتح'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                  label: Text('داكن'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness_rounded, size: 18),
                  label: Text('النظام'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(appThemeModeProvider.notifier).setTheme(s.first),
              multiSelectionEnabled: false,
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.dns_rounded,
            title: 'إعدادات الخادم',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('عنوان الـ API:',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'http://10.0.2.2:8000',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'للمحاكي: 10.0.2.2:8000  •  لجهاز حقيقي: IP الكمبيوتر:8000',
                  style: TextStyle(
                      fontSize: 11, color: colorScheme.outline, height: 1.5),
                ),
                const SizedBox(height: 12),
                if (testResult.value != null)
                  _TestResultBanner(result: testResult.value!),
                OutlinedButton.icon(
                  onPressed: testing.value ? null : testConnection,
                  icon: testing.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: Text(
                      testing.value ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const _SectionCard(
            icon: Icons.info_outline_rounded,
            title: 'عن المشروع',
            child: Column(
              children: [
                _InfoRow('الإصدار', _appVersion),
                _InfoRow('الكلمات', '1029+ كلمة حضرمية'),
                _InfoRow('المصدر', 'القاموس الحضرمي'),
                _InfoRow('Backend', 'FastAPI + Python'),
                _InfoRow('Frontend', 'Flutter + Riverpod'),
                _InfoRow('AI', 'RAG + Gemini'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.terminal_rounded,
            title: 'تشغيل الـ Backend',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SelectableText(
                    'cd backend\npip install -r requirements.txt\nuvicorn app.main:app --reload',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF4EC9B0),
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ثم افتح: http://localhost:8000/docs',
                  style: TextStyle(fontSize: 12, color: colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _TestResultBanner extends StatelessWidget {
  const _TestResultBanner({required this.result});
  final String result;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.contains('ناجح');
    final color = isSuccess ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(result, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
