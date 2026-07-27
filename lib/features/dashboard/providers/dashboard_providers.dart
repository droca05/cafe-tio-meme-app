import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

class DashboardStats {
  final int ventasHoy;
  final int revisarTotal;
  final int verificadoTotal;
  final int noPagadoTotal;

  const DashboardStats({
    required this.ventasHoy,
    required this.revisarTotal,
    required this.verificadoTotal,
    required this.noPagadoTotal,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final solicitudes = ref.watch(solicitudesStreamProvider).value ?? [];

  final ahora = DateTime.now();
  bool esHoy(DateTime fecha) =>
      fecha.year == ahora.year &&
      fecha.month == ahora.month &&
      fecha.day == ahora.day;

  final deHoy = solicitudes.where((s) => esHoy(s.fechaCreacion)).length;

  return DashboardStats(
    ventasHoy: deHoy,
    revisarTotal: solicitudes
        .where((s) => s.estadoSolicitud == EstadoSolicitud.revisar)
        .length,
    verificadoTotal: solicitudes
        .where((s) => s.estadoSolicitud == EstadoSolicitud.verificado)
        .length,
    noPagadoTotal: solicitudes
        .where((s) => s.estadoSolicitud == EstadoSolicitud.noPagado)
        .length,
  );
});
