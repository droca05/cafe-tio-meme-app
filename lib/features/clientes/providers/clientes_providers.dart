import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clientes_repository.dart';
import '../domain/cliente_model.dart';

final clientesRepositoryProvider = Provider<ClientesRepository>((ref) {
  return ClientesRepository();
});

final clientesStreamProvider = StreamProvider<List<Cliente>>((ref) {
  final repository = ref.watch(clientesRepositoryProvider);
  return repository.streamClientes();
});

final clienteStreamProvider = StreamProvider.family<Cliente, String>((ref, id) {
  final repository = ref.watch(clientesRepositoryProvider);
  return repository.streamCliente(id);
});

final busquedaClienteProvider = StateProvider<String>((ref) => '');

final clientesBuscadosProvider = StreamProvider<List<Cliente>>((ref) {
  final repository = ref.watch(clientesRepositoryProvider);
  final query = ref.watch(busquedaClienteProvider);
  return repository.buscarClientes(query);
});
