import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/producto_model.dart';
import '../providers/productos_providers.dart';

const _emailAdmin = 'julioroca92@gmail.com';

class ProductosScreen extends ConsumerWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).value;
    if (user?.email != _emailAdmin) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Productos')),
        body: Center(
          child: Text(
            'No tienes permiso para acceder a esta pantalla.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
          ),
        ),
      );
    }

    final productosAsync = ref.watch(productosTodosProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/productos/nuevo'),
          ),
        ],
      ),
      body: productosAsync.when(
        data: (productos) {
          if (productos.isEmpty) {
            return Center(
              child: Text(
                'No hay productos registrados aún',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              return _ProductoCard(producto: productos[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Ocurrió un error al cargar los productos.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}

class _ProductoCard extends ConsumerWidget {
  final Producto producto;

  const _ProductoCard({required this.producto});

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.espresso),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await ref.read(productosRepositoryProvider).eliminarProducto(producto.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: producto.activo ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/productos/${producto.id}/editar'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.roast,
                              ),
                            ),
                          ),
                          if (!producto.activo)
                            Text(
                              'Inactivo',
                              style: AppTextStyles.bodyMedium500.copyWith(
                                fontSize: 12,
                                color: AppColors.danger,
                              ),
                            ),
                        ],
                      ),
                      if (producto.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          producto.descripcion,
                          style: AppTextStyles.bodyLight.copyWith(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Q${producto.precioNormal.toStringAsFixed(2)}',
                            style: AppTextStyles.bodyMedium500.copyWith(
                              color: AppColors.espresso,
                            ),
                          ),
                          if (producto.precioPromo != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Q${producto.precioPromo!.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium500.copyWith(
                                color: AppColors.caramel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: producto.activo,
                      activeThumbColor: AppColors.caramel,
                      onChanged: (value) => ref
                          .read(productosRepositoryProvider)
                          .toggleActivo(producto.id, value),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      onPressed: () => _confirmarEliminar(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
