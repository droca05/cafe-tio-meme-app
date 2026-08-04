import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/solicitudes_repository.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';

enum CanalFiltro { todas, ventaDirecta, forza }

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

final canalFiltroProvider = StateProvider<CanalFiltro>((ref) {
  return CanalFiltro.todas;
});

final estadosFiltroProvider = StateProvider<Set<EstadoSolicitud>>((ref) {
  return <EstadoSolicitud>{};
});

final solicitudesFiltradasProvider = Provider<AsyncValue<List<Solicitud>>>((ref) {
  final canal = ref.watch(canalFiltroProvider);
  final estados = ref.watch(estadosFiltroProvider);
  final solicitudesAsync = ref.watch(solicitudesStreamProvider);

  return solicitudesAsync.whenData((solicitudes) {
    var resultado = solicitudes;

    switch (canal) {
      case CanalFiltro.todas:
        break;
      case CanalFiltro.ventaDirecta:
        resultado =
            resultado.where((s) => s.canal == CanalVenta.ventaDirecta).toList();
      case CanalFiltro.forza:
        resultado = resultado.where((s) => s.canal == CanalVenta.forza).toList();
    }

    if (estados.isNotEmpty) {
      resultado =
          resultado.where((s) => estados.contains(s.estadoSolicitud)).toList();
    }

    return resultado;
  });
});
