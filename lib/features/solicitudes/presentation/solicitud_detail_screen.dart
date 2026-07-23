import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';
import '../providers/solicitudes_providers.dart';

class SolicitudDetailScreen extends ConsumerWidget {
  final String solicitudId;

  const SolicitudDetailScreen({super.key, required this.solicitudId});

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar solicitud'),
        content: const Text(
          '¿Estás seguro que deseas eliminar esta solicitud? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.espresso),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await ref.read(solicitudesRepositoryProvider).eliminarSolicitud(solicitudId);

    if (context.mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solicitudAsync = ref.watch(solicitudStreamProvider(solicitudId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/solicitudes/$solicitudId/editar'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmarEliminar(context, ref),
          ),
        ],
      ),
      body: solicitudAsync.when(
        data: (solicitud) => _SolicitudDetailBody(solicitud: solicitud),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'No se pudo cargar la solicitud.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}

String _nombreUsuario(String creadoPor) {
  if (creadoPor.isEmpty) return '—';
  return creadoPor.split('@').first;
}

class _SolicitudDetailBody extends ConsumerWidget {
  final Solicitud solicitud;

  const _SolicitudDetailBody({required this.solicitud});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CanalBadge(canal: solicitud.canal),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/clientes/${solicitud.clienteId}'),
            child: Text(
              solicitud.clienteNombre,
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.caramel,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Creado el ${formatFechaHora(solicitud.fechaCreacion)}',
            style: AppTextStyles.bodyLight,
          ),
          Text(
            'Solicitud creada por: ${_nombreUsuario(solicitud.creadoPor)}',
            style: AppTextStyles.bodyLight,
          ),
          const SizedBox(height: 24),
          Text('Productos', style: AppTextStyles.bodyMedium500),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.foam,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steam),
            ),
            child: Column(
              children: [
                for (final producto in solicitud.productos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              producto.nombre,
                              if (producto.presentacion != null)
                                producto.presentacion ==
                                        PresentacionCafe.grano
                                    ? 'Grano'
                                    : 'Molido',
                              'x${producto.cantidad}',
                            ].join(' · '),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          'Q${producto.subtotal.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium500,
                        ),
                      ],
                    ),
                  ),
                const Divider(color: AppColors.steam),
                Row(
                  children: [
                    const Expanded(child: Text('Total')),
                    Text(
                      'Q${solicitud.total.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium500.copyWith(
                        color: AppColors.caramel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (solicitud.notas != null && solicitud.notas!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Notas', style: AppTextStyles.bodyMedium500),
            const SizedBox(height: 8),
            Text(solicitud.notas!, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: 24),
          Text('Estado del pedido', style: AppTextStyles.bodyMedium500),
          const SizedBox(height: 8),
          _EstadoPedidoSelector(
            estadoActual: solicitud.estadoPedido,
            onChanged: (estado) async {
              try {
                await ref
                    .read(solicitudesRepositoryProvider)
                    .actualizarEstadoPedido(solicitud.id, estado);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo actualizar el estado: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EstadoPedidoSelector extends StatelessWidget {
  final EstadoPedido estadoActual;
  final ValueChanged<EstadoPedido> onChanged;

  const _EstadoPedidoSelector({
    required this.estadoActual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EstadoPedidoBoton(
            label: 'Pendiente',
            seleccionado: estadoActual == EstadoPedido.pendiente,
            onTap: () => onChanged(EstadoPedido.pendiente),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EstadoPedidoBoton(
            label: 'Entregado',
            seleccionado: estadoActual == EstadoPedido.entregado,
            onTap: () => onChanged(EstadoPedido.entregado),
          ),
        ),
      ],
    );
  }
}

class _EstadoPedidoBoton extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _EstadoPedidoBoton({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.caramel : AppColors.steam,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium500.copyWith(
            color: seleccionado ? Colors.white : AppColors.espresso,
          ),
        ),
      ),
    );
  }
}
