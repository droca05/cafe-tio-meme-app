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

EstadoPedido _parseEstadoPedido(String? value) {
  return EstadoPedido.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoPedido.pendiente,
  );
}

EstadoPago _parseEstadoPago(String? value) {
  return EstadoPago.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EstadoPago.pendiente,
  );
}

class ProductoItem {
  final String productoId; // Referencia a ProductoCatalogo
  final String nombre; // Desnormalizado
  final PresentacionCafe? presentacion; // null si el producto no aplica presentación
  final int cantidad;
  final bool esPromo; // si se aplicó el precio promocional
  final double precioUnitario; // precio aplicado (normal o promo) al momento de la venta
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
  final EstadoPedido estadoPedido;
  final EstadoPago estadoPago;
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
    required this.estadoPedido,
    required this.estadoPago,
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
      estadoPedido: _parseEstadoPedido(map['estadoPedido'] as String?),
      estadoPago: _parseEstadoPago(map['estadoPago'] as String?),
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
      'estadoPedido': estadoPedido.name,
      'estadoPago': estadoPago.name,
      'notas': notas,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'creadoPor': creadoPor,
    };
  }

  Solicitud copyWith({
    EstadoPedido? estadoPedido,
    EstadoPago? estadoPago,
    String? notas,
  }) {
    return Solicitud(
      id: id,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      canal: canal,
      productos: productos,
      total: total,
      estadoPedido: estadoPedido ?? this.estadoPedido,
      estadoPago: estadoPago ?? this.estadoPago,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion,
      creadoPor: creadoPor,
    );
  }
}
