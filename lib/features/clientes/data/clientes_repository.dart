import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cliente_model.dart';

class ClientesRepository {
  final FirebaseFirestore _firestore;

  ClientesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('clientes');

  Future<void> crearCliente(Cliente cliente) {
    return _collection.doc(cliente.id).set(cliente.toMap());
  }

  Future<void> actualizarCliente(Cliente cliente) {
    return _collection.doc(cliente.id).update(cliente.toMap());
  }

  Stream<List<Cliente>> streamClientes() {
    return _collection
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Cliente.fromFirestore).toList());
  }

  Stream<Cliente> streamCliente(String id) {
    return _collection.doc(id).snapshots().map(Cliente.fromFirestore);
  }

  Future<Cliente?> obtenerClientePorId(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Cliente.fromFirestore(doc);
  }

  /// Búsqueda parcial por nombre o teléfono (case-insensitive).
  /// Firestore no soporta "contains" nativamente, así que se filtra
  /// en el cliente sobre el stream completo de clientes.
  Stream<List<Cliente>> buscarClientes(String query) {
    final normalizado = query.trim().toLowerCase();
    return streamClientes().map((clientes) {
      if (normalizado.isEmpty) return clientes;
      return clientes
          .where((c) =>
              c.nombre.toLowerCase().contains(normalizado) ||
              c.telefono.contains(normalizado))
          .toList();
    });
  }
}
