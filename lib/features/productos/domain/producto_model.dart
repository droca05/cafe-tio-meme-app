import 'package:cloud_firestore/cloud_firestore.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precioNormal;
  final double? precioPromo;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioNormal,
    this.precioPromo,
    required this.activo,
  });

  double precioEfectivo({required bool esPromo}) {
    if (esPromo && precioPromo != null) {
      return precioPromo!;
    }
    return precioNormal;
  }

  factory Producto.fromMap(String id, Map<String, dynamic> map) {
    return Producto(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      precioNormal: (map['precioNormal'] as num?)?.toDouble() ?? 0,
      precioPromo: (map['precioPromo'] as num?)?.toDouble(),
      activo: map['activo'] as bool? ?? true,
    );
  }

  factory Producto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Producto.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precioNormal': precioNormal,
      'precioPromo': precioPromo,
      'activo': activo,
    };
  }
}
