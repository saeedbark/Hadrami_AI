import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:hadrami_nlp/src/modules/ask/forms/ask_form.dart';
import 'package:hadrami_nlp/src/modules/ask/providers/ask_provider.dart';
import 'package:hadrami_nlp/src/widgets/app_scaffold.dart';

class AskPage extends ConsumerWidget {
  const AskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final askState = ref.watch(askProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      appBar: const AppAppBar(title: Text('اسأل عن اللهجة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AskFormModelFormBuilder(
          model: const AskFormModel(),
          builder: (context, formModel, _) {
            void send() {
              formModel.form.markAllAsTouched();
              if (!formModel.form.valid) return;
              if (ref.read(askProvider).isLoading) return;
              final q = formModel.model.question.trim();
              ref.read(askProvider.notifier).ask(q);
              FocusScope.of(context).unfocus();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReactiveTextField<String>(
                  formControlName: AskFormModelForm.questionControlName,
                  textDirection: TextDirection.rtl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => send(),
                  validationMessages: {
                    ValidationMessage.required: (_) => 'السؤال مطلوب',
                    ValidationMessage.minLength: (_) => 'أدخل سؤالا أوضح',
                  },
                  decoration: const InputDecoration(
                    hintText: 'اسأل عن كلمة أو عبارة حضرمية...',
                    prefixIcon: Icon(Icons.chat),
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
                      : const Icon(Icons.send),
                  label: Text(askState.isLoading ? 'جاري السؤال...' : 'اسأل'),
                ),
                const SizedBox(height: 16),
                if (askState.result != null) ...[
                  Text(
                    askState.result!.mode == 'error'
                        ? 'خطأ في الاتصال'
                        : 'الإجابة (${askState.result!.mode})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: askState.result!.mode == 'error'
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: askState.result!.mode == 'error'
                        ? colorScheme.errorContainer
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        askState.result!.answer,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 16,
                          color: askState.result!.mode == 'error'
                              ? colorScheme.onErrorContainer
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
