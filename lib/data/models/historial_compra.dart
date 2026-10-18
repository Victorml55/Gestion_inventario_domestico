import '../../core/date_utils.dart';

class HistorialCompra {
  final int? id;
  final int productoId;
  final int tiendaId;
  final int cantidad;
  final double? precio;
  final DateTime fechaCompra;

  HistorialCompra({
    this.id,
    required this.productoId,
    required this.tiendaId,
    required this.cantidad,
    this.precio,
    required this.fechaCompra,
  });

  factory HistorialCompra.fromMap(Map<String, dynamic> map) => HistorialCompra(
    id: map['id'] as int?,
    productoId: map['producto_id'] as int,
    tiendaId: map['tienda_id'] as int,
    cantidad: map['cantidad'] as int,
    precio: map['precio'] as double?,
    fechaCompra: sqlToDate(map['fecha_compra']),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'producto_id': productoId,
    'tienda_id': tiendaId,
    'cantidad': cantidad,
    'precio': precio,
    'fecha_compra': dateToSql(fechaCompra),
  };
}