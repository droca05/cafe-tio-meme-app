import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/producto_model.dart';

class ProductosRepository {
  final FirebaseFirestore _firestore;

  ProductosRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('productos');

  Stream<List<Producto>> streamProductosActivos() {
    return _collection.where('activo', isEqualTo: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Producto.fromFirestore).toList(),
        );
  }
}
