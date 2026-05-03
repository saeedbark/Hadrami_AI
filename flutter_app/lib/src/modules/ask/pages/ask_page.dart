import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';
import 'package:hadrami_nlp/src/core/utils/hadrami_lexicon_spans.dart';
import 'package:hadrami_nlp/src/modules/ask/forms/ask_form.dart';
import 'package:hadrami_nlp/src/modules/ask/providers/ask_provider.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';
import 'package:hadrami_nlp/src/widgets/hadrami_highlighted_text.dart';

Widget _askAnswerBody(
  String answer,
  List<WordEntry> context,
  List<HadramiSpan> askResultSpans,
  bool isError,
  ColorScheme colorScheme,
  Color highlightBg,
  Color highlightFg,
) {
  final baseStyle = TextStyle(
    fontSize: 16,
    height: 1.7,
    color: isError ? colorScheme.onErrorContainer : null,
  );
  if (isError) {
    if (kIsWeb) {
      return Text(
        answer,
        textDirection: TextDirection.rtl,
        style: baseStyle,
      );
    }
    return SelectableText(
      answer,
      textDirection: TextDirection.rtl,
      style: baseStyle,
    );
  }
  final spans = askResultSpans.isNotEmpty
      ? askResultSpans
      : hadramiSpansFromLexiconContext(
          answer,
          context.map((e) => e.toJson()).toList(growable: false),
        );
  if (spans.isEmpty) {
    if (kIsWeb) {
      return Text(
        answer,
        textDirection: TextDirection.rtl,
        style: baseStyle,
      );
    }
    return SelectableText(
      answer,
      textDirection: TextDirection.rtl,
      style: baseStyle,
    );
  }
  return HadramiHighlightedText(
    text: answer,
    spans: spans,
    baseStyle: baseStyle,
    highlightBackground: highlightBg,
    highlightForeground: highlightFg,
    textAlign: TextAlign.right,
    textDirection: TextDirection.rtl,
  );
}

class AskPage extends ConsumerWidget {
  const AskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final askState = ref.watch(askProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightBg =
        AppColors.hadramiLexiconHighlightBackground(Theme.of(context).brightness);
    final highlightFg =
        colorScheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.88);

    return AppScaffold(
      appBar: const AppAppBar(title: Text('اسأل عن اللهجة')),
      body: AskFormModelFormBuilder(
        model: const AskFormModel(),
        builder: (context, formModel, _) {
          void dismissInput() {
            if (kIsWeb) {
              // Avoid a Flutter web assertion when focus changes mid-pointer event.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  FocusManager.instance.primaryFocus?.unfocus();
                }
              });
              return;
            }
            FocusScope.of(context).unfocus();
          }

          void send() {
            formModel.form.markAllAsTouched();
            if (!formModel.form.valid) return;
            if (ref.read(askProvider).isLoading) return;
            final q = formModel.model.question.trim();
            ref.read(askProvider.notifier).ask(q);
            dismissInput();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ReactiveTextField<String>(
                formControlName: AskFormModelForm.questionControlName,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => send(),
                minLines: 1,
                maxLines: 4,
                validationMessages: {
                  ValidationMessage.required: (_) => 'السؤال مطلوب',
                  ValidationMessage.minLength: (_) => 'أدخل سؤالا أوضح',
                },
                decoration: const InputDecoration(
                  hintText: 'اسأل عن كلمة أو عبارة حضرمية...',
                  prefixIcon: Icon(Icons.chat_rounded),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: askState.isLoading ? null : send,
                icon: askState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(askState.isLoading ? 'جاري السؤال...' : 'اسأل'),
              ),
              if (askState.result != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      askState.result!.mode == 'error'
                          ? Icons.error_outline_rounded
                          : Icons.auto_awesome_rounded,
                      size: 18,
                      color: askState.result!.mode == 'error'
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        askState.result!.mode == 'error'
                            ? 'خطأ في الاتصال'
                            : 'الإجابة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: askState.result!.mode == 'error'
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                    if (askState.result!.mode != 'error')
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'نسخ',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: askState.result!.answer),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم النسخ')),
                            );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  color: askState.result!.mode == 'error'
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _askAnswerBody(
                      askState.result!.answer,
                      askState.result!.context,
                      askState.result!.hadramiSpans,
                      askState.result!.mode == 'error',
                      colorScheme,
                      highlightBg,
                      highlightFg,
                    ),
                  ),
                ),
                if (askState.result!.mode != 'error')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      askState.result!.answerSource == 'lexicon'
                          ? 'المصدر: القاموس الاحتياطي (لم تُنطَق إجابة من نموذج التوليد). وضع الخادم: ${askState.result!.mode}'
                          : 'المصدر: نص من نموذج التوليد. وضع الخادم: ${askState.result!.mode}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
