import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../../../shared/widgets/estado_solicitud_icon.dart';
import '../../auth/providers/auth_providers.dart';
import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/solicitud_model.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';
import '../providers/dashboard_providers.dart';

const _emailAdmin = 'julioroca92@gmail.com';

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
    final esAdmin = user?.email == _emailAdmin;
    final stats = ref.watch(dashboardStatsProvider);
    final solicitudesAsync = ref.watch(solicitudesFiltradasProvider);
    final filtro = ref.watch(filtroSolicitudProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Café Tío Meme'),
        actions: [
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
                        value: '${stats.revisarHoy}',
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
                        value: '${stats.verificadoHoy}',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        label: 'No pagado',
                        value: '${stats.noPagadoHoy}',
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
                        filtro: FiltroSolicitud.todas,
                        seleccionado: filtro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'Directa',
                        filtro: FiltroSolicitud.ventaDirecta,
                        seleccionado: filtro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'FORZA',
                        filtro: FiltroSolicitud.forza,
                        seleccionado: filtro,
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
                        filtro: FiltroSolicitud.revisar,
                        seleccionado: filtro,
                        icono: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'Verificado',
                        filtro: FiltroSolicitud.verificado,
                        seleccionado: filtro,
                        icono: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FiltroChip(
                        label: 'No pagado',
                        filtro: FiltroSolicitud.noPagado,
                        seleccionado: filtro,
                        icono: Icons.cancel_rounded,
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
      height: 70,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTextStyles.displayMedium.copyWith(
                  color: color,
                  fontSize: 20,
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

class _FiltroChip extends ConsumerWidget {
  final String label;
  final FiltroSolicitud filtro;
  final FiltroSolicitud seleccionado;
  final IconData? icono;

  const _FiltroChip({
    required this.label,
    required this.filtro,
    required this.seleccionado,
    this.icono,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = filtro == seleccionado;
    final color = isSelected ? Colors.white : AppColors.espresso;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ref.read(filtroSolicitudProvider.notifier).state = filtro;
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.caramel : AppColors.foam,
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
                    height: 20,
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
