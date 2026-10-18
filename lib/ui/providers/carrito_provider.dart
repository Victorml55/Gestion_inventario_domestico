import 'package:flutter/foundation.dart';
import '../../data/repositories/carrito_repository.dart';

class CarritoProvider extends ChangeNotifier {
  final CarritoRepository _repo;
  CarritoProvider(this._repo);

  List<CarritoLinea> lineas = [];
  bool cargando = false;

  Future<void> cargar() async {
    cargando = true;
    notifyListeners();
    lineas = await _repo.getLineas();
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