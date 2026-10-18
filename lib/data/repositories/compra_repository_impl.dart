import '../database/db_helper.dart';
import '../models/historial_compra.dart';
import '../models/lote.dart';
import '../models/tienda.dart';
import '../services/notification_service.dart';
import 'compra_repository.dart';

class CompraRepositoryImpl implements CompraRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<void> registrarCompraConLote(HistorialCompra c, Lote l) async {
    final db = await _dbHelper.database;
    late int loteId;

    await db.transaction((txn) async {
      // 1. Insertar compra
      await txn.insert('historial_compras', c.toMap());

      // 2. Actualizar última tienda del producto
      await txn.update(
        'producto',
        {'ultima_tienda_id': c.tiendaId},
        where: 'id = ?',
        whereArgs: [c.productoId],
      );

      // 3. Insertar lote
      loteId = await txn.insert('lote', l.toMap());
    });

    // 4. Alarma de caducidad del lote (fuera de la transacción)
    if (l.alarmaActiva && l.fechaCaducidad != null) {
      try {
        final r = await db.query('producto',
            columns: ['nombre'], where: 'id = ?', whereArgs: [c.productoId]);
        if (r.isNotEmpty) {
          await NotificationService.programarAlarma(
              loteId, r.first['nombre'] as String, l.fechaCaducidad!);
        }
      } catch (_) {
        // una falla de notificación no debe invalidar la compra
      }
    }
  }

  @override
  Future<List<Tienda>> getTiendasDeProducto(int productoId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tienda t
      INNER JOIN historial_compras h ON t.id = h.tienda_id
      WHERE h.producto_id = ?
      ORDER BY t.nombre ASC
    ''', [productoId]);

    return res.map((e) => Tienda.fromMap(e)).toList();
  }

  @override
  Future<List<HistorialCompra>> getHistorial({int? productoId}) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      'historial_compras',
      where: productoId != null ? 'producto_id = ?' : null,
      whereArgs: productoId != null ? [productoId] : null,
      orderBy: 'fecha_compra DESC, id DESC',
    );
    return res.map((e) => HistorialCompra.fromMap(e)).toList();
  }
}
