import '../../core/date_utils.dart';
import '../models/estado_producto.dart';
import '../models/producto_resumen.dart';
import 'calendario_repository.dart';
import 'producto_repository.dart';

class CalendarioRepositoryImpl implements CalendarioRepository {
  final ProductoRepository _productoRepo;

  CalendarioRepositoryImpl(this._productoRepo);

  @override
  Future<Map<DateTime, List<ProductoResumen>>> getAlertasPorDia() async {
    final alertas = await _productoRepo.getAlertas();
    final Map<DateTime, List<ProductoResumen>> mapa = {};

    for (final p in alertas) {
      final f = p.proximaCaducidad;
      if (f == null) continue;
      // Solo caducados y por caducar tienen un día relevante en el calendario
      if (p.estado != EstadoProducto.caducado &&
          p.estado != EstadoProducto.porCaducar) {
        continue;
      }
      mapa.putIfAbsent(normalizarFecha(f), () => []).add(p);
    }
    return mapa;
  }

  @override
  Future<List<ProductoResumen>> getAlertasDeDia(DateTime dia) async {
    final mapa = await getAlertasPorDia();
    return mapa[normalizarFecha(dia)] ?? [];
  }
}
