import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/services/api_service.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlController =
        useTextEditingController(text: ApiConfig.baseUrl);
    final testing = useState(false);
    final testResult = useState<String?>(null);
    final colorScheme = Theme.of(context).colorScheme;

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('إعدادات الخادم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  const Text('عنوان الـ API:',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlController,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: 'http://10.0.2.2:8000',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'للمحاكي: 10.0.2.2:8000\nلجهاز حقيقي: IP الكمبيوتر:8000',
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.outline, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  if (testResult.value != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: testResult.value!.contains('ناجح')
                            ? Colors.green.withValues(alpha: .1)
                            : Colors.red.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: testResult.value!.contains('ناجح')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(testResult.value!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  OutlinedButton.icon(
                    onPressed: testing.value ? null : testConnection,
                    icon: testing.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(
                        testing.value ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عن المشروع',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                  const SizedBox(height: 12),
                  const _InfoRow('الإصدار', '2.0.0'),
                  const _InfoRow('الكلمات', '1029 كلمة حضرمية'),
                  const _InfoRow('المصدر', 'القاموس الحضرمي (154 صفحة)'),
                  const _InfoRow('Backend', 'FastAPI + Python'),
                  const _InfoRow('Frontend', 'Flutter + Riverpod'),
                  const _InfoRow('AI', 'RAG (Gemini)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('كيف تشغّل الـ Backend؟',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SelectableText(
                      'cd backend\npip install -r requirements.txt\nuvicorn app.main:app --reload',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
