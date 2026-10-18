class Producto {
  final int? id;
  final String nombre;
  final int categoriaId;
  final String? imagenPath;
  final String unidad;
  final int stockMinimo;
  final int? ultimaTiendaId;

  Producto({
    this.id,
    required this.nombre,
    required this.categoriaId,
    this.imagenPath,
    this.unidad = 'pza',
    this.stockMinimo = 1,
    this.ultimaTiendaId,
  });

  factory Producto.fromMap(Map<String, dynamic> map) => Producto(
    id: map['id'] as int?,
    nombre: map['nombre'] as String,
    categoriaId: map['categoria_id'] as int,
    imagenPath: map['imagen_path'] as String?,
    unidad: map['unidad'] as String,
    stockMinimo: map['stock_minimo'] as int,
    ultimaTiendaId: map['ultima_tienda_id'] as int?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': nombre,
    'categoria_id': categoriaId,
    'imagen_path': imagenPath,
    'unidad': unidad,
    'stock_minimo': stockMinimo,
    'ultima_tienda_id': ultimaTiendaId,
  };
}