import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:microfinance_app/models/collection_bag.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

class BagsScreen extends ConsumerStatefulWidget {
  const BagsScreen({super.key});

  @override
  ConsumerState<BagsScreen> createState() => _BagsScreenState();
}

class _BagsScreenState extends ConsumerState<BagsScreen> {
  final _controller = TextEditingController();

  Future<void> _add() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter bag name'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    final service = ref.read(supabaseServiceProvider);
    try {
      await service.createCollectionBag(name: name);
      _controller.clear();
      ref.invalidate(collectionBagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bag added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bag: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bag?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final service = ref.read(supabaseServiceProvider);
    try {
      await service.deleteCollectionBag(id);
      ref.invalidate(collectionBagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bag deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting bag: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _edit(CollectionBag bag) async {
    final controller = TextEditingController(text: bag.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bag Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Bag Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final name = controller.text.trim();
    if (name.isEmpty || name == bag.name) return;
    final service = ref.read(supabaseServiceProvider);
    try {
      await service.updateCollectionBag(id: bag.id, name: name);
      ref.invalidate(collectionBagsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bag updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating bag: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bagsAsync = ref.watch(collectionBagsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Bags'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Bag Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: bagsAsync.when(
              data: (bags) {
                if (bags.isEmpty) {
                  return const Center(child: Text('No bags found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bags.length,
                  itemBuilder: (context, index) {
                    final bag = bags[index];
                      return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(bag.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                              onPressed: () => _edit(bag),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                              onPressed: () => _delete(bag.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
