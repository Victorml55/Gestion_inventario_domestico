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

  /// Agrega al carrito los productos agotados o por agotarse que aún no
  /// están en la lista. Devuelve cuántos agregó.
  Future<int> agregarSugeridos() async {
    final items = await _repo.getItems();
    final yaEn = items.map((i) => i.productoId).toSet();
    final alertas = await _productos.getAlertas();
    var n = 0;
    for (final r in alertas) {
      final falta = r.estado == EstadoProducto.sinExistencia ||
          r.estado == EstadoProducto.porAgotarse;
      if (!falta || yaEn.contains(r.producto.id)) continue;
      final faltan = r.producto.stockMinimo - r.stockTotal + 1;
      await _repo.agregar(r.producto.id!, cantidad: faltan < 1 ? 1 : faltan);
      n++;
    }
    await cargar();
    return n;
  }
}
