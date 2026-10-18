import '../models/historial_compra.dart';
import '../models/tienda.dart';
import '../models/lote.dart';

abstract class CompraRepository {
  Future<void> registrarCompraConLote(HistorialCompra c, Lote l);
  Future<List<Tienda>> getTiendasDeProducto(int productoId);
  Future<List<HistorialCompra>> getHistorial({int? productoId});
}