import '../models/models.dart';

abstract class CategoriaRepository {
  Future<List<Categoria>> getTodos();
  Future<int> insertar(Categoria c);
  Future<void> actualizar(Categoria c);
  Future<void> eliminar(int id);
}