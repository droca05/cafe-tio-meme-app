import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/producto_model.dart';
import '../providers/productos_providers.dart';

class NuevoProductoScreen extends ConsumerStatefulWidget {
  const NuevoProductoScreen({super.key});

  @override
  ConsumerState<NuevoProductoScreen> createState() =>
      _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends ConsumerState<NuevoProductoScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioNormalController = TextEditingController();
  final _precioPromoController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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

      final producto = Producto(
        id: '',
        nombre: nombre,
        descripcion: _descripcionController.text.trim(),
        precioNormal: precioNormal,
        precioPromo: precioPromo,
        activo: true,
      );

      await ref.read(productosRepositoryProvider).agregarProducto(producto);

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
                'Producto agregado exitosamente',
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
        _errorMessage = 'No se pudo guardar el producto. Intenta nuevamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Nuevo producto')),
      body: SingleChildScrollView(
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
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
