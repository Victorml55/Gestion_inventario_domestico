import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../../core/errors.dart';
import '../database/db_helper.dart';
import '../models/estado_producto.dart';
import '../models/producto.dart';
import '../models/producto_resumen.dart';
import 'producto_repository.dart';

class ProductoRepositoryImpl implements ProductoRepository {
  final DbHelper _dbHelper = DbHelper();

  @override
  Future<List<ProductoResumen>> getAlertas() async {
    final todos = await getTodos();
    return todos.where((p) => p.estado != EstadoProducto.normal).toList();
  }

  @override
  Future<List<ProductoResumen>> getTodos({int? categoriaId}) async {
    final db = await _dbHelper.database;
    
    String where = '';
    List<dynamic> whereArgs = [];
    if (categoriaId != null) {
      where = 'WHERE p.categoria_id = ?';
      whereArgs.add(categoriaId);
    }

    final res = await db.rawQuery('''
      SELECT p.*, c.nombre as cat_nombre, t.nombre as tienda_nombre,
             (SELECT SUM(cantidad) FROM lote WHERE producto_id = p.id AND cantidad > 0) as stock_total,
             (SELECT MIN(fecha_caducidad) FROM lote WHERE producto_id = p.id AND cantidad > 0) as prox_caducidad
      FROM producto p
      LEFT JOIN categoria c ON p.categoria_id = c.id
      LEFT JOIN tienda t ON p.ultima_tienda_id = t.id
      $where
    ''', whereArgs);

    List<ProductoResumen> lista = [];
    final hoyDate = hoy();

    for (var row in res) {
      final p = Producto.fromMap(row);
      final stockTotal = (row['stock_total'] as int?) ?? 0;
      final proxCadStr = row['prox_caducidad'] as String?;
      final proxCad = proxCadStr != null ? sqlToDate(proxCadStr) : null;

      EstadoProducto estado = EstadoProducto.normal;

      if (stockTotal == 0) {
        estado = EstadoProducto.sinExistencia;
      } else if (proxCad != null && proxCad.isBefore(hoyDate)) {
        estado = EstadoProducto.caducado;
      } else if (proxCad != null && proxCad.difference(hoyDate).inDays <= kDiasPorCaducar) {
        estado = EstadoProducto.porCaducar;
      } else if (stockTotal <= p.stockMinimo) {
        estado = EstadoProducto.porAgotarse;
      }

      lista.add(ProductoResumen(
        producto: p,
        categoriaNombre: row['cat_nombre'] as String? ?? 'Sin categoría',
        stockTotal: stockTotal,
        proximaCaducidad: proxCad,
        estado: estado,
        ultimaTiendaNombre: row['tienda_nombre'] as String?,
      ));
    }
    return lista;
  }

  @override
  Future<ProductoResumen?> getById(int id) async {
    final lista = await getTodos();
    try {
      return lista.firstWhere((p) => p.producto.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> insertar(Producto p) async {
    final db = await _dbHelper.database;
    return await db.insert(DbTables.producto, p.toMap());
  }

  @override
  Future<void> actualizar(Producto p) async {
    final db = await _dbHelper.database;
    await db.update(DbTables.producto, p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  @override
  Future<void> eliminar(int id) async {
    final db = await _dbHelper.database;
    await db.delete(DbTables.producto, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> consumirStock(int productoId, int cantidad) async {
    if (cantidad <= 0) return;
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Verificar stock total
      final res = await txn.rawQuery(
          'SELECT SUM(cantidad) as total FROM lote WHERE producto_id = ? AND cantidad > 0',
          [productoId]);
      final total = (res.first['total'] as int?) ?? 0;

      if (total < cantidad) {
        throw AppException('No hay suficiente stock. Stock actual: $total');
      }

      // 2. Obtener lotes ordenados por FEFO (First Expired, First Out)
      final lotesRes = await txn.query(
        DbTables.lote,
        where: 'producto_id = ? AND cantidad > 0',
        whereArgs: [productoId],
        orderBy: 'fecha_caducidad ASC, id ASC', // FEFO
      );

      int restante = cantidad;
      for (var row in lotesRes) {
        if (restante <= 0) break;
        
        final loteId = row['id'] as int;
        final loteCant = row['cantidad'] as int;

        if (loteCant > restante) {
          await txn.update(DbTables.lote, {'cantidad': loteCant - restante}, where: 'id = ?', whereArgs: [loteId]);
          restante = 0;
        } else {
          await txn.update(DbTables.lote, {'cantidad': 0}, where: 'id = ?', whereArgs: [loteId]);
          restante -= loteCant;
        }
      }
    });
  }
}