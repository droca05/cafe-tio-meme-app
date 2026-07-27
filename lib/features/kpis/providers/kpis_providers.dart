import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../productos/providers/productos_providers.dart';
import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/solicitud_model.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';

enum RangoFecha { todo, hoy, semana, mes, personalizado }

class RangoFechas {
  final DateTime inicio;
  final DateTime fin;

  const RangoFechas({required this.inicio, required this.fin});
}

class VentaProducto {
  final String nombre;
  final int unidadesRevisar;
  final double montoRevisar;
  final int unidadesVerificado;
  final double montoVerificado;
  final int unidadesNoPagado;
  final double montoNoPagado;

  const VentaProducto({
    required this.nombre,
    required this.unidadesRevisar,
    required this.montoRevisar,
    required this.unidadesVerificado,
    required this.montoVerificado,
    required this.unidadesNoPagado,
    required this.montoNoPagado,
  });
}

class VentaCanal {
  final int cantidadSolicitudes;
  final double totalVerificado;

  const VentaCanal({
    required this.cantidadSolicitudes,
    required this.totalVerificado,
  });
}

class KpisData {
  final double totalRevisar;
  final double totalVerificado;
  final double totalNoPagado;
  final List<VentaProducto> ventasPorProducto;
  final VentaCanal forza;
  final VentaCanal ventaDirecta;
  final int totalSolicitudes;
  final int clientesUnicos;
  final double ticketPromedio;

  const KpisData({
    required this.totalRevisar,
    required this.totalVerificado,
    required this.totalNoPagado,
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
  final productosAsync = ref.watch(productosActivosProvider);
  final rango = ref.watch(rangoFechasActivoProvider);

  return solicitudesAsync.whenData((todas) {
    final productos = productosAsync.value ?? [];

    final enRango = todas
        .where((s) =>
            !s.fechaCreacion.isBefore(rango.inicio) &&
            !s.fechaCreacion.isAfter(rango.fin))
        .toList();

    final revisar =
        enRango.where((s) => s.estadoSolicitud == EstadoSolicitud.revisar).toList();
    final verificadas = enRango
        .where((s) => s.estadoSolicitud == EstadoSolicitud.verificado)
        .toList();
    final noPagadas =
        enRango.where((s) => s.estadoSolicitud == EstadoSolicitud.noPagado).toList();

    final totalRevisar = revisar.fold(0.0, (sum, s) => sum + s.total);
    final totalVerificado = verificadas.fold(0.0, (sum, s) => sum + s.total);
    final totalNoPagado = noPagadas.fold(0.0, (sum, s) => sum + s.total);

    final unidadesRevisarPorProducto = <String, int>{};
    final montoRevisarPorProducto = <String, double>{};
    final unidadesVerificadoPorProducto = <String, int>{};
    final montoVerificadoPorProducto = <String, double>{};
    final unidadesNoPagadoPorProducto = <String, int>{};
    final montoNoPagadoPorProducto = <String, double>{};

    void acumular(
      List<Solicitud> solicitudes,
      Map<String, int> unidadesMap,
      Map<String, double> montoMap,
    ) {
      for (final s in solicitudes) {
        for (final p in s.productos) {
          unidadesMap[p.productoId] = (unidadesMap[p.productoId] ?? 0) + p.cantidad;
          montoMap[p.productoId] = (montoMap[p.productoId] ?? 0) + p.subtotal;
        }
      }
    }

    acumular(revisar, unidadesRevisarPorProducto, montoRevisarPorProducto);
    acumular(verificadas, unidadesVerificadoPorProducto, montoVerificadoPorProducto);
    acumular(noPagadas, unidadesNoPagadoPorProducto, montoNoPagadoPorProducto);

    final ventasPorProducto = productos.map((producto) {
      return VentaProducto(
        nombre: producto.nombre,
        unidadesRevisar: unidadesRevisarPorProducto[producto.id] ?? 0,
        montoRevisar: montoRevisarPorProducto[producto.id] ?? 0,
        unidadesVerificado: unidadesVerificadoPorProducto[producto.id] ?? 0,
        montoVerificado: montoVerificadoPorProducto[producto.id] ?? 0,
        unidadesNoPagado: unidadesNoPagadoPorProducto[producto.id] ?? 0,
        montoNoPagado: montoNoPagadoPorProducto[producto.id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.montoVerificado.compareTo(a.montoVerificado));

    VentaCanal calcularCanal(CanalVenta canal) {
      final delCanal = verificadas.where((s) => s.canal == canal).toList();
      return VentaCanal(
        cantidadSolicitudes: delCanal.length,
        totalVerificado: delCanal.fold(0.0, (sum, s) => sum + s.total),
      );
    }

    final totalSolicitudes = enRango.length;
    final clientesUnicos = enRango.map((s) => s.clienteId).toSet().length;
    final ticketPromedio =
        verificadas.isEmpty ? 0.0 : totalVerificado / verificadas.length;

    return KpisData(
      totalRevisar: totalRevisar,
      totalVerificado: totalVerificado,
      totalNoPagado: totalNoPagado,
      ventasPorProducto: ventasPorProducto,
      forza: calcularCanal(CanalVenta.forza),
      ventaDirecta: calcularCanal(CanalVenta.ventaDirecta),
      totalSolicitudes: totalSolicitudes,
      clientesUnicos: clientesUnicos,
      ticketPromedio: ticketPromedio,
    );
  });
});
