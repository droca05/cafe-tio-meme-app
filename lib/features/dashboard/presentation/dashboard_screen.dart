import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../../../shared/widgets/estado_pedido_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../../solicitudes/domain/solicitud_model.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';
import '../providers/dashboard_providers.dart';

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
    final stats = ref.watch(dashboardStatsProvider);
    final solicitudesAsync = ref.watch(solicitudesFiltradasProvider);
    final filtro = ref.watch(filtroSolicitudProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Café Tío Meme'),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Activas hoy',
                    value: '${stats.activasHoy}',
                    color: AppColors.espresso,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Pendientes',
                    value: '${stats.pendientesHoy}',
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Entregadas',
                    value: '${stats.entregadasHoy}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.cream,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _FiltroChip(
                  label: 'Todas',
                  filtro: FiltroSolicitud.todas,
                  seleccionado: filtro,
                ),
                _FiltroChip(
                  label: 'Directa',
                  filtro: FiltroSolicitud.ventaDirecta,
                  seleccionado: filtro,
                ),
                _FiltroChip(
                  label: 'FORZA',
                  filtro: FiltroSolicitud.forza,
                  seleccionado: filtro,
                ),
                _FiltroChip(
                  label: 'Pendiente',
                  filtro: FiltroSolicitud.pendiente,
                  seleccionado: filtro,
                ),
                _FiltroChip(
                  label: 'Entregado',
                  filtro: FiltroSolicitud.entregado,
                  seleccionado: filtro,
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
                    return _SolicitudCard(solicitud: solicitud);
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.displayMedium.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroChip extends ConsumerWidget {
  final String label;
  final FiltroSolicitud filtro;
  final FiltroSolicitud seleccionado;

  const _FiltroChip({
    required this.label,
    required this.filtro,
    required this.seleccionado,
  });

  static const double _width = 112;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = filtro == seleccionado;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        ref.read(filtroSolicitudProvider.notifier).state = filtro;
      },
      child: Container(
        width: _width,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.caramel : AppColors.foam,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.steam, width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.espresso,
          ),
        ),
      ),
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

String _nombreCreador(String creadoPor) {
  if (creadoPor.isEmpty) return '—';
  return creadoPor.split('@').first;
}

class _SolicitudCard extends StatelessWidget {
  final Solicitud solicitud;

  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/solicitudes/${solicitud.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CanalBadge(canal: solicitud.canal),
                  const SizedBox(width: 8),
                  EstadoPedidoBadge(estadoPedido: solicitud.estadoPedido),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                solicitud.clienteNombre,
                style: AppTextStyles.bodyMedium500,
              ),
              const SizedBox(height: 4),
              Text(
                _resumenProductos(solicitud.productos),
                style: AppTextStyles.bodyLight.copyWith(
                  fontSize: 12,
                  color: AppColors.latte,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Solicitud creada por: ${_nombreCreador(solicitud.creadoPor)}',
                style: AppTextStyles.bodyLight.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF9A8878),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatFecha(solicitud.fechaCreacion),
                style: AppTextStyles.bodyLight,
              ),
              const SizedBox(height: 8),
              Text(
                'Q${solicitud.total.toStringAsFixed(2)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.caramel,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
