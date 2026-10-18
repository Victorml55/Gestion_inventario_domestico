class Tienda {
  final int? id;
  final String nombre;
  final String? direccion;

  Tienda({this.id, required this.nombre, this.direccion});

  factory Tienda.fromMap(Map<String, dynamic> map) => Tienda(
    id: map['id'] as int?,
    nombre: map['nombre'] as String,
    direccion: map['direccion'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': nombre,
    'direccion': direccion,
  };
}