class TipoCaso {
  final int? id;
  final String nombreCaso;
  final String descripcion;
  final int eliminado;

  TipoCaso({
    this.id,
    required this.nombreCaso,
    required this.descripcion,
    this.eliminado = 0,
  });

  factory TipoCaso.fromMap(Map<String, dynamic> map) => TipoCaso(
    id: map['id'],
    nombreCaso: map['nombre_caso'],
    descripcion: map['descripcion'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre_caso': nombreCaso,
    'descripcion': descripcion,
    'eliminado': eliminado,
  };
}
