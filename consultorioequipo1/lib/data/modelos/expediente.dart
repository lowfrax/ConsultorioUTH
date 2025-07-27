class Expediente {
  final int? id;
  final String nombreExpediente;
  final int casoId;
  final int eliminado;

  Expediente({
    this.id,
    required this.nombreExpediente,
    required this.casoId,
    this.eliminado = 0,
  });

  factory Expediente.fromMap(Map<String, dynamic> map) => Expediente(
    id: map['id'],
    nombreExpediente: map['nombre_expediente'],
    casoId: map['caso_id'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre_expediente': nombreExpediente,
    'caso_id': casoId,
    'eliminado': eliminado,
  };
}
