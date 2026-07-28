import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/configs/phrase_translate_config.dart';
import 'package:hadrami_nlp/src/modules/phrase/forms/phrase_form.dart';
import 'package:hadrami_nlp/src/modules/phrase/providers/phrase_translate_provider.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/content_shell.dart';
import 'package:hadrami_nlp/src/widgets/hadrami_highlighted_text.dart';
import 'package:hadrami_nlp/src/widgets/text_input.dart';

/// Web: avoid [SelectableText] next to [TextField] (Flutter web input assertion).
Widget _plainResultText(String text, ColorScheme colorScheme, bool isError) {
  final style = TextStyle(
    fontSize: 16,
    color: isError ? colorScheme.onErrorContainer : null,
  );
  if (kIsWeb) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      style: style,
    );
  }
  return SelectableText(
    text,
    textDirection: TextDirection.rtl,
    style: style,
  );
}

class PhraseTranslatePage extends HookConsumerWidget {
  
  const PhraseTranslatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = useState('ar_to_hadrami');
    final state = ref.watch(phraseTranslateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightBg = AppColors.hadramiLexiconHighlightBackground(
        Theme.of(context).brightness);
    final highlightFg =
        colorScheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.88);

    return AppScaffold(
      appBar: const AppAppBar(title: Text('ترجمة العبارات')),
      body: ContentShell(
        maxWidth: 880,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: PhraseFormModelFormBuilder(
          model: const PhraseFormModel(),
          builder: (context, formModel, _) {
            void run() {
              formModel.form.markAllAsTouched();
              if (!formModel.form.valid) return;
              if (ref.read(phraseTranslateProvider).isLoading) return;
              final text = formModel.model.phrase.trim();
              ref.read(phraseTranslateProvider.notifier).translate(
                    text: text,
                    direction: direction.value,
                  );
              FocusScope.of(context).unfocus();
            }

            return ListView(
              children: [
                Text(
                  'الاتجاه',
                  style: Theme.of(context).textTheme.titleSmall,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'ar_to_hadrami',
                      label: Text('فصحى → حضرمي'),
                      icon: Icon(Icons.arrow_forward, size: 18),
                    ),
                    ButtonSegment<String>(
                      value: 'hadrami_to_ar',
                      label: Text('حضرمي → فصحى'),
                      icon: Icon(Icons.arrow_forward, size: 18),
                    ),
                  ],
                  selected: {direction.value},
                  onSelectionChanged: (s) => direction.value = s.first,
                  multiSelectionEnabled: false,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  formControlName: PhraseFormModelForm.phraseControlName,
                  minLines: 3,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      PhraseTranslateConfig.maxLength,
                    ),
                  ],
                  validationMessages: {
                    ValidationMessage.required: (_) => 'النص مطلوب',
                    ValidationMessage.minLength: (_) => 'أدخل عبارة أوضح',
                    ValidationMessage.maxLength: (_) =>
                        'الحد الأعلى ${PhraseTranslateConfig.maxLength} حرفاً',
                  },
                  alignLabelWithHint: true,
                  hintText:
                      'من ${PhraseTranslateConfig.minLength} إلى ${PhraseTranslateConfig.maxLength} حرفاً (أفضل جودة حتى ${PhraseTranslateConfig.softRecommendLength})',
                  prefixIcon: const Icon(Icons.translate),
                ),
                ReactiveValueListenableBuilder<String>(
                  formControl: formModel.phraseControl,
                  builder: (context, control, _) {
                    final v = control.value ?? '';
                    final n = v.runes.length;
                    const maxL = PhraseTranslateConfig.maxLength;
                    const soft = PhraseTranslateConfig.softRecommendLength;
                    const chunk = PhraseTranslateConfig.chunkWarningLength;
                    final overSoft = n > soft;
                    final overChunk = n > chunk;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                '$n / $maxL',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: overChunk
                                          ? colorScheme.error
                                          : overSoft
                                              ? colorScheme.tertiary
                                              : colorScheme.outline,
                                    ),
                              ),
                              const Spacer(),
                              if (overChunk)
                                Text(
                                  'سيُقسّم النص تلقائياً لترجمة أفضل',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: colorScheme.error),
                                  textDirection: TextDirection.rtl,
                                )
                              else if (overSoft)
                                Text(
                                  'للجودة الأفضل قسّم النص',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: colorScheme.tertiary),
                                  textDirection: TextDirection.rtl,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: n / maxL,
                              minHeight: 4,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: overChunk
                                  ? colorScheme.error.withValues(alpha: 0.7)
                                  : overSoft
                                      ? colorScheme.tertiary
                                      : colorScheme.primary
                                          .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : run,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate),
                  label: Text(state.isLoading ? 'جاري الترجمة...' : 'ترجم'),
                ),
                if (state.result != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          state.result!.mode == 'error'
                              ? 'تنبيه'
                              : 'النتيجة (${state.result!.mode})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: state.result!.mode == 'error'
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      if (state.result!.translatedText.isNotEmpty)
                        IconButton(
                          tooltip: 'نسخ',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: state.result!.translatedText),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم النسخ')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: state.result!.mode == 'error'
                        ? colorScheme.errorContainer
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: state.result!.mode == 'error' ||
                              state.result!.hadramiSpans.isEmpty
                          ? _plainResultText(
                              state.result!.translatedText,
                              colorScheme,
                              state.result!.mode == 'error',
                            )
                          : HadramiHighlightedText(
                              text: state.result!.translatedText,
                              spans: state.result!.hadramiSpans,
                              baseStyle: const TextStyle(fontSize: 16),
                              highlightBackground: highlightBg,
                              highlightForeground: highlightFg,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                    ),
                  ),
                  if (state.result!.context.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'مداخل مستخدمة من القاموس',
                      style: Theme.of(context).textTheme.labelLarge,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      textDirection: TextDirection.rtl,
                      children: state.result!.context
                          .map(
                            (e) => Chip(
                              label: Text(
                                '${e.wordVocalized} → ${e.fushaEquivalent ?? ''}',
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}
