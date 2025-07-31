import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivoExpediente {
  final String? id;
  final String expedienteId;
  final String formatoEntrada;
  final String formatoActual;
  final String urlArchivo;
  final String nombreArchivo;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  ArchivoExpediente({
    this.id,
    required this.expedienteId,
    required this.formatoEntrada,
    required this.formatoActual,
    required this.urlArchivo,
    required this.nombreArchivo,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory ArchivoExpediente.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) => ArchivoExpediente(
    id: documentId,
    expedienteId: map['expediente_id'] ?? '',
    formatoEntrada: map['formato_entrada'] ?? '',
    formatoActual: map['formato_actual'] ?? '',
    urlArchivo: map['url_archivo'] ?? '',
    nombreArchivo: map['nombre_archivo'] ?? '',
    eliminado: map['eliminado'] ?? false,
    creadoEl: map['creado_el'] != null
        ? (map['creado_el'] as Timestamp).toDate()
        : null,
    actualizadoEl: map['actualizado_el'] != null
        ? (map['actualizado_el'] as Timestamp).toDate()
        : null,
  );

  Map<String, dynamic> toMap() => {
    'expediente_id': expedienteId,
    'formato_entrada': formatoEntrada,
    'formato_actual': formatoActual,
    'url_archivo': urlArchivo,
    'nombre_archivo': nombreArchivo,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  ArchivoExpediente copyWith({
    String? id,
    String? expedienteId,
    String? formatoEntrada,
    String? formatoActual,
    String? urlArchivo,
    String? nombreArchivo,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return ArchivoExpediente(
      id: id ?? this.id,
      expedienteId: expedienteId ?? this.expedienteId,
      formatoEntrada: formatoEntrada ?? this.formatoEntrada,
      formatoActual: formatoActual ?? this.formatoActual,
      urlArchivo: urlArchivo ?? this.urlArchivo,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
