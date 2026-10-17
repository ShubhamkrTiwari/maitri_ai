class TopicModel {
  final String id;
  final String name;
  final String? customName;
  final bool isSelected;

  TopicModel({
    required this.id,
    required this.name,
    this.customName,
    this.isSelected = false,
  });

  TopicModel copyWith({
    String? id,
    String? name,
    String? customName,
    bool? isSelected,
  }) {
    return TopicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      customName: customName ?? this.customName,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      customName: json['custom_topic_name'] as String?,
      isSelected: true,
    );
  }
}
