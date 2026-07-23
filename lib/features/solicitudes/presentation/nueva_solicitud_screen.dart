import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clientes/domain/cliente_model.dart';
import '../../clientes/providers/clientes_providers.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';
import '../providers/solicitudes_providers.dart';
import 'widgets/solicitud_form_widgets.dart';

class NuevaSolicitudScreen extends ConsumerStatefulWidget {
  const NuevaSolicitudScreen({super.key});

  @override
  ConsumerState<NuevaSolicitudScreen> createState() =>
      _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends ConsumerState<NuevaSolicitudScreen> {
  CanalVenta? _canal;

  final _clienteSearchController = TextEditingController();
  Cliente? _clienteSeleccionado;
  bool _creandoNuevoCliente = false;
  final _nuevoNombreController = TextEditingController();
  final _nuevoTelefonoController = TextEditingController();
  final _nuevoDireccionController = TextEditingController();

  final List<ProductoFormRow> _productos = [ProductoFormRow()];

  EstadoPedido _estadoPedidoInicial = EstadoPedido.pendiente;

  final _notasController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(busquedaClienteProvider.notifier).state = '';
    });
  }

  @override
  void dispose() {
    _clienteSearchController.dispose();
    _nuevoNombreController.dispose();
    _nuevoTelefonoController.dispose();
    _nuevoDireccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  double get _total => _productos.fold(0, (sum, item) => sum + item.subtotal);

  bool get _puedeGuardar =>
      _canal != null &&
      _clienteSeleccionado != null &&
      _productos.isNotEmpty &&
      _productos.every((p) => p.esValido);

  bool get _hayCambios {
    if (_canal != null) return true;
    if (_clienteSeleccionado != null) return true;
    if (_notasController.text.trim().isNotEmpty) return true;
    if (_estadoPedidoInicial != EstadoPedido.pendiente) return true;
    if (_productos.length > 1) return true;
    final fila = _productos.first;
    return fila.producto != null || fila.cantidad != 1 || fila.esPromo;
  }

  Future<void> _crearCliente() async {
    final nombre = _nuevoNombreController.text.trim();
    final telefono = _nuevoTelefonoController.text.trim();
    if (nombre.isEmpty || telefono.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa al menos nombre y teléfono del cliente.';
      });
      return;
    }

    final cliente = Cliente(
      id: const Uuid().v4(),
      nombre: nombre,
      telefono: telefono,
      direccion: _nuevoDireccionController.text.trim(),
      fechaRegistro: DateTime.now(),
    );

    await ref.read(clientesRepositoryProvider).crearCliente(cliente);

    setState(() {
      _clienteSeleccionado = cliente;
      _creandoNuevoCliente = false;
      _errorMessage = null;
    });
  }

  void _agregarProducto() {
    setState(() => _productos.add(ProductoFormRow()));
  }

  void _quitarProducto(int index) {
    setState(() => _productos.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_puedeGuardar) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productoItems = _productos.map((row) {
        return ProductoItem(
          productoId: row.producto!.id,
          nombre: row.producto!.nombre,
          cantidad: row.cantidad,
          esPromo: row.esPromo,
          precioUnitario: row.precioUnitario,
          subtotal: row.subtotal,
        );
      }).toList();

      final creadoPor = ref.read(authRepositoryProvider).currentUser!.email!;

      final solicitud = Solicitud(
        id: const Uuid().v4(),
        clienteId: _clienteSeleccionado!.id,
        clienteNombre: _clienteSeleccionado!.nombre,
        canal: _canal!,
        productos: productoItems,
        total: _total,
        estadoPedido: _estadoPedidoInicial,
        estadoPago: EstadoPago.pendiente,
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        fechaCreacion: DateTime.now(),
        creadoPor: creadoPor,
      );

      await ref.read(solicitudesRepositoryProvider).crearSolicitud(solicitud);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Solicitud creada exitosamente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo guardar la solicitud. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final descartar = await confirmarDescartarCambios(context);
        if (descartar && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Nueva Solicitud')),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SeccionTitulo('1. Canal de venta'),
            const SizedBox(height: 8),
            SelectorCanal(
              canal: _canal,
              onChanged: (canal) => setState(() => _canal = canal),
            ),
            const SizedBox(height: 24),
            const SeccionTitulo('2. Cliente'),
            const SizedBox(height: 8),
            SelectorCliente(
              searchController: _clienteSearchController,
              clienteSeleccionado: _clienteSeleccionado,
              creandoNuevoCliente: _creandoNuevoCliente,
              nombreController: _nuevoNombreController,
              telefonoController: _nuevoTelefonoController,
              direccionController: _nuevoDireccionController,
              onClienteSeleccionado: (cliente) {
                setState(() {
                  _clienteSeleccionado = cliente;
                  _creandoNuevoCliente = false;
                });
              },
              onCambiarCliente: () {
                setState(() {
                  _clienteSeleccionado = null;
                  _clienteSearchController.clear();
                  ref.read(busquedaClienteProvider.notifier).state = '';
                });
              },
              onCrearNuevo: () => setState(() => _creandoNuevoCliente = true),
              onGuardarNuevoCliente: _crearCliente,
              onCancelarNuevoCliente: () =>
                  setState(() => _creandoNuevoCliente = false),
            ),
            const SizedBox(height: 24),
            const SeccionTitulo('3. Productos'),
            const SizedBox(height: 8),
            for (var i = 0; i < _productos.length; i++) ...[
              ProductoRowWidget(
                row: _productos[i],
                puedeEliminar: _productos.length > 1,
                onChanged: () => setState(() {}),
                onEliminar: () => _quitarProducto(i),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar otro producto'),
            ),
            const SizedBox(height: 24),
            const SeccionTitulo('4. Estado del pedido'),
            const SizedBox(height: 8),
            SegmentedButton<EstadoPedido>(
              segments: const [
                ButtonSegment(
                  value: EstadoPedido.pendiente,
                  label: Text('Pendiente'),
                ),
                ButtonSegment(
                  value: EstadoPedido.entregado,
                  label: Text('Entregado'),
                ),
              ],
              selected: {_estadoPedidoInicial},
              onSelectionChanged: (selection) {
                setState(() => _estadoPedidoInicial = selection.first);
              },
            ),
            const SizedBox(height: 24),
            const SeccionTitulo('5. Notas (opcional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notasController,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Notas adicionales sobre la solicitud...',
              ),
            ),
            const SizedBox(height: 24),
            const SeccionTitulo('6. Total de la solicitud'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.foam,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.steam),
              ),
              child: Text(
                'Total: Q${_total.toStringAsFixed(2)}',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.caramel,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _puedeGuardar && !_isLoading ? _guardar : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.foam,
                        ),
                      )
                    : const Text('Guardar Solicitud'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
