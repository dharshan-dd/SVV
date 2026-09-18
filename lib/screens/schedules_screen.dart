import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:microfinance_app/models/bag_configuration.dart';
import 'package:microfinance_app/providers/app_providers.dart';
import 'package:microfinance_app/services/supabase_service.dart';
import 'package:microfinance_app/widgets/app_drawer.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configsAsync = ref.watch(bagConfigurationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      drawer: const AppDrawer(),
      body: configsAsync.when(
        data: (configs) {
          if (configs.isEmpty) {
            return const Center(child: Text('No schedules configured'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: configs.length,
            itemBuilder: (context, index) {
              final config = configs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('${config.entity} - ${config.frequency}'),
                  subtitle: Text(
                    'Bag: ${config.bagId} | Type: ${config.frequencyType} | Days: ${config.daysOfWeek.join(", ")}',
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
