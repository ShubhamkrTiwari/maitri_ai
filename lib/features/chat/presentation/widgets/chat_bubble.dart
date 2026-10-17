import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String avatarName;

  const ChatBubble({
    super.key,
    required this.message,
    required this.avatarName,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final isCrisis = message.isCrisisAlert;

    if (isCrisis) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.health_and_safety_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'We Care About You',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Helpline Resources:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('• India Tele-MANAS: 14416 or 1800-891-4416'),
                  Text('• USA/Canada Suicide Prevention: 988'),
                  Text('• International Lifeline: https://findahelpline.com'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                avatarName.isNotEmpty ? avatarName[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryLight
                    : Theme.of(context).cardTheme.color ?? Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
