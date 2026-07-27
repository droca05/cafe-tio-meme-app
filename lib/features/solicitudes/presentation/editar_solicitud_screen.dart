import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../clientes/domain/cliente_model.dart';
import '../../clientes/providers/clientes_providers.dart';
import '../../productos/domain/producto_model.dart';
import '../../productos/providers/productos_providers.dart';
import '../domain/enums.dart';
import '../domain/solicitud_model.dart';
import '../providers/solicitudes_providers.dart';
import 'widgets/solicitud_form_widgets.dart';

class EditarSolicitudScreen extends ConsumerStatefulWidget {
  final String solicitudId;

  const EditarSolicitudScreen({super.key, required this.solicitudId});

  @override
  ConsumerState<EditarSolicitudScreen> createState() =>
      _EditarSolicitudScreenState();
}

class _EditarSolicitudScreenState
    extends ConsumerState<EditarSolicitudScreen> {
  bool _inicializado = false;

  late CanalVenta _canal;

  late DateTime _horaBase;
  late DateTime _fecha;
  late DateTime _fechaInicial;

  final _clienteSearchController = TextEditingController();
  Cliente? _clienteSeleccionado;
  bool _creandoNuevoCliente = false;
  final _nuevoNombreController = TextEditingController();
  final _nuevoTelefonoController = TextEditingController();
  final _nuevoDireccionController = TextEditingController();

  final List<ProductoFormRow> _productos = [];

  final _notasController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late CanalVenta _canalInicial;
  String? _clienteIdInicial;
  late String _notasInicial;
  late List<String> _productosInicial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(busquedaClienteProvider.notifier).state = '';
    });
  }

  List<String> _snapshotProductos() {
    return _productos
        .map((p) => '${p.producto?.id}|${p.cantidad}|${p.esPromo}|${p.precioUnitario}')
        .toList();
  }

  void _inicializar(
    Solicitud solicitud,
    Cliente cliente,
    List<Producto> productosDisponibles,
  ) {
    final productosPorId = {for (final p in productosDisponibles) p.id: p};

    _canal = solicitud.canal;
    _horaBase = solicitud.fechaCreacion;
    _fecha = solicitud.fechaCreacion;
    _fechaInicial = solicitud.fechaCreacion;
    _clienteSeleccionado = cliente;
    _productos.addAll(
      solicitud.productos.map(
        (item) => ProductoFormRow.desde(item, productosPorId[item.productoId]),
      ),
    );
    if (_productos.isEmpty) _productos.add(ProductoFormRow());
    _notasController.text = solicitud.notas ?? '';

    _canalInicial = _canal;
    _clienteIdInicial = _clienteSeleccionado?.id;
    _notasInicial = _notasController.text.trim();
    _productosInicial = _snapshotProductos();

    _inicializado = true;
  }

  void _cambiarFecha(DateTime nuevaFecha) {
    setState(() {
      _fecha = DateTime(
        nuevaFecha.year,
        nuevaFecha.month,
        nuevaFecha.day,
        _horaBase.hour,
        _horaBase.minute,
        _horaBase.second,
      );
    });
  }

  bool get _hayCambios {
    if (!_inicializado) return false;
    if (_canal != _canalInicial) return true;
    if (_fecha != _fechaInicial) return true;
    if (_clienteSeleccionado?.id != _clienteIdInicial) return true;
    if (_notasController.text.trim() != _notasInicial) return true;
    final actuales = _snapshotProductos();
    if (actuales.length != _productosInicial.length) return true;
    for (var i = 0; i < actuales.length; i++) {
      if (actuales[i] != _productosInicial[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _clienteSearchController.dispose();
    _nuevoNombreController.dispose();
    _nuevoTelefonoController.dispose();
    _nuevoDireccionController.dispose();
    _notasController.dispose();
    for (final fila in _productos) {
      fila.dispose();
    }
    super.dispose();
  }

  double get _total => _productos.fold(0, (sum, item) => sum + item.subtotal);

  bool get _puedeGuardar =>
      _clienteSeleccionado != null &&
      _productos.isNotEmpty &&
      _productos.every((p) => p.esValido);

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
    setState(() => _productos.removeAt(index).dispose());
  }

  Future<void> _guardar(Solicitud original) async {
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

      final actualizada = Solicitud(
        id: original.id,
        clienteId: _clienteSeleccionado!.id,
        clienteNombre: _clienteSeleccionado!.nombre,
        canal: _canal,
        productos: productoItems,
        total: _total,
        estadoSolicitud: original.estadoSolicitud,
        estadoPago: original.estadoPago,
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        fechaCreacion: _fecha,
        creadoPor: original.creadoPor,
      );

      await ref
          .read(solicitudesRepositoryProvider)
          .actualizarSolicitud(actualizada);

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
                'Solicitud actualizada exitosamente',
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
        _errorMessage =
            'No se pudo actualizar la solicitud. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitudAsync =
        ref.watch(solicitudStreamProvider(widget.solicitudId));
    final productosAsync = ref.watch(productosActivosProvider);

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
        appBar: AppBar(title: const Text('Editar Solicitud')),
        body: solicitudAsync.when(
          data: (solicitud) {
            final clienteAsync =
                ref.watch(clienteStreamProvider(solicitud.clienteId));

            return clienteAsync.when(
              data: (cliente) => productosAsync.when(
                data: (productosDisponibles) {
                  if (!_inicializado) {
                    _inicializar(solicitud, cliente, productosDisponibles);
                  }
                  return _buildForm(solicitud, productosDisponibles);
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'No se pudieron cargar los productos.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'No se pudo cargar el cliente.',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'No se pudo cargar la solicitud.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Solicitud original, List<Producto> productosDisponibles) {
    return SingleChildScrollView(
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
          const SeccionTitulo('2. Fecha de la solicitud'),
          const SizedBox(height: 8),
          SelectorFecha(
            fecha: _fecha,
            onChanged: _cambiarFecha,
          ),
          const SizedBox(height: 24),
          const SeccionTitulo('3. Cliente'),
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
          const SeccionTitulo('4. Productos'),
          const SizedBox(height: 8),
          for (var i = 0; i < _productos.length; i++) ...[
            ProductoRowWidget(
              row: _productos[i],
              productosDisponibles: productosDisponibles,
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
              onPressed: _puedeGuardar && !_isLoading
                  ? () => _guardar(original)
                  : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.foam,
                      ),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ),
        ],
      ),
    );
  }
}
