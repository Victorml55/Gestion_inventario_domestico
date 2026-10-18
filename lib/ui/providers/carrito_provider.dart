import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/repositories/carrito_repository.dart';
import '../../data/repositories/producto_repository.dart';

class CarritoLinea {
  final ProductoResumen producto;
  final int cantidad;
  const CarritoLinea({required this.producto, required this.cantidad});
}

class CarritoProvider extends ChangeNotifier {
  final CarritoRepository _repo;
  final ProductoRepository _productos;
  CarritoProvider(this._repo, this._productos);

  List<CarritoLinea> lineas = [];
  bool cargando = false;

  Future<void> cargar() async {
    cargando = true;
    notifyListeners();
    final items = await _repo.getItems();
    final todos = await _productos.getTodos();
    final porId = {for (final r in todos) r.producto.id!: r};
    lineas = [
      for (final it in items)
        if (porId.containsKey(it.productoId))
          CarritoLinea(producto: porId[it.productoId]!, cantidad: it.cantidad),
    ];
    cargando = false;
    notifyListeners();
  }

  Future<void> cambiarCantidad(int id, int cantidad) async {
    await _repo.cambiarCantidad(id, cantidad);
    await cargar();
  }

  Future<void> quitar(int id) async {
    await _repo.quitar(id);
    await cargar();
  }

  Future<void> vaciar() async {
    await _repo.vaciar();
    await cargar();
  }
}