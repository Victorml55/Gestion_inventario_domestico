import 'package:sqflite/sqflite.dart';
import '../../core/errors.dart';
import '../database/db_helper.dart';
import '../models/tienda.dart';
import 'tienda_repository.dart';

class TiendaRepositoryImpl implements TiendaRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<List<Tienda>> getTodos() async {
    final db = await _dbHelper.database;
    final res = await db.query('tienda', orderBy: 'nombre ASC');
    return res.map(Tienda.fromMap).toList();
  }

  @override
  Future<int> insertar(Tienda t) async {
    final db = await _dbHelper.database;
    try {
      return await db.insert('tienda', t.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Ya existe una tienda con ese nombre');
      }
      rethrow;
    }
  }

  @override
  Future<void> actualizar(Tienda t) async {
    final db = await _dbHelper.database;
    try {
      await db.update('tienda', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw AppException('Ya existe una tienda con ese nombre');
      }
      rethrow;
    }
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await _dbHelper.database;
    final compras = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM historial_compras WHERE tienda_id = ?', [id])) ??
        0;
    if (compras > 0) {
      throw AppException(
          'No se puede eliminar: tiene $compras compra(s) registradas');
    }
    await db.delete('tienda', where: 'id = ?', whereArgs: [id]);
  }
}
