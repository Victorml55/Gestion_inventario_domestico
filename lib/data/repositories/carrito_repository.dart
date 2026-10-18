import '../models/models.dart';

class CarritoLinea {
  final ProductoResumen producto;
  final int cantidad;
  const CarritoLinea({required this.producto, required this.cantidad});
}

abstract class CarritoRepository {
  Stream<int> watchCantidad();
  Future<List<CarritoLinea>> getLineas();
  Future<void> agregar(int productoId, {int cantidad = 1});
  Future<void> cambiarCantidad(int productoId, int cantidad);
  Future<void> quitar(int productoId);
  Future<void> vaciar();
}