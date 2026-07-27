import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/productos_repository.dart';
import '../domain/producto_model.dart';

final productosRepositoryProvider = Provider<ProductosRepository>((ref) {
  return ProductosRepository();
});

final productosActivosProvider = StreamProvider<List<Producto>>((ref) {
  final repository = ref.watch(productosRepositoryProvider);
  return repository.streamProductosActivos();
});

final productosTodosProvider = StreamProvider<List<Producto>>((ref) {
  final repository = ref.watch(productosRepositoryProvider);
  return repository.obtenerTodos();
});

final productoPorIdProvider =
    StreamProvider.family<Producto, String>((ref, id) {
  final repository = ref.watch(productosRepositoryProvider);
  return repository.streamProductoPorId(id);
});
