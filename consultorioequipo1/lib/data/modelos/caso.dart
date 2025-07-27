class Caso {
  final int? id;
  final String nombreCaso;
  final int tipocasoId;
  final int procuradorId;
  final String? descripcion;
  final int demandanteId;
  final int demandadoId;
  final int juzgadoId;
  final DateTime plazo;
  final String estado;
  final int eliminado;

  Caso({
    this.id,
    required this.nombreCaso,
    required this.tipocasoId,
    required this.procuradorId,
    this.descripcion,
    required this.demandanteId,
    required this.demandadoId,
    required this.juzgadoId,
    required this.plazo,
    required this.estado,
    this.eliminado = 0,
  });

  factory Caso.fromMap(Map<String, dynamic> map) => Caso(
    id: map['id'],
    nombreCaso: map['nombre_caso'],
    tipocasoId: map['tipocaso_id'],
    procuradorId: map['procurador_id'],
    descripcion: map['descripcion'],
    demandanteId: map['demandante_id'],
    demandadoId: map['demandado_id'],
    juzgadoId: map['juzgado_id'],
    plazo: DateTime.parse(map['plazo']),
    estado: map['estado'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre_caso': nombreCaso,
    'tipocaso_id': tipocasoId,
    'procurador_id': procuradorId,
    'descripcion': descripcion,
    'demandante_id': demandanteId,
    'demandado_id': demandadoId,
    'juzgado_id': juzgadoId,
    'plazo': plazo.toIso8601String(),
    'estado': estado,
    'eliminado': eliminado,
  };
}
