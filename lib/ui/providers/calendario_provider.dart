import 'package:flutter/foundation.dart';
import '../../core/date_utils.dart';
import '../../data/models/models.dart';
import '../../data/repositories/calendario_repository.dart';

class CalendarioProvider extends ChangeNotifier {
  final CalendarioRepository _repo;
  CalendarioProvider(this._repo);

  Map<DateTime, List<ProductoResumen>> _eventos = {};
  DateTime diaEnfocado = hoy();
  DateTime? diaSeleccionado;
  bool cargando = false;
  String? error;

  List<ProductoResumen> eventosDe(DateTime dia) => _eventos[soloFecha(dia)] ?? [];

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _eventos = await _repo.getAlertasPorDia();
    } catch (e) {
      error = e.toString();
    }
    cargando = false;
    notifyListeners();
  }

  void seleccionar(DateTime seleccionado, DateTime enfocado) {
    diaSeleccionado = soloFecha(seleccionado);
    diaEnfocado = enfocado;
    notifyListeners();
  }

  void cambiarEnfoque(DateTime d) => diaEnfocado = d;
}