import '../../core/date_utils.dart';

class Lote {
  final int? id;
  final int productoId;
  final int cantidad;
  final DateTime? fechaCaducidad; // Nullable para no perecederos
  final bool alarmaActiva;
  final DateTime fechaIngreso;

  Lote({
    this.id,
    required this.productoId,
    required this.cantidad,
    this.fechaCaducidad,
    this.alarmaActiva = true,
    required this.fechaIngreso,
  });

  factory Lote.fromMap(Map<String, dynamic> map) => Lote(
    id: map['id'] as int?,
    productoId: map['producto_id'] as int,
    cantidad: map['cantidad'] as int,
    fechaCaducidad: map['fecha_caducidad'] != null ? sqlToDate(map['fecha_caducidad']) : null,
    alarmaActiva: map['alarma_activa'] == 1,
    fechaIngreso: sqlToDate(map['fecha_ingreso']),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'producto_id': productoId,
    'cantidad': cantidad,
    'fecha_caducidad': fechaCaducidad != null ? dateToSql(fechaCaducidad!) : null,
    'alarma_activa': alarmaActiva ? 1 : 0,
    'fecha_ingreso': dateToSql(fechaIngreso),
  };
}