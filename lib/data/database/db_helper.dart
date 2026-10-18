import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alacena.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tablas
    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0),
        icono TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tienda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE CHECK (length(trim(nombre)) > 0),
        direccion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE producto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
        categoria_id INTEGER NOT NULL,
        imagen_path TEXT,
        unidad TEXT NOT NULL DEFAULT 'pza',
        stock_minimo INTEGER NOT NULL DEFAULT 1 CHECK (stock_minimo >= 0),
        ultima_tienda_id INTEGER,
        FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON DELETE RESTRICT,
        FOREIGN KEY (ultima_tienda_id) REFERENCES tienda(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE lote (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL CHECK (cantidad >= 0),
        fecha_caducidad TEXT,
        alarma_activa INTEGER NOT NULL DEFAULT 1 CHECK (alarma_activa IN (0,1)),
        fecha_ingreso TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE historial_compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tienda_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL CHECK (cantidad > 0),
        precio REAL CHECK (precio IS NULL OR precio >= 0),
        fecha_compra TEXT NOT NULL,
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE,
        FOREIGN KEY (tienda_id) REFERENCES tienda(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE carrito_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL UNIQUE,
        cantidad INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE
      )
    ''');

    // 2. Índices
    await db.execute('CREATE INDEX idx_lote_producto ON lote(producto_id)');
    await db.execute('CREATE INDEX idx_lote_caducidad ON lote(fecha_caducidad)');
    await db.execute('CREATE INDEX idx_historial_producto ON historial_compras(producto_id)');

    // 3. Semilla (Datos iniciales)
    await _insertarSemilla(db);
  }

  Future<void> _insertarSemilla(Database db) async {
    final categorias = ['Lácteos', 'Carnes', 'Frutas y verduras', 'Despensa', 'Bebidas', 'Limpieza'];
    for (var cat in categorias) {
      await db.insert('categoria', {'nombre': cat});
    }

    final tiendas = [
      {'nombre': 'Walmart', 'direccion': 'Sucursal Centro'},
      {'nombre': 'Soriana', 'direccion': 'Sucursal Norte'},
    ];
    for (var t in tiendas) {
      await db.insert('tienda', t);
    }
  }
}