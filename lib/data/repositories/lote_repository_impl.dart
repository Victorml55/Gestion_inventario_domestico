import '../database/db_helper.dart';
import '../models/lote.dart';
import '../services/notification_service.dart';
import 'lote_repository.dart';

class LoteRepositoryImpl implements LoteRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<List<Lote>> getPorProducto(int productoId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'lote',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha_caducidad IS NULL, fecha_caducidad ASC, id ASC',
    );
    return res.map(Lote.fromMap).toList();
  }

  @override
  Future<int> insertar(Lote l) async {
    final db = await _dbHelper.database;
    final id = await db.insert('lote', l.toMap());
    await _programar(id, l);
    return id;
  }

  @override
  Future<void> actualizar(Lote l) async {
    final db = await _dbHelper.database;
    await db.update('lote', l.toMap(), where: 'id = ?', whereArgs: [l.id]);
    if (l.id != null) await _programar(l.id!, l);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await _dbHelper.database;
    await db.delete('lote', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _programar(int id, Lote l) async {
    if (!l.alarmaActiva || l.fechaCaducidad == null) return;
    try {
      final db = await _dbHelper.database;
      final r = await db.query('producto',
          columns: ['nombre'], where: 'id = ?', whereArgs: [l.productoId]);
      if (r.isEmpty) return;
      await NotificationService.programarAlarma(
          id, r.first['nombre'] as String, l.fechaCaducidad!);
    } catch (_) {
      // una falla de notificación no debe impedir guardar el lote
    }
  }
}