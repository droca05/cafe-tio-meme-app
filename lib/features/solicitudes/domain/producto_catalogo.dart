import 'enums.dart';

class ProductoCatalogo {
  final String id;
  final String nombre;
  final String? descripcion; // ej. "Anacafé 14, lavado"
  final int? gramaje; // en gramos; null si no aplica (ej. Licor de Café)
  final List<PresentacionCafe> presentaciones; // vacío si no aplica presentación
  final double precioNormal;
  final double? precioPromo; // null si no tiene precio promocional

  const ProductoCatalogo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.gramaje,
    required this.presentaciones,
    required this.precioNormal,
    this.precioPromo,
  });

  double precioEfectivo({required bool esPromo}) {
    if (esPromo && precioPromo != null) {
      return precioPromo!;
    }
    return precioNormal;
  }
}

const List<ProductoCatalogo> catalogoProductos = [
  ProductoCatalogo(
    id: 'cafe-premium',
    nombre: 'Café Premium',
    descripcion: 'Anacafé 14, lavado',
    gramaje: 350,
    presentaciones: [PresentacionCafe.grano, PresentacionCafe.molido],
    precioNormal: 65,
    precioPromo: 55,
  ),
  ProductoCatalogo(
    id: 'cafe-clasico',
    nombre: 'Café Clásico',
    descripcion: 'Catuai, lavado',
    gramaje: 350,
    presentaciones: [PresentacionCafe.grano, PresentacionCafe.molido],
    precioNormal: 60,
    precioPromo: 50,
  ),
  ProductoCatalogo(
    id: 'cafe-campesino',
    nombre: 'Café Campesino',
    descripcion: 'Mezcla',
    gramaje: 400,
    presentaciones: [PresentacionCafe.molido],
    precioNormal: 35,
    precioPromo: 30,
  ),
  ProductoCatalogo(
    id: 'licor-cafe',
    nombre: 'Licor de Café',
    presentaciones: [],
    precioNormal: 80,
  ),
];

ProductoCatalogo? buscarProductoCatalogo(String id) {
  for (final producto in catalogoProductos) {
    if (producto.id == id) return producto;
  }
  return null;
}
