import 'package:flutter/material.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/widgets/text_input.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  final ValueChanged<String> onSend;
  final bool enabled;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
              ),
              child: AppTextField(
                controller: _controller,
                variant: AppTextFieldVariant.pill,
                enabled: widget.enabled,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                onSubmitted: _send,
                hintText: AppStrings.chatInputHint,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: _hasText && widget.enabled ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: IconButton.filled(
              onPressed: _hasText && widget.enabled ? _send : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.enabled
                    ? const Icon(Icons.send_rounded,
                        size: 20, key: ValueKey('send'))
                    : const SizedBox(
                        key: ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
              style: IconButton.styleFrom(
                backgroundColor: _hasText && widget.enabled
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHigh,
                foregroundColor: _hasText && widget.enabled
                    ? colorScheme.onPrimary
                    : colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
