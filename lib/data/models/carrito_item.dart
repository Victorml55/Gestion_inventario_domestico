class CarritoItem {
  final int? id;
  final int productoId;
  final int cantidad;

  CarritoItem({this.id, required this.productoId, required this.cantidad});

  factory CarritoItem.fromMap(Map<String, dynamic> map) => CarritoItem(
    id: map['id'] as int?,
    productoId: map['producto_id'] as int,
    cantidad: map['cantidad'] as int,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'producto_id': productoId,
    'cantidad': cantidad,
  };
}