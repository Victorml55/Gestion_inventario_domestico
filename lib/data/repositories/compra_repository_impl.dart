import '../database/db_helper.dart';
import '../models/historial_compra.dart';
import '../models/lote.dart';
import '../models/tienda.dart';
import 'compra_repository.dart';

class CompraRepositoryImpl implements CompraRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<void> registrarCompraConLote(HistorialCompra c, Lote l) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // 1. Insertar compra
      await txn.insert('historial_compras', c.toMap());
      
      // 2. Actualizar última tienda del producto
      await txn.update(
        'producto', 
        {'ultima_tienda_id': c.tiendaId}, 
        where: 'id = ?', 
        whereArgs: [c.productoId]
      );
      
      // 3. Insertar lote
      await txn.insert('lote', l.toMap());
    });
  }

  @override
  Future<List<Tienda>> getTiendasDeProducto(int productoId) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT DISTINCT t.* FROM tienda t
      INNER JOIN historial_compras h ON t.id = h.tienda_id
      WHERE h.producto_id = ?
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
      orderBy: 'fecha_compra DESC',
    );
    return res.map((e) => HistorialCompra.fromMap(e)).toList();
  }
}