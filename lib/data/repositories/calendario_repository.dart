import '../models/producto_resumen.dart';

abstract class CalendarioRepository {
  Future<Map<DateTime, List<ProductoResumen>>> getAlertasPorDia();
  Future<List<ProductoResumen>> getAlertasDeDia(DateTime dia);
}