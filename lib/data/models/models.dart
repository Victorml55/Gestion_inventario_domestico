enum EstadoProducto { sinExistencia, caducado, porCaducar, porAgotarse, normal }

class Producto {
  final int? id;
  final String nombre;
  final int categoriaId;
  final String? imagenPath;
  final String unidad;
  final int stockMinimo;
  final int? ultimaTiendaId;

  const Producto({
    this.id,
    required this.nombre,
    required this.categoriaId,
    this.imagenPath,
    this.unidad = 'pza',
    this.stockMinimo = 1,
    this.ultimaTiendaId,
  });
}

class ProductoResumen {
  final Producto producto;
  final String categoriaNombre;
  final int stockTotal;
  final DateTime? proximaCaducidad;
  final EstadoProducto estado;
  final String? ultimaTiendaNombre;

  const ProductoResumen({
    required this.producto,
    required this.categoriaNombre,
    required this.stockTotal,
    required this.proximaCaducidad,
    required this.estado,
    this.ultimaTiendaNombre,
  });
}