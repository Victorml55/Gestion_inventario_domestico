class Categoria {
  final int? id;
  final String nombre;
  final String? icono;

  Categoria({this.id, required this.nombre, this.icono});

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
    id: map['id'] as int?,
    nombre: map['nombre'] as String,
    icono: map['icono'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre': nombre,
    'icono': icono,
  };

  Categoria copyWith({int? id, String? nombre, String? icono}) => Categoria(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    icono: icono ?? this.icono,
  );
}