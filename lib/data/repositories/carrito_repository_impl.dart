import 'dart:async';
import '../database/db_helper.dart';
import '../models/carrito_item.dart';
import 'carrito_repository.dart';

class CarritoRepositoryImpl implements CarritoRepository {
  final DbHelper _dbHelper = DbHelper();
  final _controller = StreamController<int>.broadcast();

  Future<int> _total() async {
    final db = await _dbHelper.database;
    final res =
        await db.rawQuery('SELECT SUM(cantidad) as total FROM carrito_item');
    return (res.first['total'] as int?) ?? 0;
  }

  Future<void> _emitirConteo() async => _controller.add(await _total());

  @override
  Stream<int> watchCantidad() async* {
    yield await _total();
    yield* _controller.stream;
  }

  @override
  Future<List<CarritoItem>> getItems() async {
    final db = await _dbHelper.database;
    final res = await db.query('carrito_item');
    return res.map(CarritoItem.fromMap).toList();
  }

  @override
  Future<void> agregar(int productoId, {int cantidad = 1}) async {
    final db = await _dbHelper.database;
    final res = await db
        .query('carrito_item', where: 'producto_id = ?', whereArgs: [productoId]);
    if (res.isNotEmpty) {
      final item = CarritoItem.fromMap(res.first);
      await db.update('carrito_item', {'cantidad': item.cantidad + cantidad},
          where: 'id = ?', whereArgs: [item.id]);
    } else {
      await db.insert(
          'carrito_item', {'producto_id': productoId, 'cantidad': cantidad});
    }
    await _emitirConteo();
  }

  @override
  Future<void> cambiarCantidad(int productoId, int cantidad) async {
    final db = await _dbHelper.database;
    if (cantidad <= 0) {
      await db.delete('carrito_item',
          where: 'producto_id = ?', whereArgs: [productoId]);
    } else {
      await db.update('carrito_item', {'cantidad': cantidad},
          where: 'producto_id = ?', whereArgs: [productoId]);
    }
    await _emitirConteo();
  }

  @override
  Future<void> quitar(int productoId) async {
    final db = await _dbHelper.database;
    await db.delete('carrito_item',
        where: 'producto_id = ?', whereArgs: [productoId]);
    await _emitirConteo();
  }

  @override
  Future<void> vaciar() async {
    final db = await _dbHelper.database;
    await db.delete('carrito_item');
    await _emitirConteo();
  }
}
