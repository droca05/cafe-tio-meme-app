import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/canal_badge.dart';
import '../../../shared/widgets/estado_pedido_badge.dart';
import '../../solicitudes/providers/solicitudes_providers.dart';
import '../domain/cliente_model.dart';
import '../providers/clientes_providers.dart';

class ClienteDetailScreen extends ConsumerStatefulWidget {
  final String clienteId;

  const ClienteDetailScreen({super.key, required this.clienteId});

  @override
  ConsumerState<ClienteDetailScreen> createState() =>
      _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends ConsumerState<ClienteDetailScreen> {
  bool _editando = false;
  bool _isSaving = false;
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _iniciarEdicion(Cliente cliente) {
    _nombreController.text = cliente.nombre;
    _telefonoController.text = cliente.telefono;
    _direccionController.text = cliente.direccion;
    setState(() => _editando = true);
  }

  Future<void> _guardarCambios(Cliente cliente) async {
    setState(() => _isSaving = true);

    final actualizado = cliente.copyWith(
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
    );

    await ref.read(clientesRepositoryProvider).actualizarCliente(actualizado);

    if (mounted) {
      setState(() {
        _editando = false;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteAsync = ref.watch(clienteStreamProvider(widget.clienteId));
    final solicitudesAsync =
        ref.watch(solicitudesPorClienteProvider(widget.clienteId));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Cliente')),
      body: clienteAsync.when(
        data: (cliente) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_editando) ...[
                  Text(cliente.nombre, style: AppTextStyles.displayMedium),
                  const SizedBox(height: 8),
                  Text(cliente.telefono, style: AppTextStyles.bodyMedium),
                  Text(cliente.direccion, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _iniciarEdicion(cliente),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar datos'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => setState(() => _editando = false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _guardarCambios(cliente),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.foam,
                                  ),
                                )
                              : const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Historial de solicitudes',
                  style: AppTextStyles.bodyMedium500,
                ),
                const SizedBox(height: 8),
                solicitudesAsync.when(
                  data: (solicitudes) {
                    if (solicitudes.isEmpty) {
                      return Text(
                        'Sin solicitudes anteriores',
                        style: AppTextStyles.bodyLight,
                      );
                    }
                    return Column(
                      children: [
                        for (final solicitud in solicitudes)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () =>
                                  context.push('/solicitudes/${solicitud.id}'),
                              title: Row(
                                children: [
                                  CanalBadge(canal: solicitud.canal),
                                  const SizedBox(width: 8),
                                  EstadoPedidoBadge(
                                    estadoPedido: solicitud.estadoPedido,
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                formatFechaHora(solicitud.fechaCreacion),
                                style: AppTextStyles.bodyLight,
                              ),
                              trailing: Text(
                                'Q${solicitud.total.toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium500,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Text(
                    'Ocurrió un error al cargar el historial.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'No se pudo cargar el cliente.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
