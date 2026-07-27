import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../clientes/domain/cliente_model.dart';
import '../../productos/domain/producto_model.dart';
import '../../solicitudes/domain/enums.dart';
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
    required List<Producto> productos,
  }) async {
    final workbook = xlsio.Workbook();

    final hojaSolicitudes = workbook.worksheets[0]..name = 'Solicitudes';
    _llenarHojaSolicitudes(hojaSolicitudes, solicitudes, clientesPorId);

    final hojaResumen = workbook.worksheets.add()
      ..name = 'Resumen por producto';
    _llenarHojaResumen(hojaResumen, solicitudes, productos);

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

  String _nombreEstado(EstadoSolicitud estado) {
    switch (estado) {
      case EstadoSolicitud.revisar:
        return 'Revisar';
      case EstadoSolicitud.verificado:
        return 'Verificado';
      case EstadoSolicitud.noPagado:
        return 'No pagado';
    }
  }

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
        _nombreEstado(solicitud.estadoSolicitud),
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

  void _llenarHojaResumen(
    xlsio.Worksheet hoja,
    List<Solicitud> solicitudes,
    List<Producto> productos,
  ) {
    const encabezados = [
      'Producto',
      'Unidades Revisar',
      'Monto Revisar (Q)',
      'Unidades Verificado',
      'Monto Verificado (Q)',
      'Unidades No Pagado',
      'Monto No Pagado (Q)',
    ];

    for (var col = 0; col < encabezados.length; col++) {
      final celda = hoja.getRangeByIndex(1, col + 1);
      celda.setText(encabezados[col]);
      _estiloEncabezado(celda);
    }

    final unidadesRevisar = <String, int>{};
    final montoRevisar = <String, double>{};
    final unidadesVerificado = <String, int>{};
    final montoVerificado = <String, double>{};
    final unidadesNoPagado = <String, int>{};
    final montoNoPagado = <String, double>{};

    for (final solicitud in solicitudes) {
      final Map<String, int> unidadesMap;
      final Map<String, double> montoMap;
      switch (solicitud.estadoSolicitud) {
        case EstadoSolicitud.revisar:
          unidadesMap = unidadesRevisar;
          montoMap = montoRevisar;
        case EstadoSolicitud.verificado:
          unidadesMap = unidadesVerificado;
          montoMap = montoVerificado;
        case EstadoSolicitud.noPagado:
          unidadesMap = unidadesNoPagado;
          montoMap = montoNoPagado;
      }
      for (final producto in solicitud.productos) {
        unidadesMap[producto.productoId] =
            (unidadesMap[producto.productoId] ?? 0) + producto.cantidad;
        montoMap[producto.productoId] =
            (montoMap[producto.productoId] ?? 0) + producto.subtotal;
      }
    }

    final filas = productos.map((producto) {
      return (
        nombre: producto.nombre,
        uRevisar: unidadesRevisar[producto.id] ?? 0,
        mRevisar: montoRevisar[producto.id] ?? 0.0,
        uVerificado: unidadesVerificado[producto.id] ?? 0,
        mVerificado: montoVerificado[producto.id] ?? 0.0,
        uNoPagado: unidadesNoPagado[producto.id] ?? 0,
        mNoPagado: montoNoPagado[producto.id] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => b.mVerificado.compareTo(a.mVerificado));

    var fila = 2;
    var totalURevisar = 0;
    var totalMRevisar = 0.0;
    var totalUVerificado = 0;
    var totalMVerificado = 0.0;
    var totalUNoPagado = 0;
    var totalMNoPagado = 0.0;

    for (final f in filas) {
      final esPar = (fila - 2) % 2 == 0;

      totalURevisar += f.uRevisar;
      totalMRevisar += f.mRevisar;
      totalUVerificado += f.uVerificado;
      totalMVerificado += f.mVerificado;
      totalUNoPagado += f.uNoPagado;
      totalMNoPagado += f.mNoPagado;

      final valores = <Object>[
        f.nombre,
        f.uRevisar,
        f.mRevisar,
        f.uVerificado,
        f.mVerificado,
        f.uNoPagado,
        f.mNoPagado,
      ];

      for (var col = 0; col < valores.length; col++) {
        final celda = hoja.getRangeByIndex(fila, col + 1);
        final valor = valores[col];
        if (valor is String) {
          celda.setText(valor);
        } else {
          celda.setNumber((valor as num).toDouble());
          if (col == 2 || col == 4 || col == 6) {
            celda.numberFormat = _formatoMoneda;
          }
        }
        _estiloFilaAlterna(celda, esPar);
      }

      fila++;
    }

    final totales = <Object>[
      'TOTAL',
      totalURevisar,
      totalMRevisar,
      totalUVerificado,
      totalMVerificado,
      totalUNoPagado,
      totalMNoPagado,
    ];

    for (var col = 0; col < totales.length; col++) {
      final celda = hoja.getRangeByIndex(fila, col + 1);
      final valor = totales[col];
      if (valor is String) {
        celda.setText(valor);
      } else {
        celda.setNumber((valor as num).toDouble());
        if (col == 2 || col == 4 || col == 6) {
          celda.numberFormat = _formatoMoneda;
        }
      }
      _estiloTotal(celda);
    }

    hoja.getRangeByIndex(1, 1).columnWidth = 22;
    hoja.getRangeByIndex(1, 2).columnWidth = 16;
    hoja.getRangeByIndex(1, 3).columnWidth = 16;
    hoja.getRangeByIndex(1, 4).columnWidth = 18;
    hoja.getRangeByIndex(1, 5).columnWidth = 18;
    hoja.getRangeByIndex(1, 6).columnWidth = 17;
    hoja.getRangeByIndex(1, 7).columnWidth = 17;
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
