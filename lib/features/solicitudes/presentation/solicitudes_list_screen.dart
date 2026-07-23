import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../../../shared/widgets/estado_pedido_badge.dart';
import '../providers/solicitudes_providers.dart';

// Placeholder mínimo — lista filtrable completa; el dashboard ya cubre
// la vista principal en tiempo real con estadísticas.
class SolicitudesListScreen extends ConsumerWidget {
  const SolicitudesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudesAsync = ref.watch(solicitudesFiltradasProvider);
    final filtro = ref.watch(filtroSolicitudProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Solicitudes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in const {
                    FiltroSolicitud.todas: 'Todas',
                    FiltroSolicitud.ventaDirecta: 'Directa',
                    FiltroSolicitud.forza: 'FORZA',
                    FiltroSolicitud.pendiente: 'Pendiente',
                    FiltroSolicitud.entregado: 'Entregado',
                  }.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: filtro == entry.key,
                        onSelected: (_) {
                          ref.read(filtroSolicitudProvider.notifier).state =
                              entry.key;
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: solicitudesAsync.when(
              data: (solicitudes) {
                if (solicitudes.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay solicitudes aún',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () =>
                            context.push('/solicitudes/${solicitud.id}'),
                        title: Text(
                          solicitud.clienteNombre,
                          style: AppTextStyles.bodyMedium500,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                CanalBadge(canal: solicitud.canal),
                                const SizedBox(width: 8),
                                EstadoPedidoBadge(
                                  estadoPedido: solicitud.estadoPedido,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formatFechaHora(solicitud.fechaCreacion)),
                          ],
                        ),
                        trailing: Text(
                          'Q${solicitud.total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium500,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Ocurrió un error al cargar las solicitudes.',
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
