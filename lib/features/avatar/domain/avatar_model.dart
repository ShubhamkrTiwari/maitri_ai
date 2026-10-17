class AvatarModel {
  final String id;
  final String userId;
  final String name;
  final String style; // e.g. 'bot', 'friendly', 'cute', 'minimal'
  final String hair; // e.g. 'short', 'long', 'curly', 'bald'
  final String outfit; // e.g. 'casual', 'formal', 'sporty'
  final String skinColorHex;
  final String hairColorHex;
  final String outfitColorHex;
  final String voiceType;
  final double voicePitch;
  final double voiceSpeed;
  final String personality; // 'friendly', 'funny', 'calm', 'motivating', 'professional'
  final String? customImageUrl;

  AvatarModel({
    required this.id,
    required this.userId,
    required this.name,
    this.style = 'friendly',
    this.hair = 'short',
    this.outfit = 'casual',
    this.skinColorHex = '#FFD1DC',
    this.hairColorHex = '#2D3436',
    this.outfitColorHex = '#6C5CE7',
    this.voiceType = 'en-US-Standard',
    this.voicePitch = 1.0,
    this.voiceSpeed = 1.0,
    this.personality = 'friendly',
    this.customImageUrl,
  });

  factory AvatarModel.fromJson(Map<String, dynamic> json) {
    return AvatarModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Maitri',
      style: json['style'] as String? ?? 'friendly',
      hair: json['hair'] as String? ?? 'short',
      outfit: json['outfit'] as String? ?? 'casual',
      skinColorHex: json['skin_color_hex'] as String? ?? '#FFD1DC',
      hairColorHex: json['hair_color_hex'] as String? ?? '#2D3436',
      outfitColorHex: json['outfit_color_hex'] as String? ?? '#6C5CE7',
      voiceType: json['voice_type'] as String? ?? 'en-US-Standard',
      voicePitch: (json['voice_pitch'] as num?)?.toDouble() ?? 1.0,
      voiceSpeed: (json['voice_speed'] as num?)?.toDouble() ?? 1.0,
      personality: json['personality'] as String? ?? 'friendly',
      customImageUrl: json['custom_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'style': style,
      'hair': hair,
      'outfit': outfit,
      'skin_color_hex': skinColorHex,
      'hair_color_hex': hairColorHex,
      'outfit_color_hex': outfitColorHex,
      'voice_type': voiceType,
      'voice_pitch': voicePitch,
      'voice_speed': voiceSpeed,
      'personality': personality,
      'custom_image_url': customImageUrl,
    };
  }

  AvatarModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? style,
    String? hair,
    String? outfit,
    String? skinColorHex,
    String? hairColorHex,
    String? outfitColorHex,
    String? voiceType,
    double? voicePitch,
    double? voiceSpeed,
    String? personality,
    String? customImageUrl,
  }) {
    return AvatarModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      style: style ?? this.style,
      hair: hair ?? this.hair,
      outfit: outfit ?? this.outfit,
      skinColorHex: skinColorHex ?? this.skinColorHex,
      hairColorHex: hairColorHex ?? this.hairColorHex,
      outfitColorHex: outfitColorHex ?? this.outfitColorHex,
      voiceType: voiceType ?? this.voiceType,
      voicePitch: voicePitch ?? this.voicePitch,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      personality: personality ?? this.personality,
      customImageUrl: customImageUrl ?? this.customImageUrl,
    );
  }
}
