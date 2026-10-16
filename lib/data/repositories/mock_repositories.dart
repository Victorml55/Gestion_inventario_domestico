import 'dart:async';
import '../../core/date_utils.dart';
import '../models/models.dart';
import 'carrito_repository.dart';
import 'producto_repository.dart';

class MockProductoRepository implements ProductoRepository {
  final _datos = <ProductoResumen>[
    ProductoResumen(
      producto: const Producto(id: 1, nombre: 'Leche entera', categoriaId: 1, unidad: 'L', stockMinimo: 2),
      categoriaNombre: 'Lácteos',
      stockTotal: 3,
      proximaCaducidad: hoy().add(const Duration(days: 2)),
      estado: EstadoProducto.porCaducar,
      ultimaTiendaNombre: 'Walmart',
    ),
    ProductoResumen(
      producto: const Producto(id: 2, nombre: 'Yogurt', categoriaId: 1),
      categoriaNombre: 'Lácteos',
      stockTotal: 1,
      proximaCaducidad: hoy().subtract(const Duration(days: 1)),
      estado: EstadoProducto.caducado,
    ),
    const ProductoResumen(
      producto: Producto(id: 3, nombre: 'Arroz', categoriaId: 4, unidad: 'kg', stockMinimo: 2),
      categoriaNombre: 'Despensa',
      stockTotal: 1,
      proximaCaducidad: null,
      estado: EstadoProducto.porAgotarse,
    ),
    const ProductoResumen(
      producto: Producto(id: 4, nombre: 'Atún', categoriaId: 4),
      categoriaNombre: 'Despensa',
      stockTotal: 0,
      proximaCaducidad: null,
      estado: EstadoProducto.sinExistencia,
    ),
  ];

  @override
  Future<List<ProductoResumen>> getAlertas() async => _datos;

  @override
  Future<List<ProductoResumen>> getTodos({int? categoriaId}) async => _datos;
}

class MockCarritoRepository implements CarritoRepository {
  final _items = <int, int>{};
  final _ctrl = StreamController<int>.broadcast();

  void _emit() => _ctrl.add(_items.values.fold(0, (a, b) => a + b));

  @override
  Stream<int> watchCantidad() async* {
    yield _items.values.fold<int>(0, (a, b) => a + b);
    yield* _ctrl.stream;
  }

  @override
  Future<void> agregar(int productoId, {int cantidad = 1}) async {
    _items.update(productoId, (v) => v + cantidad, ifAbsent: () => cantidad);
    _emit();
  }

  @override
  Future<void> quitar(int productoId) async {
    _items.remove(productoId);
    _emit();
  }

  @override
  Future<void> vaciar() async {
    _items.clear();
    _emit();
  }
}