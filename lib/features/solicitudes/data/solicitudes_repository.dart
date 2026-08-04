import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
import '../domain/solicitud_model.dart';

class SolicitudesRepository {
  final FirebaseFirestore _firestore;

  SolicitudesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('solicitudes');

  Future<void> crearSolicitud(Solicitud solicitud) {
    return _collection.doc(solicitud.id).set(solicitud.toMap());
  }

  Future<void> actualizarSolicitud(Solicitud solicitud) {
    return _collection.doc(solicitud.id).set(solicitud.toMap());
  }

  Future<void> eliminarSolicitud(String id) {
    return _collection.doc(id).delete();
  }

  // Un solo orderBy sin where() en otro campo: Firestore lo cubre con su
  // índice automático de campo simple, no requiere índice compuesto.
  Stream<List<Solicitud>> streamSolicitudes() {
    return _collection
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<Solicitud> solicitudes = [];
      for (final doc in snapshot.docs) {
        try {
          solicitudes.add(Solicitud.fromFirestore(doc));
        } catch (e) {
          debugPrint('Error deserializando solicitud ${doc.id}: $e');
          // Se omite este documento y se sigue con los demás.
        }
      }
      return solicitudes;
    });
  }

  // Sin orderBy en el query para evitar requerir un índice compuesto en
  // Firestore (where + orderBy en campos distintos); se ordena en Dart.
  Stream<List<Solicitud>> streamSolicitudesPorCliente(String clienteId) {
    return _collection
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((snapshot) {
      final solicitudes =
          snapshot.docs.map(Solicitud.fromFirestore).toList();
      solicitudes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      return solicitudes;
    });
  }

  Stream<Solicitud> streamSolicitud(String id) {
    return _collection.doc(id).snapshots().map(Solicitud.fromFirestore);
  }

  Future<void> actualizarEstadoSolicitud(String id, EstadoSolicitud estado) {
    return _collection.doc(id).update({'estadoSolicitud': estado.name});
  }
}
