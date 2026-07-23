import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id; // UUID generado localmente
  final String nombre;
  final String telefono;
  final String direccion;
  final DateTime fechaRegistro;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.direccion,
    required this.fechaRegistro,
  });

  factory Cliente.fromMap(String id, Map<String, dynamic> map) {
    return Cliente(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      fechaRegistro:
          (map['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Cliente.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Cliente.fromMap(doc.id, doc.data() ?? <String, dynamic>{});
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    };
  }

  Cliente copyWith({
    String? nombre,
    String? telefono,
    String? direccion,
  }) {
    return Cliente(
      id: id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      fechaRegistro: fechaRegistro,
    );
  }
}
