import '../../core/date_utils.dart';
import '../models/producto_resumen.dart';
import 'calendario_repository.dart';
import 'producto_repository.dart';
import '../models/estado_producto.dart';

class CalendarioRepositoryImpl implements CalendarioRepository {
  final ProductoRepository _productoRepo;

  CalendarioRepositoryImpl(this._productoRepo);

  @override
  Future<Map<DateTime, List<ProductoResumen>>> getAlertasPorDia() async {
    final alertas = await _productoRepo.getAlertas();
    final Map<DateTime, List<ProductoResumen>> mapa = {};

    for (var p in alertas) {
      if (p.proximaCaducidad != null &&
    (p.estado == EstadoProducto.caducado ||
        p.estado == EstadoProducto.porCaducar)) {
        final fecha = normalizarFecha(p.proximaCaducidad!);
        if (!mapa.containsKey(fecha)) mapa[fecha] = [];
        mapa[fecha]!.add(p);
      }
    }
    return mapa;
  }

  @override
  Future<List<ProductoResumen>> getAlertasDeDia(DateTime dia) async {
    final mapa = await getAlertasPorDia();
    return mapa[normalizarFecha(dia)] ?? [];
  }
}