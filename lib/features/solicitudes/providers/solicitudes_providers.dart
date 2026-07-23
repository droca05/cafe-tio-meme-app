import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/solicitudes_repository.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';

enum FiltroSolicitud { todas, ventaDirecta, forza, pendiente, entregado }

final solicitudesRepositoryProvider = Provider<SolicitudesRepository>((ref) {
  return SolicitudesRepository();
});

final solicitudesStreamProvider = StreamProvider<List<Solicitud>>((ref) {
  final repository = ref.watch(solicitudesRepositoryProvider);
  return repository.streamSolicitudes();
});

final solicitudStreamProvider =
    StreamProvider.family<Solicitud, String>((ref, id) {
  final repository = ref.watch(solicitudesRepositoryProvider);
  return repository.streamSolicitud(id);
});

final solicitudesPorClienteProvider =
    StreamProvider.family<List<Solicitud>, String>((ref, clienteId) {
  final repository = ref.watch(solicitudesRepositoryProvider);
  return repository.streamSolicitudesPorCliente(clienteId);
});

final filtroSolicitudProvider = StateProvider<FiltroSolicitud>((ref) {
  return FiltroSolicitud.todas;
});

final solicitudesFiltradasProvider = Provider<AsyncValue<List<Solicitud>>>((ref) {
  final filtro = ref.watch(filtroSolicitudProvider);
  final solicitudesAsync = ref.watch(solicitudesStreamProvider);

  return solicitudesAsync.whenData((solicitudes) {
    switch (filtro) {
      case FiltroSolicitud.todas:
        return solicitudes;
      case FiltroSolicitud.ventaDirecta:
        return solicitudes
            .where((s) => s.canal == CanalVenta.ventaDirecta)
            .toList();
      case FiltroSolicitud.forza:
        return solicitudes.where((s) => s.canal == CanalVenta.forza).toList();
      case FiltroSolicitud.pendiente:
        return solicitudes
            .where((s) => s.estadoPedido == EstadoPedido.pendiente)
            .toList();
      case FiltroSolicitud.entregado:
        return solicitudes
            .where((s) => s.estadoPedido == EstadoPedido.entregado)
            .toList();
    }
  });
});
