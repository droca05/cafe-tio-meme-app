import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

class DashboardStats {
  final int ventasHoy;
  final int revisarHoy;
  final int verificadoHoy;
  final int noPagadoHoy;

  const DashboardStats({
    required this.ventasHoy,
    required this.revisarHoy,
    required this.verificadoHoy,
    required this.noPagadoHoy,
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
    ventasHoy: deHoy.length,
    revisarHoy: deHoy
        .where((s) => s.estadoSolicitud == EstadoSolicitud.revisar)
        .length,
    verificadoHoy: deHoy
        .where((s) => s.estadoSolicitud == EstadoSolicitud.verificado)
        .length,
    noPagadoHoy: deHoy
        .where((s) => s.estadoSolicitud == EstadoSolicitud.noPagado)
        .length,
  );
});
