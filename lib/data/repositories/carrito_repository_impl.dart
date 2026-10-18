import 'dart:async';
import '../database/db_helper.dart';
import '../models/carrito_item.dart';
import 'carrito_repository.dart';

class CarritoRepositoryImpl implements CarritoRepository {
  final DbHelper _dbHelper = DbHelper();
  final _controller = StreamController<int>.broadcast();

  CarritoRepositoryImpl() {
    _emitirConteo(); // Carga inicial
  }

  Future<void> _emitirConteo() async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('SELECT SUM(cantidad) as total FROM carrito_item');
    final total = (res.first['total'] as int?) ?? 0;
    _controller.add(total);
  }

  @override
  Stream<int> watchCantidad() => _controller.stream;

  @override
  Future<List<CarritoItem>> getItems() async {
    final db = await _dbHelper.database;
    final res = await db.query('carrito_item');
    return res.map((e) => CarritoItem.fromMap(e)).toList();
  }

  @override
  Future<void> agregar(int productoId, {int cantidad = 1}) async {
    final db = await _dbHelper.database;
    
    // Verificar si ya existe
    final res = await db.query('carrito_item', where: 'producto_id = ?', whereArgs: [productoId]);
    if (res.isNotEmpty) {
      final item = CarritoItem.fromMap(res.first);
      await db.update(
        'carrito_item', 
        {'cantidad': item.cantidad + cantidad}, 
        where: 'id = ?', 
        whereArgs: [item.id]
      );
    } else {
      await db.insert('carrito_item', {'producto_id': productoId, 'cantidad': cantidad});
    }
    _emitirConteo();
  }

  @override
  Future<void> quitar(int productoId) async {
    final db = await _dbHelper.database;
    await db.delete('carrito_item', where: 'producto_id = ?', whereArgs: [productoId]);
    _emitirConteo();
  }

  @override
  Future<void> vaciar() async {
    final db = await _dbHelper.database;
    await db.delete('carrito_item');
    _emitirConteo();
  }
}