import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class ProductoItem {
  final String nombre;
  final int cantidad;

  const ProductoItem({
    required this.nombre,
    required this.cantidad,
  });

  factory ProductoItem.fromMap(Map<String, dynamic> map) {
    return ProductoItem(
      nombre: map['nombre'] as String,
      cantidad: map['cantidad'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'cantidad': cantidad,
    };
  }
}

class Solicitud {
  final String id;
  final String clienteId; // Referencia a Cliente
  final String clienteNombre; // Desnormalizado para mostrar sin query extra
  final CanalVenta canal;
  final List<ProductoItem> productos;
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
    required this.estadoPedido,
    required this.estadoPago,
    this.notas,
    required this.fechaCreacion,
    required this.creadoPor,
  });

  factory Solicitud.fromMap(String id, Map<String, dynamic> map) {
    return Solicitud(
      id: id,
      clienteId: map['clienteId'] as String,
      clienteNombre: map['clienteNombre'] as String,
      canal: CanalVenta.values.byName(map['canal'] as String),
      productos: (map['productos'] as List<dynamic>)
          .map((p) => ProductoItem.fromMap(p as Map<String, dynamic>))
          .toList(),
      estadoPedido: EstadoPedido.values.byName(map['estadoPedido'] as String),
      estadoPago: EstadoPago.values.byName(map['estadoPago'] as String),
      notas: map['notas'] as String?,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      creadoPor: map['creadoPor'] as String,
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
      estadoPedido: estadoPedido ?? this.estadoPedido,
      estadoPago: estadoPago ?? this.estadoPago,
      notas: notas ?? this.notas,
      fechaCreacion: fechaCreacion,
      creadoPor: creadoPor,
    );
  }
}
