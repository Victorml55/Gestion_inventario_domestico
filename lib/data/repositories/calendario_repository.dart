import '../models/models.dart';

abstract class CalendarioRepository {
  /// fecha normalizada a medianoche.
  Future<Map<DateTime, List<ProductoResumen>>> getAlertasPorDia();
  Future<List<ProductoResumen>> getAlertasDeDia(DateTime dia);
}