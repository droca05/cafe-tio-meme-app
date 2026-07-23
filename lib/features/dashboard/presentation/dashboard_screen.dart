import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';

// Placeholder mínimo — la implementación completa (sección 7.2 del CLAUDE.md:
// stats, chips de filtro, lista en tiempo real, FAB) se hace en un paso posterior.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Café Tío Meme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      backgroundColor: AppColors.cream,
      body: const Center(
        child: Text('Dashboard'),
      ),
    );
  }
}
