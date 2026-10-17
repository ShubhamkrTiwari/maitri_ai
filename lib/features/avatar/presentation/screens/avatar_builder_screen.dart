import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../controllers/avatar_controller.dart';
import '../widgets/animated_avatar_widget.dart';

class AvatarBuilderScreen extends ConsumerStatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  ConsumerState<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends ConsumerState<AvatarBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;

  final List<String> _personalities = ['friendly', 'funny', 'calm', 'motivating', 'professional'];
  final List<String> _styles = ['friendly', 'bot', 'cute', 'minimal'];
  final List<String> _hairStyles = ['short', 'long', 'curly', 'bald'];
  final List<String> _outfits = ['casual', 'formal', 'sporty'];

  final List<Map<String, String>> _sampleImagePresets = [
    {'name': 'Cyber Companion', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80'},
    {'name': 'Anime Friend', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&q=80'},
    {'name': 'Robot AI', 'url': 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=500&q=80'},
    {'name': 'Portrait', 'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&q=80'},
  ];

  @override
  void initState() {
    super.initState();
    final avatar = ref.read(avatarControllerProvider).avatar;
    _nameController = TextEditingController(text: avatar.name);
    _imageUrlController = TextEditingController(text: avatar.customImageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _updateCustomImage(String? url) {
    _imageUrlController.text = url ?? '';
    ref.read(avatarControllerProvider.notifier).updateAvatar(
          ref.read(avatarControllerProvider).avatar.copyWith(customImageUrl: url),
        );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final imagePath = await ImagePickerHelper.pickImage(source);
      if (imagePath != null && imagePath.isNotEmpty) {
        _updateCustomImage(imagePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Companion image selected!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
              title: const Text('Choose from Gallery / Photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
              title: const Text('Take a Photo with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarControllerProvider);
    final avatar = avatarState.avatar;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Your Companion'),
        actions: [
          TextButton(
            onPressed: avatarState.isLoading
                ? null
                : () async {
                    final controller = ref.read(avatarControllerProvider.notifier);
                    controller.updateAvatar(
                      avatar.copyWith(
                        name: _nameController.text.trim(),
                        customImageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
                      ),
                    );
                    final success = await controller.saveAvatar();
                    if (!mounted) return;
                    if (success) {
                      context.go('/topic-picker');
                    }
                  },
            child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Visual Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.avatarCardGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    AnimatedAvatarWidget(
                      avatar: avatar,
                      state: AvatarAnimState.happy,
                      size: 130,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      avatar.name.isEmpty ? 'Companion' : avatar.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Personality: ${avatar.personality.toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Name Input
              TextField(
                controller: _nameController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                decoration: InputDecoration(
                  labelText: 'Companion Name',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (val) {
                  ref.read(avatarControllerProvider.notifier).updateAvatar(
                        avatar.copyWith(name: val),
                      );
                },
              ),
              const SizedBox(height: 24),

              // Image Upload / Photo Mode Option
              const Text('Companion Image / Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Upload a photo from your device gallery/camera, paste a URL, or choose a preset photo.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _showImageSourcePicker,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Upload Photo from Gallery / Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageUrlController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Or Paste Image URL...',
                        prefixIcon: const Icon(Icons.link_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onChanged: (val) {
                        _updateCustomImage(val.trim().isEmpty ? null : val.trim());
                      },
                    ),
                  ),
                  if (avatar.customImageUrl != null && avatar.customImageUrl!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.redAccent),
                      onPressed: () => _updateCustomImage(null),
                      tooltip: 'Remove Custom Image',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Preset Photo Cards
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sampleImagePresets.length,
                  itemBuilder: (context, index) {
                    final preset = _sampleImagePresets[index];
                    final isSelected = avatar.customImageUrl == preset['url'];

                    return GestureDetector(
                      onTap: () => _updateCustomImage(preset['url']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(preset['url']!),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Personality Selector
              const Text('Personality Traits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _personalities.map((p) {
                  final isSelected = avatar.personality == p;
                  return ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(avatarControllerProvider.notifier).updateAvatar(
                              avatar.copyWith(personality: p),
                            );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Visual Style (if 2D avatar mode)
              if (avatar.customImageUrl == null || avatar.customImageUrl!.isEmpty) ...[
                const Text('Avatar Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _styles.map((s) {
                    final isSelected = avatar.style == s;
                    return ChoiceChip(
                      label: Text(s[0].toUpperCase() + s.substring(1)),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(avatarControllerProvider.notifier).updateAvatar(
                                avatar.copyWith(style: s),
                              );
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Hair & Outfit
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hair Style', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: avatar.hair,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _hairStyles
                                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(avatarControllerProvider.notifier).updateAvatar(
                                      avatar.copyWith(hair: val),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Outfit Style', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: avatar.outfit,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _outfits
                                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(avatarControllerProvider.notifier).updateAvatar(
                                      avatar.copyWith(outfit: val),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Voice Pitch & Speed
              const Text('Voice Pitch & Speed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Pitch', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: avatar.voicePitch,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      label: avatar.voicePitch.toStringAsFixed(1),
                      onChanged: (val) {
                        ref.read(avatarControllerProvider.notifier).updateAvatar(
                              avatar.copyWith(voicePitch: val),
                            );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Speed', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: avatar.voiceSpeed,
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      label: avatar.voiceSpeed.toStringAsFixed(1),
                      onChanged: (val) {
                        ref.read(avatarControllerProvider.notifier).updateAvatar(
                              avatar.copyWith(voiceSpeed: val),
                            );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: avatarState.isLoading
                    ? null
                    : () async {
                        final controller = ref.read(avatarControllerProvider.notifier);
                        controller.updateAvatar(
                          avatar.copyWith(
                            name: _nameController.text.trim(),
                            customImageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
                          ),
                        );
                        final success = await controller.saveAvatar();
                        if (!mounted) return;
                        if (success) {
                          context.go('/topic-picker');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: avatarState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Select Topics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
