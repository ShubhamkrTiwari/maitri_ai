import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../domain/avatar_model.dart';

enum AvatarAnimState { idle, talking, happy, thinking }

class AnimatedAvatarWidget extends StatefulWidget {
  final AvatarModel avatar;
  final AvatarAnimState state;
  final double size;

  const AnimatedAvatarWidget({
    super.key,
    required this.avatar,
    this.state = AvatarAnimState.idle,
    this.size = 100,
  });

  @override
  State<AnimatedAvatarWidget> createState() => _AnimatedAvatarWidgetState();
}

class _AnimatedAvatarWidgetState extends State<AnimatedAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _mouthController;
  late Animation<double> _mouthAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _mouthAnimation = Tween<double>(begin: 3.0, end: 16.0).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == AvatarAnimState.talking) {
      _mouthController.repeat(reverse: true);
    } else {
      _mouthController.stop();
      _mouthController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mouthController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  ImageProvider? _getCustomImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:')) {
      return NetworkImage(url);
    } else if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last.replaceAll('\n', '').replaceAll('\r', '').trim();
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    } else if (!kIsWeb && (url.startsWith('file://') || url.startsWith('/'))) {
      return FileImage(File(url.replaceFirst('file://', '')));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final skinColor = _parseHexColor(widget.avatar.skinColorHex, const Color(0xFFFFD1DC));
    final hairColor = _parseHexColor(widget.avatar.hairColorHex, const Color(0xFF2D3436));
    final outfitColor = _parseHexColor(widget.avatar.outfitColorHex, const Color(0xFF6C5CE7));

    final customImage = widget.avatar.customImageUrl != null && widget.avatar.customImageUrl!.isNotEmpty
        ? _getCustomImageProvider(widget.avatar.customImageUrl!)
        : null;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.state == AvatarAnimState.thinking ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outfitColor.withOpacity(0.15),
              border: Border.all(color: outfitColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: outfitColor.withOpacity(0.3),
                  blurRadius: widget.state == AvatarAnimState.talking ? 18 : 10,
                  spreadRadius: widget.state == AvatarAnimState.talking ? 4 : 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (customImage != null) ...[
                    // Photo Avatar Mode
                    Image(
                      image: customImage,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _build2DAvatar(skinColor, hairColor, widget.size),
                    ),

                    // Talking Lip Sync / Face Movement Overlay over Photo
                    Positioned(
                      bottom: widget.size * 0.22,
                      child: AnimatedBuilder(
                        animation: _mouthAnimation,
                        builder: (context, child) {
                          double mouthHeight = 3.0;
                          if (widget.state == AvatarAnimState.talking) {
                            mouthHeight = _mouthAnimation.value;
                          } else if (widget.state == AvatarAnimState.happy) {
                            mouthHeight = 10.0;
                          }

                          return Container(
                            width: widget.size * 0.28,
                            height: mouthHeight,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade100.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(mouthHeight / 2),
                              border: Border.all(color: Colors.pink.shade900, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // 2D Vector Canvas Avatar Mode
                    _build2DAvatar(skinColor, hairColor, widget.size),
                  ],

                  // Thinking Indicator Badge
                  if (widget.state == AvatarAnimState.thinking)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _build2DAvatar(Color skinColor, Color hairColor, double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Hair Back
        if (widget.avatar.hair == 'long')
          Positioned(
            top: size * 0.15,
            child: Container(
              width: size * 0.75,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: BorderRadius.circular(size * 0.3),
              ),
            ),
          ),

        // Face Circle
        Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            color: skinColor,
            shape: BoxShape.circle,
          ),
        ),

        // Short Hair Top
        if (widget.avatar.hair == 'short' || widget.avatar.hair == 'curly')
          Positioned(
            top: size * 0.16,
            child: Container(
              width: size * 0.6,
              height: size * 0.22,
              decoration: BoxDecoration(
                color: hairColor,
                borderRadius: BorderRadius.circular(size * 0.2),
              ),
            ),
          ),

        // Eyes
        Positioned(
          top: size * 0.38,
          child: SizedBox(
            width: size * 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEye(size),
                _buildEye(size),
              ],
            ),
          ),
        ),

        // Mouth
        Positioned(
          bottom: size * 0.26,
          child: AnimatedBuilder(
            animation: _mouthAnimation,
            builder: (context, child) {
              double height = 4.0;
              if (widget.state == AvatarAnimState.talking) {
                height = _mouthAnimation.value;
              } else if (widget.state == AvatarAnimState.happy) {
                height = 8.0;
              }
              return Container(
                width: size * 0.22,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade100,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEye(double parentSize) {
    if (widget.state == AvatarAnimState.happy) {
      return Container(
        width: parentSize * 0.08,
        height: parentSize * 0.04,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      );
    }

    return Container(
      width: parentSize * 0.07,
      height: parentSize * 0.07,
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }
}
