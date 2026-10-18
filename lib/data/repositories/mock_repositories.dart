import 'dart:async';
import '../../core/constants.dart';
import '../../core/date_utils.dart';
import '../models/models.dart';
import 'calendario_repository.dart';
import 'carrito_repository.dart';
import 'categoria_repository.dart';
import 'lote_repository.dart';
import 'producto_repository.dart';
import 'dart:math';
import '../../core/app_exception.dart';

// ======================= CATEGORÍAS =======================
class MockCategoriaRepository implements CategoriaRepository {
  static final List<Categoria> datos = [
    const Categoria(id: 1, nombre: 'Lácteos'),
    const Categoria(id: 2, nombre: 'Carnes'),
    const Categoria(id: 3, nombre: 'Frutas y verduras'),
    const Categoria(id: 4, nombre: 'Despensa'),
    const Categoria(id: 5, nombre: 'Bebidas'),
    const Categoria(id: 6, nombre: 'Limpieza'),
  ];
  int _next = 7;

  @override
  Future<List<Categoria>> getTodos() async => List.of(datos);

  @override
  Future<int> insertar(Categoria c) async {
    final id = _next++;
    datos.add(Categoria(id: id, nombre: c.nombre, icono: c.icono));
    return id;
  }

  @override
  Future<void> actualizar(Categoria c) async {
    final i = datos.indexWhere((x) => x.id == c.id);
    if (i >= 0) datos[i] = c;
  }

  @override
  Future<void> eliminar(int id) async => datos.removeWhere((x) => x.id == id);
}

// ======================= PRODUCTOS (almacén compartido) =======================
class MockProductoRepository implements ProductoRepository {
  int _nextProducto = 5;
  int _nextLote = 10;

  final List<Producto> _productos = [
    const Producto(id: 1, nombre: 'Leche entera', categoriaId: 1, unidad: 'L', stockMinimo: 2),
    const Producto(id: 2, nombre: 'Yogurt', categoriaId: 1),
    const Producto(id: 3, nombre: 'Arroz', categoriaId: 4, unidad: 'kg', stockMinimo: 2),
    const Producto(id: 4, nombre: 'Atún', categoriaId: 4),
  ];

  final List<Lote> _lotes = [
    Lote(id: 1, productoId: 1, cantidad: 3, fechaCaducidad: hoy().add(const Duration(days: 2)), fechaIngreso: hoy()),
    Lote(id: 2, productoId: 2, cantidad: 1, fechaCaducidad: hoy().subtract(const Duration(days: 1)), fechaIngreso: hoy()),
    Lote(id: 3, productoId: 3, cantidad: 1, fechaCaducidad: hoy().add(const Duration(days: 200)), fechaIngreso: hoy()),
  ];

  // Compartido con MockLoteRepository
  int nuevoIdLote() => _nextLote++;
  List<Lote> get lotes => _lotes;

  ProductoResumen _resumen(Producto p) {
    final activos = _lotes.where((l) => l.productoId == p.id && l.cantidad > 0).toList()
      ..sort((a, b) => a.fechaCaducidad.compareTo(b.fechaCaducidad));
    final stock = activos.fold<int>(0, (s, l) => s + l.cantidad);
    final h = hoy();
    final limite = h.add(const Duration(days: kDiasPorCaducar));

    EstadoProducto estado;
    if (stock == 0) {
      estado = EstadoProducto.sinExistencia;
    } else if (activos.any((l) => l.fechaCaducidad.isBefore(h))) {
      estado = EstadoProducto.caducado;
    } else if (activos.any((l) => !l.fechaCaducidad.isAfter(limite))) {
      estado = EstadoProducto.porCaducar;
    } else if (stock <= p.stockMinimo) {
      estado = EstadoProducto.porAgotarse;
    } else {
      estado = EstadoProducto.normal;
    }

    final cat = MockCategoriaRepository.datos.firstWhere(
      (c) => c.id == p.categoriaId,
      orElse: () => const Categoria(nombre: '—'),
    );

    return ProductoResumen(
      producto: p,
      categoriaNombre: cat.nombre,
      stockTotal: stock,
      proximaCaducidad: activos.isEmpty ? null : activos.first.fechaCaducidad,
      estado: estado,
    );
  }

  @override
  Future<List<ProductoResumen>> getAlertas() async => _productos
      .map(_resumen)
      .where((r) => r.estado != EstadoProducto.normal)
      .toList();

  @override
  Future<List<ProductoResumen>> getTodos({int? categoriaId}) async => _productos
      .where((p) => categoriaId == null || p.categoriaId == categoriaId)
      .map(_resumen)
      .toList();

  @override
  Future<ProductoResumen?> getById(int id) async {
    final i = _productos.indexWhere((p) => p.id == id);
    return i < 0 ? null : _resumen(_productos[i]);
  }

  @override
  Future<int> insertar(Producto p) async {
    final id = _nextProducto++;
    _productos.add(Producto(
      id: id,
      nombre: p.nombre,
      categoriaId: p.categoriaId,
      imagenPath: p.imagenPath,
      unidad: p.unidad,
      stockMinimo: p.stockMinimo,
    ));
    return id;
  }

  @override
  Future<void> actualizar(Producto p) async {
    final i = _productos.indexWhere((x) => x.id == p.id);
    if (i >= 0) _productos[i] = p;
  }

  @override
  Future<void> eliminar(int id) async {
    _productos.removeWhere((p) => p.id == id);
    _lotes.removeWhere((l) => l.productoId == id);
  }

    @override
  Future<void> consumirStock(int productoId, int cantidad) async {
    if (cantidad <= 0) throw AppException('La cantidad debe ser mayor a 0');

    final activos = _lotes
        .where((l) => l.productoId == productoId && l.cantidad > 0)
        .toList()
      ..sort((a, b) {
        final c = a.fechaCaducidad.compareTo(b.fechaCaducidad);
        return c != 0 ? c : a.id!.compareTo(b.id!);
      });

    final total = activos.fold<int>(0, (s, l) => s + l.cantidad);
    if (total < cantidad) {
      throw AppException('Stock insuficiente: solo hay $total');
    }

    var resto = cantidad;
    for (final l in activos) {
      if (resto == 0) break;
      final descuento = min(l.cantidad, resto);
      final i = _lotes.indexWhere((x) => x.id == l.id);
      _lotes[i] = Lote(
        id: l.id,
        productoId: l.productoId,
        cantidad: l.cantidad - descuento,
        fechaCaducidad: l.fechaCaducidad,
        alarmaActiva: l.alarmaActiva,
        fechaIngreso: l.fechaIngreso,
      );
      resto -= descuento;
    }
  }
}

// ======================= LOTES =======================
class MockLoteRepository implements LoteRepository {
  final MockProductoRepository _store;
  MockLoteRepository(this._store);

  @override
  Future<List<Lote>> getPorProducto(int productoId) async =>
      _store.lotes.where((l) => l.productoId == productoId).toList();

  @override
  Future<int> insertar(Lote l) async {
    final id = _store.nuevoIdLote();
    _store.lotes.add(Lote(
      id: id,
      productoId: l.productoId,
      cantidad: l.cantidad,
      fechaCaducidad: l.fechaCaducidad,
      alarmaActiva: l.alarmaActiva,
      fechaIngreso: l.fechaIngreso,
    ));
    return id;
  }

  @override
  Future<void> actualizar(Lote l) async {
    final i = _store.lotes.indexWhere((x) => x.id == l.id);
    if (i >= 0) _store.lotes[i] = l;
  }

  @override
  Future<void> eliminar(int id) async =>
      _store.lotes.removeWhere((x) => x.id == id);
}

// ======================= CALENDARIO =======================
class MockCalendarioRepository implements CalendarioRepository {
  final ProductoRepository _productos;
  MockCalendarioRepository(this._productos);

  @override
  Future<Map<DateTime, List<ProductoResumen>>> getAlertasPorDia() async {
    final mapa = <DateTime, List<ProductoResumen>>{};
    for (final p in await _productos.getAlertas()) {
      final f = p.proximaCaducidad;
      if (f == null ||
          (p.estado != EstadoProducto.caducado &&
              p.estado != EstadoProducto.porCaducar)) {
        continue;
      }
      mapa.putIfAbsent(soloFecha(f), () => []).add(p);
    }
    return mapa;
  }

  @override
  Future<List<ProductoResumen>> getAlertasDeDia(DateTime dia) async =>
      (await getAlertasPorDia())[soloFecha(dia)] ?? [];
}

// ======================= CARRITO =======================
class MockCarritoRepository implements CarritoRepository {
  final ProductoRepository _productos;
  MockCarritoRepository(this._productos);

  final _items = <int, int>{};
  final _ctrl = StreamController<int>.broadcast();

  int get _total => _items.values.fold(0, (a, b) => a + b);
  void _emit() => _ctrl.add(_total);

  @override
  Stream<int> watchCantidad() async* {
    yield _total;
    yield* _ctrl.stream;
  }

  @override
  Future<List<CarritoLinea>> getLineas() async {
    final todos = await _productos.getTodos();
    return [
      for (final p in todos)
        if (_items.containsKey(p.producto.id))
          CarritoLinea(producto: p, cantidad: _items[p.producto.id]!),
    ];
  }

  @override
  Future<void> agregar(int productoId, {int cantidad = 1}) async {
    _items.update(productoId, (v) => v + cantidad, ifAbsent: () => cantidad);
    _emit();
  }

  @override
  Future<void> cambiarCantidad(int productoId, int cantidad) async {
    if (cantidad <= 0) {
      _items.remove(productoId);
    } else {
      _items[productoId] = cantidad;
    }
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