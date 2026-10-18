import 'package:sqflite/sqflite.dart';
import '../../core/errors.dart';
import '../database/db_helper.dart';
import '../models/categoria.dart';
import 'categoria_repository.dart';

class CategoriaRepositoryImpl implements CategoriaRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<List<Categoria>> getTodos() async {
    final db = await _dbHelper.database;
    final res = await db.query('categoria', orderBy: 'nombre ASC');
    return res.map(Categoria.fromMap).toList();
  }

  @override
  Future<int> insertar(Categoria c) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert('categoria', c.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Ya existe una categoría con ese nombre');
      }
      rethrow;
    }
  }

  @override
  Future<void> actualizar(Categoria c) async {
    final db = await _dbHelper.database;
    try {
      await db.update('categoria', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Ya existe una categoría con ese nombre');
      }
      rethrow;
    }
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await _dbHelper.database;
    final usados = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM producto WHERE categoria_id = ?', [id])) ??
        0;
    if (usados > 0) {
      throw AppException('No se puede eliminar: tiene $usados producto(s)');
    }
    await db.delete('categoria', where: 'id = ?', whereArgs: [id]);
  }
}
