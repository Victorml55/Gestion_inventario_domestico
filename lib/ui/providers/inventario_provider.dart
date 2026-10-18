import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/repositories/producto_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final ProductoRepository _repo;
  InventarioProvider(this._repo);

  // Pantalla principal (solo alertas)
  List<ProductoResumen> alertas = [];
  bool cargando = false;
  String? error;

  // Inventario completo
  List<ProductoResumen> todos = [];
  int? categoriaFiltro;
  bool cargandoTodos = false;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      alertas = await _repo.getAlertas();
    } catch (e) {
      error = e.toString();
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> cargarTodos({int? categoriaId}) async {
    categoriaFiltro = categoriaId;
    cargandoTodos = true;
    notifyListeners();
    try {
      todos = await _repo.getTodos(categoriaId: categoriaId);
    } catch (e) {
      error = e.toString();
    }
    cargandoTodos = false;
    notifyListeners();
  }
}