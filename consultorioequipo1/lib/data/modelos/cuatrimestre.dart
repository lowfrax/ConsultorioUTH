class Cuatrimestre {
  final int? id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int eliminado;

  Cuatrimestre({
    this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    this.eliminado = 0,
  });

  factory Cuatrimestre.fromMap(Map<String, dynamic> map) => Cuatrimestre(
    id: map['id'],
    nombre: map['nombre'],
    fechaInicio: DateTime.parse(map['fecha_inicio']),
    fechaFin: DateTime.parse(map['fecha_fin']),
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'fecha_inicio': fechaInicio.toIso8601String(),
    'fecha_fin': fechaFin.toIso8601String(),
    'eliminado': eliminado,
  };
}
