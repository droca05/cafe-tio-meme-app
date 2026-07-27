import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/producto_model.dart';
import '../providers/productos_providers.dart';

Future<bool> _confirmarDescartarCambios(BuildContext context) async {
  final descartar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Descartar cambios?'),
      content: const Text(
        'Tienes cambios sin guardar. Si sales ahora los perderás.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Seguir editando',
            style: TextStyle(color: AppColors.caramel),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Descartar',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
  return descartar ?? false;
}

class EditarProductoScreen extends ConsumerStatefulWidget {
  final String productoId;

  const EditarProductoScreen({super.key, required this.productoId});

  @override
  ConsumerState<EditarProductoScreen> createState() =>
      _EditarProductoScreenState();
}

class _EditarProductoScreenState extends ConsumerState<EditarProductoScreen> {
  bool _inicializado = false;

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioNormalController = TextEditingController();
  final _precioPromoController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  late String _nombreInicial;
  late String _descripcionInicial;
  late String _precioNormalInicial;
  late String _precioPromoInicial;

  void _inicializar(Producto producto) {
    _nombreController.text = producto.nombre;
    _descripcionController.text = producto.descripcion;
    _precioNormalController.text = producto.precioNormal.toStringAsFixed(2);
    _precioPromoController.text = producto.precioPromo == null
        ? ''
        : producto.precioPromo!.toStringAsFixed(2);

    _nombreInicial = _nombreController.text;
    _descripcionInicial = _descripcionController.text;
    _precioNormalInicial = _precioNormalController.text;
    _precioPromoInicial = _precioPromoController.text;

    _inicializado = true;
  }

  bool get _hayCambios {
    if (!_inicializado) return false;
    return _nombreController.text != _nombreInicial ||
        _descripcionController.text != _descripcionInicial ||
        _precioNormalController.text != _precioNormalInicial ||
        _precioPromoController.text != _precioPromoInicial;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioNormalController.dispose();
    _precioPromoController.dispose();
    super.dispose();
  }

  bool get _puedeGuardar =>
      _nombreController.text.trim().isNotEmpty &&
      double.tryParse(_precioNormalController.text.replaceAll(',', '.')) !=
          null;

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final precioNormal =
        double.tryParse(_precioNormalController.text.replaceAll(',', '.'));

    if (nombre.isEmpty || precioNormal == null) {
      setState(() {
        _errorMessage = 'Ingresa al menos nombre y precio normal.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final precioPromo = double.tryParse(
        _precioPromoController.text.replaceAll(',', '.'),
      );

      await ref.read(productosRepositoryProvider).actualizarProducto(
        widget.productoId,
        {
          'nombre': nombre,
          'descripcion': _descripcionController.text.trim(),
          'precioNormal': precioNormal,
          'precioPromo': precioPromo,
        },
      );

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
                'Producto actualizado exitosamente',
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
            'No se pudo actualizar el producto. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productoAsync = ref.watch(productoPorIdProvider(widget.productoId));

    return PopScope(
      canPop: !_hayCambios,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final descartar = await _confirmarDescartarCambios(context);
        if (descartar && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Editar producto')),
        body: productoAsync.when(
          data: (producto) {
            if (!_inicializado) _inicializar(producto);
            return _buildForm();
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text(
              'No se pudo cargar el producto.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nombreController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descripcionController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: 'ej: 350gr',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _precioNormalController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Precio normal',
              prefixText: 'Q',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _precioPromoController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Precio promo (opcional)',
              prefixText: 'Q',
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
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}
