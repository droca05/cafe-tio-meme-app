import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

PresentacionCafe? _parsePresentacion(String? value) {
  if (value == null) return null;
  for (final presentacion in PresentacionCafe.values) {
    if (presentacion.name == value) return presentacion;
  }
  return null;
}

CanalVenta _parseCanal(String? value) {
  return CanalVenta.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CanalVenta.ventaDirecta,
  );
}

EstadoSolicitud _parseEstadoSolicitud(String? value) {
  return EstadoSolicitud.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoSolicitud.revisar,
  );
}

class ProductoItem {
  final String productoId; // Referencia a Producto
  final String nombre; // Desnormalizado
  final PresentacionCafe? presentacion; // null si el producto no aplica presentación
  final int cantidad;
  final bool esPromo; // si se aplicó el precio promocional
  final double precioUnitario; // precio aplicado (editable al crear/editar)
  final double subtotal; // precioUnitario * cantidad

  const ProductoItem({
    required this.productoId,
    required this.nombre,
    this.presentacion,
    required this.cantidad,
    required this.esPromo,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ProductoItem.fromMap(Map<String, dynamic> map) {
    return ProductoItem(
      productoId: map['productoId'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      presentacion: _parsePresentacion(map['presentacion'] as String?),
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
      esPromo: map['esPromo'] as bool? ?? false,
      precioUnitario: (map['precioUnitario'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'nombre': nombre,
      'presentacion': presentacion?.name,
      'cantidad': cantidad,
      'esPromo': esPromo,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}

class Solicitud {
  final String id;
  final String clienteId; // Referencia a Cliente
  final String clienteNombre; // Desnormalizado para mostrar sin query extra
  final CanalVenta canal;
  final List<ProductoItem> productos;
  final double total; // Suma de los subtotales de productos
  final EstadoSolicitud estadoSolicitud;
  final String? notas;
  final DateTime fechaCreacion;
  final String creadoPor; // UID del usuario que creó la solicitud

  const Solicitud({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.canal,
    required this.productos,
    required this.total,
    required this.estadoSolicitud,
    this.notas,
    required this.fechaCreacion,
    required this.creadoPor,
  });

  factory Solicitud.fromMap(String id, Map<String, dynamic> map) {
    return Solicitud(
      id: id,
      clienteId: map['clienteId'] as String? ?? '',
      clienteNombre: map['clienteNombre'] as String? ?? '',
      canal: _parseCanal(map['canal'] as String?),
      productos: (map['productos'] as List<dynamic>? ?? const [])
          .map((p) => ProductoItem.fromMap(p as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      estadoSolicitud: _parseEstadoSolicitud(map['estadoSolicitud'] as String?),
      notas: map['notas'] as String?,
      fechaCreacion:
          (map['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creadoPor: map['creadoPor'] as String? ?? '',
    );
  }

  factory Solicitud.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Solicitud.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'canal': canal.name,
      'productos': productos.map((p) => p.toMap()).toList(),
      'total': total,
      'estadoSolicitud': estadoSolicitud.name,
      'notas': notas,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'creadoPor': creadoPor,
    };
  }

  Solicitud copyWith({
    EstadoSolicitud? estadoSolicitud,
    String? notas,
  }) {
    return Solicitud(
      id: id,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      canal: canal,
      productos: productos,
      total: total,
      estadoSolicitud: estadoSolicitud ?? this.estadoSolicitud,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion,
      creadoPor: creadoPor,
    );
  }
}
