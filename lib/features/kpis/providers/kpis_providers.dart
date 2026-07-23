import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/producto_catalogo.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

enum RangoFecha { todo, hoy, semana, mes, personalizado }

class RangoFechas {
  final DateTime inicio;
  final DateTime fin;

  const RangoFechas({required this.inicio, required this.fin});
}

class VentaProducto {
  final String nombre;
  final int unidadesEntregadas;
  final double ingresosEntregados;
  final int unidadesPendientes;
  final double montoPendiente;

  const VentaProducto({
    required this.nombre,
    required this.unidadesEntregadas,
    required this.ingresosEntregados,
    required this.unidadesPendientes,
    required this.montoPendiente,
  });
}

class VentaCanal {
  final int cantidadSolicitudes;
  final double totalEntregado;

  const VentaCanal({
    required this.cantidadSolicitudes,
    required this.totalEntregado,
  });
}

class KpisData {
  final double totalEntregado;
  final double totalPendiente;
  final List<VentaProducto> ventasPorProducto;
  final VentaCanal forza;
  final VentaCanal ventaDirecta;
  final int totalSolicitudes;
  final int clientesUnicos;
  final double ticketPromedio;

  const KpisData({
    required this.totalEntregado,
    required this.totalPendiente,
    required this.ventasPorProducto,
    required this.forza,
    required this.ventaDirecta,
    required this.totalSolicitudes,
    required this.clientesUnicos,
    required this.ticketPromedio,
  });
}

final rangoFechaProvider = StateProvider<RangoFecha>((ref) => RangoFecha.mes);

final fechaInicioPersonalizadaProvider = StateProvider<DateTime?>((ref) => null);
final fechaFinPersonalizadaProvider = StateProvider<DateTime?>((ref) => null);

final rangoFechasActivoProvider = Provider<RangoFechas>((ref) {
  final rango = ref.watch(rangoFechaProvider);
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final finDeHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59, 999);

  switch (rango) {
    case RangoFecha.todo:
      return RangoFechas(inicio: DateTime(2000, 1, 1), fin: finDeHoy);
    case RangoFecha.hoy:
      return RangoFechas(inicio: hoy, fin: finDeHoy);
    case RangoFecha.semana:
      final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
      return RangoFechas(inicio: inicioSemana, fin: finDeHoy);
    case RangoFecha.mes:
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      return RangoFechas(inicio: inicioMes, fin: finDeHoy);
    case RangoFecha.personalizado:
      final inicioSeleccionado = ref.watch(fechaInicioPersonalizadaProvider) ?? hoy;
      final finSeleccionado = ref.watch(fechaFinPersonalizadaProvider) ?? hoy;
      final inicio = DateTime(
        inicioSeleccionado.year,
        inicioSeleccionado.month,
        inicioSeleccionado.day,
      );
      final fin = DateTime(
        finSeleccionado.year,
        finSeleccionado.month,
        finSeleccionado.day,
        23,
        59,
        59,
        999,
      );
      return RangoFechas(inicio: inicio, fin: fin);
  }
});

final kpisProvider = Provider<AsyncValue<KpisData>>((ref) {
  final solicitudesAsync = ref.watch(solicitudesStreamProvider);
  final rango = ref.watch(rangoFechasActivoProvider);

  return solicitudesAsync.whenData((todas) {
    final enRango = todas
        .where((s) =>
            !s.fechaCreacion.isBefore(rango.inicio) &&
            !s.fechaCreacion.isAfter(rango.fin))
        .toList();

    final entregadas =
        enRango.where((s) => s.estadoPedido == EstadoPedido.entregado).toList();
    final pendientes =
        enRango.where((s) => s.estadoPedido == EstadoPedido.pendiente).toList();

    final totalEntregado = entregadas.fold(0.0, (sum, s) => sum + s.total);
    final totalPendiente = pendientes.fold(0.0, (sum, s) => sum + s.total);

    final unidadesEntregadasPorProducto = <String, int>{};
    final ingresosPorProducto = <String, double>{};
    final unidadesPendientesPorProducto = <String, int>{};
    final montoPendientePorProducto = <String, double>{};

    for (final s in entregadas) {
      for (final p in s.productos) {
        unidadesEntregadasPorProducto[p.productoId] =
            (unidadesEntregadasPorProducto[p.productoId] ?? 0) + p.cantidad;
        ingresosPorProducto[p.productoId] =
            (ingresosPorProducto[p.productoId] ?? 0) + p.subtotal;
      }
    }
    for (final s in pendientes) {
      for (final p in s.productos) {
        unidadesPendientesPorProducto[p.productoId] =
            (unidadesPendientesPorProducto[p.productoId] ?? 0) + p.cantidad;
        montoPendientePorProducto[p.productoId] =
            (montoPendientePorProducto[p.productoId] ?? 0) + p.subtotal;
      }
    }

    final ventasPorProducto = catalogoProductos.map((producto) {
      return VentaProducto(
        nombre: producto.nombre,
        unidadesEntregadas: unidadesEntregadasPorProducto[producto.id] ?? 0,
        ingresosEntregados: ingresosPorProducto[producto.id] ?? 0,
        unidadesPendientes: unidadesPendientesPorProducto[producto.id] ?? 0,
        montoPendiente: montoPendientePorProducto[producto.id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.ingresosEntregados.compareTo(a.ingresosEntregados));

    VentaCanal calcularCanal(CanalVenta canal) {
      final delCanal = entregadas.where((s) => s.canal == canal).toList();
      return VentaCanal(
        cantidadSolicitudes: delCanal.length,
        totalEntregado: delCanal.fold(0.0, (sum, s) => sum + s.total),
      );
    }

    final totalSolicitudes = enRango.length;
    final clientesUnicos = enRango.map((s) => s.clienteId).toSet().length;
    final ticketPromedio =
        entregadas.isEmpty ? 0.0 : totalEntregado / entregadas.length;

    return KpisData(
      totalEntregado: totalEntregado,
      totalPendiente: totalPendiente,
      ventasPorProducto: ventasPorProducto,
      forza: calcularCanal(CanalVenta.forza),
      ventaDirecta: calcularCanal(CanalVenta.ventaDirecta),
      totalSolicitudes: totalSolicitudes,
      clientesUnicos: clientesUnicos,
      ticketPromedio: ticketPromedio,
    );
  });
});
