import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:shared_database/shared_database.dart';

import '../../commands/initialize_command.dart';
import '../../ui/spacing.dart';

class DatabaseErrorView extends StatelessWidget {
  const DatabaseErrorView({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.storage_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Database not connected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Install the manager app (${SharedDatabase.instance.collectionsDetailed()}), '
                'open it once, then tap Retry.',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context(const InitializeCommand()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}