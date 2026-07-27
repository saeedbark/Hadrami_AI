import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hadrami_nlp/src/modules/chat/providers/chat_provider.dart';
import 'package:hadrami_nlp/src/modules/chat/widgets/chat_bubble.dart';
import 'package:hadrami_nlp/src/modules/chat/widgets/chat_input.dart';
import 'package:hadrami_nlp/src/widgets/animated_appear.dart';
import 'package:hadrami_nlp/src/widgets/content_shell.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final scrollController = useScrollController();
    final scheme = Theme.of(context).colorScheme;

    void scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      });
    }

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        scrollToBottom();
      }
    });

    final messages = chatState.messages;
    final showTyping = chatState.isLoading;
    final itemCount = messages.length + (showTyping ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة الذكية'),
        centerTitle: true,
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'مسح المحادثة',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: ContentShell(
        maxWidth: 880,
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _EmptyChat(scheme: scheme)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: itemCount,
                      itemBuilder: (_, index) {
                        if (showTyping && index == messages.length) {
                          return _TypingIndicator(scheme: scheme);
                        }
                        return ChatBubble(message: messages[index]);
                      },
                    ),
            ),
            ChatInput(
              enabled: !chatState.isLoading,
              onSend: (text) =>
                  ref.read(chatProvider.notifier).sendMessage(text),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح المحادثة'),
        content: const Text('هل تريد مسح جميع الرسائل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: AnimatedAppear(
        slideOffset: const Offset(0, 0.04),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 40,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'مرحباً! أنا مساعدك في اللهجة الحضرمية',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اسألني عن أي كلمة أو عبارة حضرمية، أو اطلب ترجمة جملة',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionChip(label: 'ما معنى كلمة ويش؟'),
                  _SuggestionChip(label: 'ترجم: كيف حالك؟'),
                  _SuggestionChip(label: 'أمثال حضرمية شهيرة'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends ConsumerWidget {
  const _SuggestionChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(
        label,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 12, color: scheme.primary),
      ),
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.4),
      side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      onPressed: () => ref.read(chatProvider.notifier).sendMessage(label),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.scheme});
  final ColorScheme scheme;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.scheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final phase = (_controller.value + i / 3) % 1.0;
                    final opacity = 0.3 + 0.7 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.scheme.primary.withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(width: 10),
            Text(
              'جاري الكتابة...',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 13, color: widget.scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
