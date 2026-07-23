import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../clientes/domain/cliente_model.dart';
import '../../solicitudes/domain/enums.dart';
import '../../solicitudes/domain/producto_catalogo.dart';
import '../../solicitudes/domain/solicitud_model.dart';

const _colorRoast = '#3B1F0A';
const _colorFoam = '#FAF6F0';
const _colorCaramel = '#A0622A';
const _colorBlanco = '#FFFFFF';
const _formatoMoneda = '"Q"#,##0.00';

class ExcelExportService {
  Future<String> exportar({
    required List<Solicitud> solicitudes,
    required Map<String, Cliente> clientesPorId,
  }) async {
    final workbook = xlsio.Workbook();

    final hojaSolicitudes = workbook.worksheets[0]..name = 'Solicitudes';
    _llenarHojaSolicitudes(hojaSolicitudes, solicitudes, clientesPorId);

    final hojaResumen = workbook.worksheets.add()
      ..name = 'Resumen por producto';
    _llenarHojaResumen(hojaResumen, solicitudes);

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    return _guardarArchivo(bytes);
  }

  void _estiloEncabezado(xlsio.Range rango) {
    rango.cellStyle
      ..backColor = _colorRoast
      ..fontColor = _colorBlanco
      ..bold = true;
  }

  void _estiloFilaAlterna(xlsio.Range rango, bool esPar) {
    rango.cellStyle.backColor = esPar ? _colorFoam : _colorBlanco;
  }

  void _estiloTotal(xlsio.Range rango) {
    rango.cellStyle
      ..backColor = _colorCaramel
      ..fontColor = _colorBlanco
      ..bold = true;
  }

  String _nombreCanal(CanalVenta canal) =>
      canal == CanalVenta.ventaDirecta ? 'Venta Directa' : 'FORZA';

  String _nombreEstado(EstadoPedido estado) =>
      estado == EstadoPedido.entregado ? 'Entregado' : 'Pendiente';

  String _nombreCreador(String creadoPor) =>
      creadoPor.isEmpty ? '' : creadoPor.split('@').first;

  String _resumenProductos(List<ProductoItem> productos) {
    return productos.map((p) => '${p.nombre} x${p.cantidad}').join(', ');
  }

  void _llenarHojaSolicitudes(
    xlsio.Worksheet hoja,
    List<Solicitud> solicitudes,
    Map<String, Cliente> clientesPorId,
  ) {
    const encabezados = [
      'Fecha',
      'Cliente',
      'Teléfono',
      'Dirección',
      'Canal',
      'Productos',
      'Total (Q)',
      'Estado',
      'Creado por',
    ];

    for (var col = 0; col < encabezados.length; col++) {
      final celda = hoja.getRangeByIndex(1, col + 1);
      celda.setText(encabezados[col]);
      _estiloEncabezado(celda);
    }

    var fila = 2;
    for (final solicitud in solicitudes) {
      final cliente = clientesPorId[solicitud.clienteId];
      final esPar = (fila - 2) % 2 == 0;

      final valores = [
        DateFormat('dd/MM/yyyy').format(solicitud.fechaCreacion),
        solicitud.clienteNombre,
        cliente?.telefono ?? '',
        cliente?.direccion ?? '',
        _nombreCanal(solicitud.canal),
        _resumenProductos(solicitud.productos),
        null, // Total, se escribe como número aparte
        _nombreEstado(solicitud.estadoPedido),
        _nombreCreador(solicitud.creadoPor),
      ];

      for (var col = 0; col < valores.length; col++) {
        final celda = hoja.getRangeByIndex(fila, col + 1);
        if (col == 6) {
          celda.setNumber(solicitud.total);
          celda.numberFormat = _formatoMoneda;
        } else {
          celda.setText(valores[col] as String);
        }
        _estiloFilaAlterna(celda, esPar);
      }

      fila++;
    }

    final totalGeneral = solicitudes.fold(0.0, (sum, s) => sum + s.total);
    final celdaTotalLabel = hoja.getRangeByIndex(fila, 1, fila, 6);
    celdaTotalLabel.merge();
    celdaTotalLabel.setText('TOTAL');
    _estiloTotal(celdaTotalLabel);

    final celdaTotalValor = hoja.getRangeByIndex(fila, 7);
    celdaTotalValor.setNumber(totalGeneral);
    celdaTotalValor.numberFormat = _formatoMoneda;
    _estiloTotal(celdaTotalValor);

    // Estado y Creado por quedan vacíos en la fila de total.
    final celdasVacias = hoja.getRangeByIndex(fila, 8, fila, 9);
    _estiloTotal(celdasVacias);

    hoja.getRangeByIndex(1, 1).columnWidth = 12;
    hoja.getRangeByIndex(1, 2).columnWidth = 22;
    hoja.getRangeByIndex(1, 3).columnWidth = 14;
    hoja.getRangeByIndex(1, 4).columnWidth = 28;
    hoja.getRangeByIndex(1, 5).columnWidth = 14;
    hoja.getRangeByIndex(1, 6).columnWidth = 32;
    hoja.getRangeByIndex(1, 7).columnWidth = 14;
    hoja.getRangeByIndex(1, 8).columnWidth = 12;
    hoja.getRangeByIndex(1, 9).columnWidth = 16;
  }

  void _llenarHojaResumen(xlsio.Worksheet hoja, List<Solicitud> solicitudes) {
    const encabezados = [
      'Producto',
      'Unidades Entregadas',
      'Ingresos (Q)',
      'Unidades Pendientes',
      'Monto Pendiente (Q)',
    ];

    for (var col = 0; col < encabezados.length; col++) {
      final celda = hoja.getRangeByIndex(1, col + 1);
      celda.setText(encabezados[col]);
      _estiloEncabezado(celda);
    }

    final unidadesEntregadas = <String, int>{};
    final ingresos = <String, double>{};
    final unidadesPendientes = <String, int>{};
    final montoPendiente = <String, double>{};

    for (final solicitud in solicitudes) {
      final esEntregado = solicitud.estadoPedido == EstadoPedido.entregado;
      for (final producto in solicitud.productos) {
        if (esEntregado) {
          unidadesEntregadas[producto.productoId] =
              (unidadesEntregadas[producto.productoId] ?? 0) +
                  producto.cantidad;
          ingresos[producto.productoId] =
              (ingresos[producto.productoId] ?? 0) + producto.subtotal;
        } else {
          unidadesPendientes[producto.productoId] =
              (unidadesPendientes[producto.productoId] ?? 0) +
                  producto.cantidad;
          montoPendiente[producto.productoId] =
              (montoPendiente[producto.productoId] ?? 0) + producto.subtotal;
        }
      }
    }

    var fila = 2;
    var totalUnidadesEntregadas = 0;
    var totalIngresos = 0.0;
    var totalUnidadesPendientes = 0;
    var totalMontoPendiente = 0.0;

    for (final producto in catalogoProductos) {
      final esPar = (fila - 2) % 2 == 0;
      final uEntregadas = unidadesEntregadas[producto.id] ?? 0;
      final ing = ingresos[producto.id] ?? 0;
      final uPendientes = unidadesPendientes[producto.id] ?? 0;
      final montoPend = montoPendiente[producto.id] ?? 0;

      totalUnidadesEntregadas += uEntregadas;
      totalIngresos += ing;
      totalUnidadesPendientes += uPendientes;
      totalMontoPendiente += montoPend;

      final celdaNombre = hoja.getRangeByIndex(fila, 1);
      celdaNombre.setText(producto.nombre);
      _estiloFilaAlterna(celdaNombre, esPar);

      final celdaUnidadesEntregadas = hoja.getRangeByIndex(fila, 2);
      celdaUnidadesEntregadas.setNumber(uEntregadas.toDouble());
      _estiloFilaAlterna(celdaUnidadesEntregadas, esPar);

      final celdaIngresos = hoja.getRangeByIndex(fila, 3);
      celdaIngresos.setNumber(ing);
      celdaIngresos.numberFormat = _formatoMoneda;
      _estiloFilaAlterna(celdaIngresos, esPar);

      final celdaUnidadesPendientes = hoja.getRangeByIndex(fila, 4);
      celdaUnidadesPendientes.setNumber(uPendientes.toDouble());
      _estiloFilaAlterna(celdaUnidadesPendientes, esPar);

      final celdaMontoPendiente = hoja.getRangeByIndex(fila, 5);
      celdaMontoPendiente.setNumber(montoPend);
      celdaMontoPendiente.numberFormat = _formatoMoneda;
      _estiloFilaAlterna(celdaMontoPendiente, esPar);

      fila++;
    }

    final celdaTotalLabel = hoja.getRangeByIndex(fila, 1);
    celdaTotalLabel.setText('TOTAL');
    _estiloTotal(celdaTotalLabel);

    final celdaTotalUnidadesEntregadas = hoja.getRangeByIndex(fila, 2);
    celdaTotalUnidadesEntregadas.setNumber(
      totalUnidadesEntregadas.toDouble(),
    );
    _estiloTotal(celdaTotalUnidadesEntregadas);

    final celdaTotalIngresos = hoja.getRangeByIndex(fila, 3);
    celdaTotalIngresos.setNumber(totalIngresos);
    celdaTotalIngresos.numberFormat = _formatoMoneda;
    _estiloTotal(celdaTotalIngresos);

    final celdaTotalUnidadesPendientes = hoja.getRangeByIndex(fila, 4);
    celdaTotalUnidadesPendientes.setNumber(
      totalUnidadesPendientes.toDouble(),
    );
    _estiloTotal(celdaTotalUnidadesPendientes);

    final celdaTotalMontoPendiente = hoja.getRangeByIndex(fila, 5);
    celdaTotalMontoPendiente.setNumber(totalMontoPendiente);
    celdaTotalMontoPendiente.numberFormat = _formatoMoneda;
    _estiloTotal(celdaTotalMontoPendiente);

    hoja.getRangeByIndex(1, 1).columnWidth = 22;
    hoja.getRangeByIndex(1, 2).columnWidth = 18;
    hoja.getRangeByIndex(1, 3).columnWidth = 14;
    hoja.getRangeByIndex(1, 4).columnWidth = 18;
    hoja.getRangeByIndex(1, 5).columnWidth = 18;
  }

  Future<String> _guardarArchivo(List<int> bytes) async {
    final nombreArchivo =
        'CafeTioMeme_${DateFormat('ddMMyyyy').format(DateTime.now())}.xlsx';

    // En Android 10+ (API 29+) no se puede escribir directamente en
    // /sdcard/Download vía File; se intenta con las carpetas que el propio
    // sistema operativo concede sin permisos especiales, y como último
    // recurso se usa el directorio de documentos de la app, que siempre
    // funciona sin requerir ningún permiso.
    Directory? directorio;

    try {
      directorio = await getDownloadsDirectory();
    } catch (_) {
      directorio = null;
    }

    if (directorio == null) {
      try {
        directorio = await getExternalStorageDirectory();
      } catch (_) {
        directorio = null;
      }
    }

    directorio ??= await getApplicationDocumentsDirectory();

    final archivo = File('${directorio.path}/$nombreArchivo');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo.path;
  }
}
