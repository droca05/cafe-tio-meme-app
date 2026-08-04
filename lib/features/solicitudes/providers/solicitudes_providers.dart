import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/solicitudes_repository.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';

enum CanalFiltro { todas, ventaDirecta, forza }

final solicitudesRepositoryProvider = Provider<SolicitudesRepository>((ref) {
  return SolicitudesRepository();
});

// Depende de authStateChangesProvider para que la suscripción a Firestore
// se recree automáticamente al cambiar el usuario autenticado (login,
// logout o cambio de cuenta).
final solicitudesStreamProvider = StreamProvider<List<Solicitud>>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        debugPrint('=== STREAM: usuario null, retornando vacío ===');
        return Stream.value(<Solicitud>[]);
      }
      debugPrint('=== STREAM: iniciando para usuario ${user.email} ===');
      return ref
          .read(solicitudesRepositoryProvider)
          .streamSolicitudes()
          .map((solicitudes) {
        debugPrint('=== STREAM: ${solicitudes.length} solicitudes cargadas ===');
        return solicitudes;
      });
    },
    loading: () {
      debugPrint('=== STREAM: authState loading ===');
      return Stream.value(<Solicitud>[]);
    },
    error: (e, _) {
      debugPrint('=== STREAM: authState error: $e ===');
      return Stream.value(<Solicitud>[]);
    },
  );
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

  // El caso error se resuelve como lista vacía en vez de propagarse: así
  // la UI nunca queda mostrando un mensaje de error fijo por un problema
  // transitorio de conexión/reconexión del stream.
  return solicitudesAsync.when(
    data: (solicitudes) {
      var resultado = solicitudes;

      switch (canal) {
        case CanalFiltro.todas:
          break;
        case CanalFiltro.ventaDirecta:
          resultado = resultado
              .where((s) => s.canal == CanalVenta.ventaDirecta)
              .toList();
        case CanalFiltro.forza:
          resultado =
              resultado.where((s) => s.canal == CanalVenta.forza).toList();
      }

      if (estados.isNotEmpty) {
        resultado = resultado
            .where((s) => estados.contains(s.estadoSolicitud))
            .toList();
      }

      return AsyncData<List<Solicitud>>(resultado);
    },
    loading: () => const AsyncLoading<List<Solicitud>>(),
    error: (error, stackTrace) => const AsyncData<List<Solicitud>>([]),
  );
});
