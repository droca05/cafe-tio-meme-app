import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';
import '../providers/clientes_providers.dart';

class ClientesListScreen extends ConsumerStatefulWidget {
  const ClientesListScreen({super.key});

  @override
  ConsumerState<ClientesListScreen> createState() =>
      _ClientesListScreenState();
}

class _ClientesListScreenState extends ConsumerState<ClientesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(busquedaClienteProvider.notifier).state = '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesBuscadosProvider);
    final solicitudesAsync = ref.watch(solicitudesStreamProvider);

    final conteoSolicitudes = <String, int>{};
    solicitudesAsync.whenData((solicitudes) {
      for (final solicitud in solicitudes) {
        conteoSolicitudes[solicitud.clienteId] =
            (conteoSolicitudes[solicitud.clienteId] ?? 0) + 1;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Clientes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o teléfono',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(busquedaClienteProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: clientesAsync.when(
              data: (clientes) {
                final ordenados = [...clientes]..sort(
                    (a, b) => a.nombre.toLowerCase().compareTo(
                          b.nombre.toLowerCase(),
                        ),
                  );

                if (ordenados.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay clientes aún',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ordenados.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.steam),
                  itemBuilder: (context, index) {
                    final cliente = ordenados[index];
                    final cantidad = conteoSolicitudes[cliente.id] ?? 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        cliente.nombre,
                        style: AppTextStyles.bodyMedium500,
                      ),
                      subtitle: Text(
                        cliente.telefono,
                        style: AppTextStyles.bodyLight,
                      ),
                      trailing: Text(
                        '$cantidad pedido${cantidad == 1 ? '' : 's'}',
                        style: AppTextStyles.bodyLight,
                      ),
                      onTap: () => context.push('/clientes/${cliente.id}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Ocurrió un error al cargar los clientes.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
