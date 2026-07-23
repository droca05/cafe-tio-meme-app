import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../clientes/domain/cliente_model.dart';
import '../../../clientes/providers/clientes_providers.dart';
import '../../domain/enums.dart';
import '../../domain/producto_catalogo.dart';
import '../../domain/solicitud_model.dart';

class ProductoFormRow {
  ProductoCatalogo? producto;
  int cantidad = 1;
  bool esPromo = false;

  ProductoFormRow();

  factory ProductoFormRow.desde(ProductoItem item) {
    return ProductoFormRow()
      ..producto = buscarProductoCatalogo(item.productoId)
      ..cantidad = item.cantidad
      ..esPromo = item.esPromo;
  }

  bool get esValido => producto != null && cantidad > 0;

  double get precioUnitario => producto?.precioEfectivo(esPromo: esPromo) ?? 0;

  double get subtotal => precioUnitario * cantidad;
}

class SeccionTitulo extends StatelessWidget {
  final String texto;

  const SeccionTitulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(texto, style: AppTextStyles.bodyMedium500);
  }
}

class SelectorCanal extends StatelessWidget {
  final CanalVenta? canal;
  final ValueChanged<CanalVenta> onChanged;

  const SelectorCanal({super.key, required this.canal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CanalBoton(
            icono: Icons.handshake_outlined,
            label: 'Venta Directa',
            seleccionado: canal == CanalVenta.ventaDirecta,
            colorFondo: AppColors.directaBg,
            colorTexto: AppColors.directaText,
            onTap: () => onChanged(CanalVenta.ventaDirecta),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CanalBoton(
            icono: Icons.share_outlined,
            label: 'FORZA',
            seleccionado: canal == CanalVenta.forza,
            colorFondo: AppColors.forzaBg,
            colorTexto: AppColors.forzaText,
            onTap: () => onChanged(CanalVenta.forza),
          ),
        ),
      ],
    );
  }
}

class CanalBoton extends StatelessWidget {
  final IconData icono;
  final String label;
  final bool seleccionado;
  final Color colorFondo;
  final Color colorTexto;
  final VoidCallback onTap;

  const CanalBoton({
    super.key,
    required this.icono,
    required this.label,
    required this.seleccionado,
    required this.colorFondo,
    required this.colorTexto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: seleccionado ? colorFondo : AppColors.foam,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? colorTexto : AppColors.steam,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 28,
              color: seleccionado ? colorTexto : AppColors.espresso,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium500.copyWith(
                color: seleccionado ? colorTexto : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductoRowWidget extends StatelessWidget {
  final ProductoFormRow row;
  final bool puedeEliminar;
  final VoidCallback onChanged;
  final VoidCallback onEliminar;

  const ProductoRowWidget({
    super.key,
    required this.row,
    required this.puedeEliminar,
    required this.onChanged,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.foam,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.steam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ProductoCatalogo>(
                  initialValue: row.producto,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Producto'),
                  items: catalogoProductos.map((producto) {
                    return DropdownMenuItem(
                      value: producto,
                      child: Text(
                        producto.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (producto) {
                    row.producto = producto;
                    if (producto?.precioPromo == null) {
                      row.esPromo = false;
                    }
                    onChanged();
                  },
                ),
              ),
              if (puedeEliminar)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: onEliminar,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Cantidad', style: AppTextStyles.bodyMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: row.cantidad > 1
                    ? () {
                        row.cantidad--;
                        onChanged();
                      }
                    : null,
              ),
              Text('${row.cantidad}', style: AppTextStyles.bodyMedium500),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  row.cantidad++;
                  onChanged();
                },
              ),
            ],
          ),
          Row(
            children: [
              Text('Aplicar precio promo', style: AppTextStyles.bodyMedium),
              const Spacer(),
              Switch(
                value: row.esPromo,
                activeThumbColor: AppColors.caramel,
                onChanged: row.producto?.precioPromo == null
                    ? null
                    : (value) {
                        row.esPromo = value;
                        onChanged();
                      },
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: Q${row.subtotal.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium500.copyWith(
                color: AppColors.caramel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectorCliente extends ConsumerWidget {
  final TextEditingController searchController;
  final Cliente? clienteSeleccionado;
  final bool creandoNuevoCliente;
  final TextEditingController nombreController;
  final TextEditingController telefonoController;
  final TextEditingController direccionController;
  final ValueChanged<Cliente> onClienteSeleccionado;
  final VoidCallback onCambiarCliente;
  final VoidCallback onCrearNuevo;
  final VoidCallback onGuardarNuevoCliente;
  final VoidCallback onCancelarNuevoCliente;

  const SelectorCliente({
    super.key,
    required this.searchController,
    required this.clienteSeleccionado,
    required this.creandoNuevoCliente,
    required this.nombreController,
    required this.telefonoController,
    required this.direccionController,
    required this.onClienteSeleccionado,
    required this.onCambiarCliente,
    required this.onCrearNuevo,
    required this.onGuardarNuevoCliente,
    required this.onCancelarNuevoCliente,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (clienteSeleccionado != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.foam,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.steam),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clienteSeleccionado!.nombre,
                    style: AppTextStyles.bodyMedium500,
                  ),
                  Text(
                    clienteSeleccionado!.telefono,
                    style: AppTextStyles.bodyLight,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onCambiarCliente,
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
    }

    if (creandoNuevoCliente) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: telefonoController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: direccionController,
            decoration: const InputDecoration(labelText: 'Dirección'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancelarNuevoCliente,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onGuardarNuevoCliente,
                  child: const Text('Guardar cliente'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final query = ref.watch(busquedaClienteProvider);
    final mostrarSugerencias = query.trim().isNotEmpty;
    final clientesAsync =
        mostrarSugerencias ? ref.watch(clientesBuscadosProvider) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o teléfono',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            ref.read(busquedaClienteProvider.notifier).state = value;
          },
        ),
        const SizedBox(height: 8),
        if (clientesAsync == null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add, color: AppColors.caramel),
            title: const Text(
              'Crear nuevo cliente',
              style: TextStyle(color: AppColors.caramel),
            ),
            onTap: onCrearNuevo,
          )
        else
          clientesAsync.when(
            data: (clientes) => Column(
              children: [
                for (final cliente in clientes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(cliente.nombre),
                    subtitle: Text(cliente.telefono),
                    onTap: () => onClienteSeleccionado(cliente),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add, color: AppColors.caramel),
                  title: const Text(
                    'Crear nuevo cliente',
                    style: TextStyle(color: AppColors.caramel),
                  ),
                  onTap: onCrearNuevo,
                ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
      ],
    );
  }
}
