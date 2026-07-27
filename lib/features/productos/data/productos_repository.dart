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

  Stream<List<Producto>> obtenerTodos() {
    return _collection.orderBy('nombre').snapshots().map(
          (snapshot) => snapshot.docs.map(Producto.fromFirestore).toList(),
        );
  }

  Stream<Producto> streamProductoPorId(String id) {
    return _collection
        .doc(id)
        .snapshots()
        .map((doc) => Producto.fromFirestore(doc));
  }

  Future<void> agregarProducto(Producto producto) {
    return _collection.add(producto.toMap());
  }

  Future<void> actualizarProducto(String id, Map<String, dynamic> datos) {
    return _collection.doc(id).update(datos);
  }

  Future<void> toggleActivo(String id, bool activo) {
    return _collection.doc(id).update({'activo': activo});
  }

  Future<void> eliminarProducto(String id) {
    return _collection.doc(id).delete();
  }
}
