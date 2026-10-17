import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/chat_controller.dart';

class SessionsDrawer extends ConsumerWidget {
  const SessionsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.primaryLight),
                  const SizedBox(width: 12),
                  const Text(
                    'Chat Sessions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryLight),
                    onPressed: () {
                      ref.read(chatControllerProvider.notifier).createNewSession();
                      Navigator.pop(context);
                    },
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: chatState.sessions.length,
                itemBuilder: (context, index) {
                  final session = chatState.sessions[index];
                  final isSelected = chatState.currentSession?.id == session.id;

                  return ListTile(
                    leading: Icon(
                      Icons.forum_outlined,
                      color: isSelected ? AppColors.primaryLight : Colors.grey,
                    ),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primaryLight : null,
                      ),
                    ),
                    subtitle: Text(
                      '${session.updatedAt.day}/${session.updatedAt.month}/${session.updatedAt.year}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: isSelected,
                    onTap: () {
                      ref.read(chatControllerProvider.notifier).selectSession(session);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.psychology_outlined),
              title: const Text('Memory Manager'),
              onTap: () {
                Navigator.pop(context);
                context.push('/memories');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings & Privacy'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
