import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hadrami_nlp/src/modules/home/services/home_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/providers/theme_provider.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/content_shell.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  static const _appVersion = '2.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testing = useState(false);
    final testResult = useState<String?>(null);
    final themeMode = ref.watch(appThemeModeProvider);

    Future<void> testConnection() async {
      testing.value = true;
      testResult.value = null;
      try {
        final stats = await ref.read(homeServiceProvider).getStats();
        if (stats != null && stats.totalWords > 0) {
          testResult.value =
              '${AppStrings.settingsConnectionSuccessPrefix}${stats.totalWords}${AppStrings.settingsConnectionSuccessSuffix}';
        } else {
          testResult.value = AppStrings.settingsServerNotRespondingMessage;
        }
      } catch (e) {
        testResult.value = '${AppStrings.settingsConnectionErrorPrefix}$e';
      }
      testing.value = false;
    }

    return AppScaffold(
      appBar: const AppAppBar(title: Text(AppStrings.commonSettingsLabel)),
      body: ContentShell(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              icon: Icons.palette_rounded,
              title: AppStrings.settingsThemeSectionLabel,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded, size: 18),
                    label: Text(AppStrings.settingsThemeLightLabel),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded, size: 18),
                    label: Text(AppStrings.settingsThemeDarkLabel),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_brightness_rounded, size: 18),
                    label: Text(AppStrings.settingsThemeSystemLabel),
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
              title: AppStrings.settingsServerStatusSectionLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    label: Text(testing.value
                        ? AppStrings.settingsTestingInProgressLabel
                        : AppStrings.settingsTestConnectionLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              icon: Icons.info_outline_rounded,
              title: AppStrings.settingsAboutSectionLabel,
              child: Column(
                children: [
                  _InfoRow(
                      AppStrings.settingsInfoVersionLabel, _appVersion),
                  _InfoRow(AppStrings.settingsInfoSourceLabel,
                      AppStrings.settingsInfoSourceValue),
                  _InfoRow(AppStrings.settingsInfoBackendLabel,
                      AppStrings.settingsInfoBackendValue),
                  _InfoRow(AppStrings.settingsInfoFrontendLabel,
                      AppStrings.settingsInfoFrontendValue),
                  _InfoRow(AppStrings.settingsInfoAiLabel,
                      AppStrings.settingsInfoAiValue),
                  if (kDebugMode)
                    _InfoRow(
                        AppStrings.settingsInfoApiLabel, ApiConfig.baseUrl),
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
            isSuccess
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
