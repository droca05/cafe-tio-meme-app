import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

class DashboardStats {
  final int activasHoy;
  final int pendientesHoy;
  final int entregadasHoy;

  const DashboardStats({
    required this.activasHoy,
    required this.pendientesHoy,
    required this.entregadasHoy,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final solicitudes = ref.watch(solicitudesStreamProvider).value ?? [];

  final ahora = DateTime.now();
  bool esHoy(DateTime fecha) =>
      fecha.year == ahora.year &&
      fecha.month == ahora.month &&
      fecha.day == ahora.day;

  final deHoy = solicitudes.where((s) => esHoy(s.fechaCreacion)).toList();

  return DashboardStats(
    activasHoy: deHoy.length,
    pendientesHoy: deHoy
        .where((s) => s.estadoPedido == EstadoPedido.pendiente)
        .length,
    entregadasHoy: deHoy
        .where((s) => s.estadoPedido == EstadoPedido.entregado)
        .length,
  );
});
