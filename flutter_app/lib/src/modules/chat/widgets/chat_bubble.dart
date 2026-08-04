import 'package:flutter/material.dart';
import 'package:hadrami_nlp/src/core/strings/app_strings.dart';
import 'package:hadrami_nlp/src/core/utils/time_formatting.dart';
import 'package:hadrami_nlp/src/modules/chat/models/chat_message.dart';
import 'package:hadrami_nlp/src/widgets/animated_appear.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final scheme = Theme.of(context).colorScheme;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.8;

    return AnimatedAppear(
      duration: const Duration(milliseconds: 240),
      slideOffset: Offset(isUser ? 0.08 : -0.08, 0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          child: Container(
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: isUser ? 48 : 0,
              right: isUser ? 0 : 48,
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUser ? scheme.primary : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        message.content,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: isUser ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      if (message.note != null && message.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 14,
                              color: isUser ? scheme.onPrimary : scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.wordDetailNoteLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    isUser ? scheme.onPrimary : scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          message.note!,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color:
                                (isUser ? scheme.onPrimary : scheme.onSurface)
                                    .withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    formatTime(message.timestamp),
                    style: TextStyle(fontSize: 10, color: scheme.outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
