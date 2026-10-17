class DefaultTopicItem {
  final String id;
  final String name;
  final String icon;

  const DefaultTopicItem({required this.id, required this.name, required this.icon});
}

class DefaultTopics {
  static const List<DefaultTopicItem> list = [
    DefaultTopicItem(id: 'career', name: 'Career', icon: '💼'),
    DefaultTopicItem(id: 'fitness', name: 'Fitness', icon: '🏋️'),
    DefaultTopicItem(id: 'studies', name: 'Studies', icon: '📚'),
    DefaultTopicItem(id: 'tech', name: 'Tech', icon: '💻'),
    DefaultTopicItem(id: 'finance', name: 'Finance', icon: '💰'),
    DefaultTopicItem(id: 'mental_wellness', name: 'Mental wellness', icon: '🧘'),
    DefaultTopicItem(id: 'movies', name: 'Movies', icon: '🎬'),
    DefaultTopicItem(id: 'cooking', name: 'Cooking', icon: '🍳'),
    DefaultTopicItem(id: 'travel', name: 'Travel', icon: '✈️'),
  ];
}
