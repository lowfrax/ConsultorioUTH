class CasoMateria {
  final int? id;
  final int casoId;
  final int materiaId;

  CasoMateria({this.id, required this.casoId, required this.materiaId});

  factory CasoMateria.fromMap(Map<String, dynamic> map) => CasoMateria(
    id: map['id'],
    casoId: map['caso_id'],
    materiaId: map['materia_id'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'caso_id': casoId,
    'materia_id': materiaId,
  };
}
