import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/repositories/producto_repository.dart';

class InventarioProvider extends ChangeNotifier {
  final ProductoRepository _repo;
  InventarioProvider(this._repo);

  List<ProductoResumen> alertas = [];
  bool cargando = false;
  String? error;

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
}