import 'producto.dart';
import 'estado_producto.dart';

class ProductoResumen {
  final Producto producto;
  final String categoriaNombre;
  final int stockTotal;
  final DateTime? proximaCaducidad;
  final EstadoProducto estado;
  final String? ultimaTiendaNombre;

  ProductoResumen({
    required this.producto,
    required this.categoriaNombre,
    required this.stockTotal,
    this.proximaCaducidad,
    required this.estado,
    this.ultimaTiendaNombre,
  });
}