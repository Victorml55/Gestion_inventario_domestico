abstract class CarritoRepository {
  Stream<int> watchCantidad();
  Future<void> agregar(int productoId, {int cantidad = 1});
  Future<void> quitar(int productoId);
  Future<void> vaciar();
}