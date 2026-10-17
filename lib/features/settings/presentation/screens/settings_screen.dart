import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../avatar/presentation/controllers/avatar_controller.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeletingAccount = false;

  void _showHelplineModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.health_and_safety_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Support & Crisis Helplines'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'If you or someone you know is going through a difficult time, free and confidential support is available:',
              ),
              SizedBox(height: 12),
              Text('🇮🇳 India Tele-MANAS: 14416 / 1800-891-4416', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('🇺🇸 USA / 🇨🇦 Canada Lifeline: 988', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('🇬🇧 UK Samaritans: 116 123', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Global Helpline Finder: https://findahelpline.com'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    try {
      final client = SupabaseService.client;
      final avatar = await client.from(AppConstants.tableAvatars).select().eq('user_id', user.id).maybeSingle();
      final topics = await client.from(AppConstants.tableUserTopics).select().eq('user_id', user.id);
      final memories = await client.from(AppConstants.tableMemories).select().eq('user_id', user.id);

      final exportPayload = {
        'user_id': user.id,
        'email': user.email,
        'export_date': DateTime.now().toIso8601String(),
        'avatar': avatar,
        'topics': topics,
        'memories': memories,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportPayload);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exported Personal Data (JSON)'),
          content: SingleChildScrollView(
            child: SelectableText(jsonString, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export data: $e')),
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account & Data?'),
        content: const Text(
          'This will permanently erase your profile, avatar, saved topics, chat history, and all long-term memories. This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isDeletingAccount = true);
              try {
                final user = SupabaseService.currentUser;
                if (user != null) {
                  final client = SupabaseService.client;
                  await client.from(AppConstants.tableMemories).delete().eq('user_id', user.id);
                  await client.from(AppConstants.tableUserTopics).delete().eq('user_id', user.id);
                  await client.from(AppConstants.tableAvatars).delete().eq('user_id', user.id);
                  await client.from(AppConstants.tableChatSessions).delete().eq('user_id', user.id);
                }
                await ref.read(authControllerProvider.notifier).signOut();
                if (mounted) context.go('/login');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isDeletingAccount = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(avatarControllerProvider).avatar;
    final topicsState = ref.watch(topicsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          avatar.name.isNotEmpty ? avatar.name[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              avatar.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Personality: ${avatar.personality.toUpperCase()}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              '${topicsState.selectedTopics.length} Active Topics',
                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Customization Section
              const Text('Companion Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.face_retouching_natural_rounded, color: AppColors.primaryLight),
                      title: const Text('Edit Avatar & Personality'),
                      subtitle: const Text('Name, visual style, voice pitch/speed'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/avatar-builder'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category_outlined, color: AppColors.primaryLight),
                      title: const Text('Manage Discussion Topics'),
                      subtitle: const Text('Add or remove allowed topic focus'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/topic-picker'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.psychology_outlined, color: AppColors.primaryLight),
                      title: const Text('Manage Long-Term Memory'),
                      subtitle: const Text('View, edit, or clear stored facts'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/memories'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Privacy & Safety Section
              const Text('Privacy & Safety', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_rounded, color: Colors.blueAccent),
                      title: const Text('Export My Data'),
                      subtitle: const Text('Download all avatar, topic, and memory data in JSON'),
                      onTap: _exportUserData,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: Colors.green),
                      title: const Text('Crisis & Helpline Resources'),
                      subtitle: const Text('Emergency support contacts and hotlines'),
                      onTap: _showHelplineModal,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      title: const Text('Delete My Account & Data', style: TextStyle(color: Colors.redAccent)),
                      subtitle: const Text('Permanently erase all profile and chat history'),
                      onTap: _isDeletingAccount ? null : _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
