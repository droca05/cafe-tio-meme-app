import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../../../shared/widgets/estado_solicitud_icon.dart';
import '../../auth/providers/auth_providers.dart';
import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/solicitud_model.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';
import '../providers/dashboard_providers.dart';

void _toggleEstado(
  WidgetRef ref,
  Set<EstadoSolicitud> actuales,
  EstadoSolicitud estado,
) {
  final nuevo = Set<EstadoSolicitud>.from(actuales);
  if (!nuevo.remove(estado)) {
    nuevo.add(estado);
  }
  ref.read(estadosFiltroProvider.notifier).state = nuevo;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _iniciales(String? email) {
    if (email == null || email.isEmpty) return '?';
    final local = email.split('@').first;
    if (local.length < 2) return local.toUpperCase();
    return local.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    final esAdmin = PermissionHelper.isAdmin(user?.email);
    final stats = ref.watch(dashboardStatsProvider);
    final solicitudesAsync = ref.watch(solicitudesFiltradasProvider);
    final canalFiltro = ref.watch(canalFiltroProvider);
    final estadosFiltro = ref.watch(estadosFiltroProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Café Tío Meme'),
        actions: [
          if (esAdmin)
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => context.push('/productos'),
            ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => context.push('/exportar'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/kpis'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: AppColors.latte,
              child: Text(
                _iniciales(user?.email),
                style: AppTextStyles.bodyMedium500.copyWith(
                  color: AppColors.roast,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Ventas hoy',
                        value: '${stats.ventasHoy}',
                        color: AppColors.espresso,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'Revisar',
                        value: '${stats.revisarTotal}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Verificado',
                        value: '${stats.verificadoTotal}',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'No pagado',
                        value: '${stats.noPagadoTotal}',
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.cream,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FiltroChip(
                        label: 'Todas',
                        isSelected: canalFiltro == CanalFiltro.todas,
                        onTap: () => ref
                            .read(canalFiltroProvider.notifier)
                            .state = CanalFiltro.todas,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'Directa',
                        isSelected: canalFiltro == CanalFiltro.ventaDirecta,
                        onTap: () => ref
                            .read(canalFiltroProvider.notifier)
                            .state = CanalFiltro.ventaDirecta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'FORZA',
                        isSelected: canalFiltro == CanalFiltro.forza,
                        onTap: () => ref
                            .read(canalFiltroProvider.notifier)
                            .state = CanalFiltro.forza,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FiltroChip(
                        label: 'Revisar',
                        icono: Icons.warning_amber_rounded,
                        isSelected:
                            estadosFiltro.contains(EstadoSolicitud.revisar),
                        onTap: () => _toggleEstado(
                          ref,
                          estadosFiltro,
                          EstadoSolicitud.revisar,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'Verificado',
                        icono: Icons.check_circle_rounded,
                        isSelected:
                            estadosFiltro.contains(EstadoSolicitud.verificado),
                        onTap: () => _toggleEstado(
                          ref,
                          estadosFiltro,
                          EstadoSolicitud.verificado,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'No pagado',
                        icono: Icons.cancel_rounded,
                        isSelected:
                            estadosFiltro.contains(EstadoSolicitud.noPagado),
                        onTap: () => _toggleEstado(
                          ref,
                          estadosFiltro,
                          EstadoSolicitud.noPagado,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index];
                    return _SolicitudCard(
                      solicitud: solicitud,
                      puedeEditarEstado: esAdmin,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              // El reintento automático (ref.listen más arriba) crea una
              // nueva suscripción; mientras tanto se muestra el mismo
              // estado vacío que cuando no hay solicitudes.
              error: (error, stackTrace) => Center(
                child: Text(
                  'No hay solicitudes aún',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/solicitudes/nueva'),
        backgroundColor: AppColors.caramel,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Solicitud'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLight.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icono;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : AppColors.espresso;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.caramel : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.steam, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 15, color: color),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoSolicitudMenu extends ConsumerWidget {
  final Solicitud solicitud;
  final bool puedeEditar;

  const _EstadoSolicitudMenu({
    required this.solicitud,
    required this.puedeEditar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icono, color) = estadoSolicitudIconoColor(solicitud.estadoSolicitud);

    if (!puedeEditar) {
      return Icon(icono, color: color, size: 20);
    }

    return PopupMenuButton<EstadoSolicitud>(
      icon: Icon(icono, color: color, size: 20),
      padding: const EdgeInsets.all(8),
      tooltip: 'Cambiar estado',
      onSelected: (estado) {
        ref
            .read(solicitudesRepositoryProvider)
            .actualizarEstadoSolicitud(solicitud.id, estado);
      },
      itemBuilder: (context) => EstadoSolicitud.values.map((estado) {
        final (itemIcono, itemColor) = estadoSolicitudIconoColor(estado);
        return PopupMenuItem(
          value: estado,
          child: Row(
            children: [
              Icon(itemIcono, color: itemColor, size: 20),
              const SizedBox(width: 8),
              Text(estadoSolicitudNombre(estado)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

String _resumenProductos(List<ProductoItem> productos) {
  final items = productos.map((p) => '${p.nombre} x${p.cantidad}').toList();
  if (items.length > 2) {
    return '${items.take(2).join(', ')}...';
  }
  return items.join(', ');
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;
  final bool puedeEditarEstado;

  const _SolicitudCard({
    required this.solicitud,
    required this.puedeEditarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final tieneNota = solicitud.notas != null && solicitud.notas!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/solicitudes/${solicitud.id}'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    height: 20,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: CanalBadge(canal: solicitud.canal),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: _EstadoSolicitudMenu(
                      solicitud: solicitud,
                      puedeEditar: puedeEditarEstado,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                solicitud.clienteNombre,
                style: AppTextStyles.bodyMedium500.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                _resumenProductos(solicitud.productos),
                style: AppTextStyles.bodyLight.copyWith(
                  fontSize: 12,
                  color: AppColors.latte,
                ),
              ),
              if (tieneNota) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.caramel,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Nota',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                formatFecha(solicitud.fechaCreacion),
                style: AppTextStyles.bodyLight.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                'Q${solicitud.total.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.caramel,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
