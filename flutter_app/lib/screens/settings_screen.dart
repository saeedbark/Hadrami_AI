import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController(text: ApiService.baseUrl);
  bool _testing = false;
  String? _testResult;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final stats = await ApiService.getStats();
      if (stats.isNotEmpty) {
        setState(() => _testResult =
            '✅ الاتصال ناجح! ${stats['total_words']} كلمة متاحة');
      } else {
        setState(() => _testResult = '❌ الخادم لا يستجيب');
      }
    } catch (e) {
      setState(() => _testResult = '❌ خطأ: $e');
    }

    setState(() => _testing = false);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Connection ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('🔗 إعدادات الخادم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(height: 12),
                  const Text('عنوان الـ API:',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _urlController,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'http://10.0.2.2:8000',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📱 للمحاكي: 10.0.2.2:8000\n'
                    '📡 لجهاز حقيقي: IP الكمبيوتر:8000',
                    style: TextStyle(
                        fontSize: 11, color: cs.outline, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  if (_testResult != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      child: Text(_testResult!,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_testing ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── About ────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ℹ️ عن المشروع',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(height: 12),
                  const _InfoRow('الإصدار', '1.0.0'),
                  const _InfoRow('الكلمات', '1029 كلمة حضرمية'),
                  const _InfoRow('المصدر', 'القاموس الحضرمي (154 صفحة)'),
                  const _InfoRow('Backend', 'FastAPI + Python'),
                  const _InfoRow('Frontend', 'Flutter + Provider'),
                  const _InfoRow('AI', 'RAG (Gemini / Ollama)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── How to run ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🚀 كيف تشغّل الـ Backend؟',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: cs.primary)),
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
                    style: TextStyle(fontSize: 12, color: cs.primary),
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
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

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
