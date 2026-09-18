import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../models/model_type.dart';
import '../models/collection_bag.dart';
import '../models/bag_configuration.dart';
import '../providers/app_providers.dart';
import '../services/supabase_service.dart';
import '../widgets/index.dart';
import '../widgets/app_drawer.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Configuration'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: theme.primaryColor.withOpacity(0.1), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Regions', icon: Icon(Icons.location_on_rounded, size: 18)),
                Tab(text: 'Types', icon: Icon(Icons.category_rounded, size: 18)),
                Tab(text: 'Bags', icon: Icon(Icons.inventory_2_rounded, size: 18)),
                Tab(text: 'Config', icon: Icon(Icons.settings_rounded, size: 18)),
              ],
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RegionsTab(),
          _ModelsTab(),
          _BagsTab(),
          _ConfigurationsTab(),
        ],
      ),
    );
  }
}

// ============================================
// REGIONS TAB
// ============================================

class _RegionsTab extends ConsumerStatefulWidget {
  const _RegionsTab();

  @override
  ConsumerState<_RegionsTab> createState() => _RegionsTabState();
}

class _RegionsTabState extends ConsumerState<_RegionsTab> {
  final _nameController = TextEditingController();
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

    final service = ref.read(supabaseServiceProvider);

    try {
      if (_editingId != null) {
        await service.updateRegion(
          id: _editingId!,
          name: _nameController.text.trim(),
        );
      } else {
        await service.createRegion(name: _nameController.text.trim());
      }
      _nameController.clear();
      setState(() => _editingId = null);
      ref.invalidate(regionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _edit(Region region) {
    _nameController.text = region.name;
    setState(() => _editingId = region.id);
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Region?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      await service.deleteRegion(id);
      ref.invalidate(regionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Region Name',
                    hintText: 'Enter region name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_editingId != null ? 'Update' : 'Add'),
                ),
            ],
          ),
        ),
        Expanded(
          child: regionsAsync.when(
            data: (regions) {
              if (regions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No regions found',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        region.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
                            onPressed: () => _edit(region),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                            onPressed: () => _delete(region.id),
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
    );
  }
}

// ============================================
// MODELS TAB
// ============================================

class _ModelsTab extends ConsumerStatefulWidget {
  const _ModelsTab();

  @override
  ConsumerState<_ModelsTab> createState() => _ModelsTabState();
}

class _ModelsTabState extends ConsumerState<_ModelsTab> {
  final _nameController = TextEditingController();
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

    final service = ref.read(supabaseServiceProvider);

    try {
      if (_editingId != null) {
        await service.updateModel(
          id: _editingId!,
          name: _nameController.text.trim(),
        );
      } else {
        await service.createModel(name: _nameController.text.trim());
      }
      _nameController.clear();
      setState(() => _editingId = null);
      ref.invalidate(modelsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _edit(ModelType model) {
    _nameController.text = model.name;
    setState(() => _editingId = model.id);
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      await service.deleteModel(id);
      ref.invalidate(modelsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(modelsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Model Name',
                    hintText: 'Enter model name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_editingId != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: modelsAsync.when(
            data: (models) {
              if (models.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No models found',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        model.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
                            onPressed: () => _edit(model),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                            onPressed: () => _delete(model.id),
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
    );
  }
}

// ============================================
// BAGS TAB
// ============================================

class _BagsTab extends ConsumerStatefulWidget {
  const _BagsTab();

  @override
  ConsumerState<_BagsTab> createState() => _BagsTabState();
}

class _BagsTabState extends ConsumerState<_BagsTab> {
  final _nameController = TextEditingController();
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

    final service = ref.read(supabaseServiceProvider);

    try {
      if (_editingId != null) {
        await service.updateCollectionBag(
          id: _editingId!,
          name: _nameController.text.trim(),
        );
      } else {
        await service.createCollectionBag(name: _nameController.text.trim());
      }
      _nameController.clear();
      setState(() => _editingId = null);
      ref.invalidate(collectionBagsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _edit(CollectionBag bag) {
    _nameController.text = bag.name;
    setState(() => _editingId = bag.id);
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection Bag?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bagsAsync = ref.watch(collectionBagsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bag Name',
                    hintText: 'Enter bag name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_editingId != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: bagsAsync.when(
            data: (bags) {
              if (bags.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No collection bags found',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: bags.length,
                itemBuilder: (context, index) {
                  final bag = bags[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          bag.name.split(' ').last,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(
                        bag.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
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
    );
  }
}

// ============================================
// CONFIGURATIONS TAB
// ============================================

class _ConfigurationsTab extends ConsumerStatefulWidget {
  const _ConfigurationsTab();

  @override
  ConsumerState<_ConfigurationsTab> createState() => _ConfigurationsTabState();
}

class _ConfigurationsTabState extends ConsumerState<_ConfigurationsTab> {
  String? _selectedRegionId;
  String? _selectedModelId;
  String? _selectedBagId;
  final _frequencyController = TextEditingController();
  String _frequencyType = 'weekly';
  final List<int> _selectedDays = [0, 3]; // Default Sunday and Wednesday
  final _monthlyRuleController = TextEditingController();
  final _expectedAmountController = TextEditingController();
  final _sundayAmountController = TextEditingController();
  final _mondayAmountController = TextEditingController();
  final _tuesdayAmountController = TextEditingController();
  final _wednesdayAmountController = TextEditingController();
  final _thursdayAmountController = TextEditingController();
  final _fridayAmountController = TextEditingController();
  final _saturdayAmountController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime(2099, 12, 31);

  @override
  void dispose() {
    _frequencyController.dispose();
    _monthlyRuleController.dispose();
    _expectedAmountController.dispose();
    _sundayAmountController.dispose();
    _mondayAmountController.dispose();
    _tuesdayAmountController.dispose();
    _wednesdayAmountController.dispose();
    _thursdayAmountController.dispose();
    _fridayAmountController.dispose();
    _saturdayAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRegionId == null ||
        _selectedModelId == null ||
        _selectedBagId == null ||
        _frequencyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final service = ref.read(supabaseServiceProvider);

    try {
      await service.createBagConfiguration(
        regionId: _selectedRegionId!,
        modelId: _selectedModelId!,
        bagId: _selectedBagId!,
        frequency: _frequencyController.text.trim(),
        frequencyType: _frequencyType,
        daysOfWeek: _selectedDays,
        monthlyRule: _monthlyRuleController.text.trim(),
        expectedAmount: double.tryParse(_expectedAmountController.text.trim()) ?? 0.0,
        sundayAmount: double.tryParse(_sundayAmountController.text.trim()) ?? 0.0,
        mondayAmount: double.tryParse(_mondayAmountController.text.trim()) ?? 0.0,
        tuesdayAmount: double.tryParse(_tuesdayAmountController.text.trim()) ?? 0.0,
        wednesdayAmount: double.tryParse(_wednesdayAmountController.text.trim()) ?? 0.0,
        thursdayAmount: double.tryParse(_thursdayAmountController.text.trim()) ?? 0.0,
        fridayAmount: double.tryParse(_fridayAmountController.text.trim()) ?? 0.0,
        saturdayAmount: double.tryParse(_saturdayAmountController.text.trim()) ?? 0.0,
        startDate: _startDate,
        endDate: _endDate,
      );

      _frequencyController.clear();
      _monthlyRuleController.clear();
      _expectedAmountController.clear();
      _sundayAmountController.clear();
      _mondayAmountController.clear();
      _tuesdayAmountController.clear();
      _wednesdayAmountController.clear();
      _thursdayAmountController.clear();
      _fridayAmountController.clear();
      _saturdayAmountController.clear();
      setState(() {
        _selectedRegionId = null;
        _selectedModelId = null;
        _selectedBagId = null;
        _frequencyType = 'weekly';
        _selectedDays.clear();
        _startDate = DateTime.now();
        _endDate = DateTime(2099, 12, 31);
      });
      ref.invalidate(bagConfigurationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      await service.deleteBagConfiguration(id);
      ref.invalidate(bagConfigurationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(regionsProvider);
    final modelsAsync = ref.watch(modelsProvider);
    final bagsAsync = ref.watch(collectionBagsProvider);
    final configsAsync = ref.watch(bagConfigurationsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  regionsAsync.when(
                    data: (regions) {
                      return CustomDropdownField(
                        label: 'Region',
                        hint: 'Select region',
                        value: _selectedRegionId != null
                            ? regions
                                .firstWhere(
                                  (r) => r.id == _selectedRegionId,
                                  orElse: () => regions.first,
                                )
                                .name
                            : null,
                        items: regions.map((r) => r.name).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final region = regions.firstWhere(
                            (r) => r.name == value,
                            orElse: () => regions.first,
                          );
                          setState(() => _selectedRegionId = region.id);
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 48),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 12),
                  modelsAsync.when(
                    data: (models) {
                      return CustomDropdownField(
                        label: 'Type / Model',
                        hint: 'Select model',
                        value: _selectedModelId != null
                            ? models
                                .firstWhere(
                                  (m) => m.id == _selectedModelId,
                                  orElse: () => models.first,
                                )
                                .name
                            : null,
                        items: models.map((m) => m.name).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final model = models.firstWhere(
                            (m) => m.name == value,
                            orElse: () => models.first,
                          );
                          setState(() => _selectedModelId = model.id);
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 48),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 12),
                  bagsAsync.when(
                    data: (bags) {
                      return CustomDropdownField(
                        label: 'Collection Bag',
                        hint: 'Select bag',
                        value: _selectedBagId != null
                            ? bags
                                .firstWhere(
                                  (b) => b.id == _selectedBagId,
                                  orElse: () => bags.first,
                                )
                                .name
                            : null,
                        items: bags.map((b) => b.name).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final bag = bags.firstWhere(
                            (b) => b.name == value,
                            orElse: () => bags.first,
                          );
                          setState(() => _selectedBagId = bag.id);
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(minHeight: 48),
                    error: (e, _) => Text('Error: $e'),
                  ),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _frequencyController,
                     decoration: const InputDecoration(
                       labelText: 'Frequency Label',
                       hintText: 'e.g., Sunday + Wednesday',
                       border: OutlineInputBorder(),
                     ),
                   ),
                   const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                     value: _frequencyType,
                     decoration: const InputDecoration(
                       labelText: 'Frequency Type',
                       border: OutlineInputBorder(),
                     ),
                     items: const [
                       DropdownMenuItem(value: 'daily', child: Text('Daily')),
                       DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                       DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                     ],
                     onChanged: (value) {
                       if (value != null) {
                         setState(() => _frequencyType = value);
                       }
                     },
                   ),
                   const SizedBox(height: 12),
                   if (_frequencyType == 'weekly') ...[
                     const Text('Days of Week', style: TextStyle(fontWeight: FontWeight.w500)),
                     const SizedBox(height: 8),
                     Wrap(
                       spacing: 8,
                       children: [
                         _DayChip(label: 'Sun', day: 0, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Mon', day: 1, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Tue', day: 2, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Wed', day: 3, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Thu', day: 4, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Fri', day: 5, selectedDays: _selectedDays, onChanged: _onDayToggled),
                         _DayChip(label: 'Sat', day: 6, selectedDays: _selectedDays, onChanged: _onDayToggled),
                       ],
                     ),
                     const SizedBox(height: 12),
                   ],
                   if (_frequencyType == 'monthly') ...[
                     TextField(
                       controller: _monthlyRuleController,
                       decoration: const InputDecoration(
                         labelText: 'Monthly Rule',
                         hintText: 'e.g., 1st and 15th',
                         border: OutlineInputBorder(),
                       ),
                     ),
                     const SizedBox(height: 12),
                   ],
                   TextField(
                     controller: _expectedAmountController,
                     decoration: const InputDecoration(
                       labelText: 'Expected Amount',
                       hintText: 'Default expected amount',
                       border: OutlineInputBorder(),
                     ),
                     keyboardType: TextInputType.number,
                   ),
                   const SizedBox(height: 12),
                   const Text('Per-Day Amounts', style: TextStyle(fontWeight: FontWeight.w500)),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(child: _AmountField(controller: _sundayAmountController, label: 'Sun')),
                       const SizedBox(width: 8),
                       Expanded(child: _AmountField(controller: _mondayAmountController, label: 'Mon')),
                       const SizedBox(width: 8),
                       Expanded(child: _AmountField(controller: _tuesdayAmountController, label: 'Tue')),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(child: _AmountField(controller: _wednesdayAmountController, label: 'Wed')),
                       const SizedBox(width: 8),
                       Expanded(child: _AmountField(controller: _thursdayAmountController, label: 'Thu')),
                       const SizedBox(width: 8),
                       Expanded(child: _AmountField(controller: _fridayAmountController, label: 'Fri')),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(child: _AmountField(controller: _saturdayAmountController, label: 'Sat')),
                     ],
                   ),
                   const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Add Configuration'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: configsAsync.when(
            data: (configs) {
              if (configs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No configurations found',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        '${config.entity} - ${config.frequency}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Region: ${config.regionId} | Model: ${config.modelId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                       trailing: IconButton(
                         icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                         onPressed: () => _delete(config.id),
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
     );
   }

  void _onDayToggled(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }
}

// ============================================
// HELPER WIDGETS FOR CONFIGURATIONS TAB
// ============================================

class _DayChip extends StatelessWidget {
  final String label;
  final int day;
  final List<int> selectedDays;
  final ValueChanged<int> onChanged;

  const _DayChip({
    required this.label,
    required this.day,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedDays.contains(day);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onChanged(day),
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _AmountField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
