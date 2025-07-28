class ArchivoExpediente {
  final int? id;
  final int expedienteId;
  final String formatoEntrada;
  final String formatoActual;
  final int eliminado;

  ArchivoExpediente({
    this.id,
    required this.expedienteId,
    required this.formatoEntrada,
    required this.formatoActual,
    this.eliminado = 0,
  });

  factory ArchivoExpediente.fromMap(Map<String, dynamic> map) =>
      ArchivoExpediente(
        id: map['id'],
        expedienteId: map['expediente_id'],
        formatoEntrada: map['formato_entrada'],
        formatoActual: map['formato_actual'],
        eliminado: map['eliminado'],
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'expediente_id': expedienteId,
    'formato_entrada': formatoEntrada,
    'formato_actual': formatoActual,
    'eliminado': eliminado,
  };
}
