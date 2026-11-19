import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';
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
                'The database lives in Documents/dev.loner.shared_database/ on this device. '
                'Free storage space, then tap Retry.',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.read<ShopCubit>().initialize(),
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