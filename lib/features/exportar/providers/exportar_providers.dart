import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clientes/domain/cliente_model.dart';
import '../../clientes/providers/clientes_providers.dart';
import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/solicitud_model.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

enum FiltroFechaExportar { todo, hoy, semana, mes, personalizado }

enum FiltroEstadoExportar { pendientes, entregadas, ambos }

class RangoExportar {
  final DateTime? inicio;
  final DateTime? fin;

  const RangoExportar({this.inicio, this.fin});
}

class ResultadoExportar {
  final List<Solicitud> solicitudes;
  final Map<String, Cliente> clientesPorId;
  final double totalEntregado;
  final double totalPendiente;

  const ResultadoExportar({
    required this.solicitudes,
    required this.clientesPorId,
    required this.totalEntregado,
    required this.totalPendiente,
  });
}

final filtroFechaExportarProvider =
    StateProvider<FiltroFechaExportar>((ref) => FiltroFechaExportar.todo);

final filtroEstadoExportarProvider =
    StateProvider<FiltroEstadoExportar>((ref) => FiltroEstadoExportar.ambos);

final fechaInicioExportarProvider = StateProvider<DateTime?>((ref) => null);
final fechaFinExportarProvider = StateProvider<DateTime?>((ref) => null);

final rangoFechaExportarActivoProvider = Provider<RangoExportar?>((ref) {
  final filtro = ref.watch(filtroFechaExportarProvider);
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finDeHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

  switch (filtro) {
    case FiltroFechaExportar.todo:
      return null;
    case FiltroFechaExportar.hoy:
      return RangoExportar(inicio: hoy, fin: finDeHoy);
    case FiltroFechaExportar.semana:
      final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
      return RangoExportar(inicio: inicioSemana, fin: finDeHoy);
    case FiltroFechaExportar.mes:
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      return RangoExportar(inicio: inicioMes, fin: finDeHoy);
    case FiltroFechaExportar.personalizado:
      final inicio = ref.watch(fechaInicioExportarProvider);
      final finSeleccionado = ref.watch(fechaFinExportarProvider);
      final fin = finSeleccionado == null
          ? null
          : DateTime(
              finSeleccionado.year,
              finSeleccionado.month,
              finSeleccionado.day,
              23,
              59,
              59,
              999,
            );
      return RangoExportar(inicio: inicio, fin: fin);
  }
});

final solicitudesParaExportarProvider =
    Provider<AsyncValue<ResultadoExportar>>((ref) {
  final solicitudesAsync = ref.watch(solicitudesStreamProvider);
  final clientesAsync = ref.watch(clientesStreamProvider);
  final rango = ref.watch(rangoFechaExportarActivoProvider);
  final filtroEstado = ref.watch(filtroEstadoExportarProvider);

  return solicitudesAsync.whenData((todas) {
    final clientes = clientesAsync.value ?? <Cliente>[];
    final clientesPorId = {for (final c in clientes) c.id: c};

    final filtradas = todas.where((s) {
      if (rango != null) {
        if (rango.inicio != null && s.fechaCreacion.isBefore(rango.inicio!)) {
          return false;
        }
        if (rango.fin != null && s.fechaCreacion.isAfter(rango.fin!)) {
          return false;
        }
      }
      switch (filtroEstado) {
        case FiltroEstadoExportar.pendientes:
          return s.estadoPedido == EstadoPedido.pendiente;
        case FiltroEstadoExportar.entregadas:
          return s.estadoPedido == EstadoPedido.entregado;
        case FiltroEstadoExportar.ambos:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    final totalEntregado = filtradas
        .where((s) => s.estadoPedido == EstadoPedido.entregado)
        .fold(0.0, (sum, s) => sum + s.total);
    final totalPendiente = filtradas
        .where((s) => s.estadoPedido == EstadoPedido.pendiente)
        .fold(0.0, (sum, s) => sum + s.total);

    return ResultadoExportar(
      solicitudes: filtradas,
      clientesPorId: clientesPorId,
      totalEntregado: totalEntregado,
      totalPendiente: totalPendiente,
    );
  });
});
