class ProcuradorMateria {
  final int? id;
  final int procuradorId;
  final int materiaId;

  ProcuradorMateria({
    this.id,
    required this.procuradorId,
    required this.materiaId,
  });

  factory ProcuradorMateria.fromMap(Map<String, dynamic> map) =>
      ProcuradorMateria(
        id: map['id'],
        procuradorId: map['procurador_id'],
        materiaId: map['materia_id'],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'procurador_id': procuradorId,
    'materia_id': materiaId,
  };
}
