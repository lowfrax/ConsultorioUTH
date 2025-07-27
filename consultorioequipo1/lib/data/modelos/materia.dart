class Materia {
  final int? id;
  final String nombreMateria;
  final String? descripcion;
  final int cuatrimestreId;
  final int eliminado;

  Materia({
    this.id,
    required this.nombreMateria,
    this.descripcion,
    required this.cuatrimestreId,
    this.eliminado = 0,
  });

  factory Materia.fromMap(Map<String, dynamic> map) => Materia(
    id: map['id'],
    nombreMateria: map['nombre_materia'],
    descripcion: map['descripcion'],
    cuatrimestreId: map['cuatrimestre_id'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre_materia': nombreMateria,
    'descripcion': descripcion,
    'cuatrimestre_id': cuatrimestreId,
    'eliminado': eliminado,
  };
}
