import 'dart:async';
import '../models/carrito_item.dart';

abstract class CarritoRepository {
  Stream<int> watchCantidad();
  Future<List<CarritoItem>> getItems();
  Future<void> agregar(int productoId, {int cantidad = 1});
  Future<void> quitar(int productoId);
  Future<void> vaciar();
}