import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/memory_controller.dart';

class MemoryManagerScreen extends ConsumerStatefulWidget {
  const MemoryManagerScreen({super.key});

  @override
  ConsumerState<MemoryManagerScreen> createState() => _MemoryManagerScreenState();
}

class _MemoryManagerScreenState extends ConsumerState<MemoryManagerScreen> {
  final TextEditingController _addMemoryController = TextEditingController();

  @override
  void dispose() {
    _addMemoryController.dispose();
    super.dispose();
  }

  void _showAddMemoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Fact / Memory'),
        content: TextField(
          controller: _addMemoryController,
          decoration: const InputDecoration(
            hintText: 'e.g. User prefers vegetarian recipes and loves football.',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _addMemoryController.text.trim();
              if (text.isNotEmpty) {
                ref.read(memoryControllerProvider.notifier).addMemory(text);
                _addMemoryController.clear();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String id, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Memory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Memory statement'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                ref.read(memoryControllerProvider.notifier).updateMemory(id, text);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Memories?'),
        content: const Text('This will delete all long-term facts stored about you. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(memoryControllerProvider.notifier).clearAllMemories();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoryState = ref.watch(memoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Long-Term Memory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: memoryState.memories.isEmpty ? null : _confirmClearAll,
            tooltip: 'Clear All Memories',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemoryDialog,
        backgroundColor: AppColors.primaryLight,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: memoryState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : memoryState.memories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 70, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No Memories Saved Yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Your AI companion automatically learns key facts about you during conversations, or you can manually add them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddMemoryDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Fact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: memoryState.memories.length,
                    itemBuilder: (context, index) {
                      final memory = memoryState.memories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondaryLight,
                            child: Icon(Icons.lightbulb_outline_rounded, color: Colors.white),
                          ),
                          title: Text(
                            memory.content,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'Saved ${memory.createdAt.day}/${memory.createdAt.month}/${memory.createdAt.year}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showEditDialog(memory.id, memory.content),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                onPressed: () {
                                  ref
                                      .read(memoryControllerProvider.notifier)
                                      .deleteMemory(memory.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
