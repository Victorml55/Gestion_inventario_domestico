import '../models/models.dart';

abstract class TiendaRepository {
  Future<List<Tienda>> getTodos();
  Future<int> insertar(Tienda t);
  Future<void> actualizar(Tienda t);

  /// Lanza AppException si la tienda tiene compras registradas.
  Future<void> eliminar(int id);
}
