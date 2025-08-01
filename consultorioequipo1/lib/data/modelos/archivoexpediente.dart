import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivoExpediente {
  final String? id;
  final String expedienteId;
  final String? urlArchivo;
  final String nombreArchivo;
  final String formatoEntrada;
  final String formatoActual;
  final String? rutaLocal; // Nueva campo para ruta local
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  ArchivoExpediente({
    this.id,
    required this.expedienteId,
    this.urlArchivo,
    required this.nombreArchivo,
    required this.formatoEntrada,
    required this.formatoActual,
    this.rutaLocal,
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
    urlArchivo: map['url_archivo'],
    nombreArchivo: map['nombre_archivo'] ?? '',
    formatoEntrada: map['formato_entrada'] ?? '',
    formatoActual: map['formato_actual'] ?? '',
    rutaLocal: map['ruta_local'],
    eliminado: map['eliminado'] ?? false,
    creadoEl: map['creado_el'] != null
        ? (map['creado_el'] is Timestamp
              ? (map['creado_el'] as Timestamp).toDate()
              : DateTime.parse(map['creado_el'].toString()))
        : null,
    actualizadoEl: map['actualizado_el'] != null
        ? (map['actualizado_el'] is Timestamp
              ? (map['actualizado_el'] as Timestamp).toDate()
              : DateTime.parse(map['actualizado_el'].toString()))
        : null,
  );

  Map<String, dynamic> toMap() => {
    'expediente_id': expedienteId,
    'url_archivo': urlArchivo,
    'nombre_archivo': nombreArchivo,
    'formato_entrada': formatoEntrada,
    'formato_actual': formatoActual,
    'ruta_local': rutaLocal,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  ArchivoExpediente copyWith({
    String? id,
    String? expedienteId,
    String? urlArchivo,
    String? nombreArchivo,
    String? formatoEntrada,
    String? formatoActual,
    String? rutaLocal,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return ArchivoExpediente(
      id: id ?? this.id,
      expedienteId: expedienteId ?? this.expedienteId,
      urlArchivo: urlArchivo ?? this.urlArchivo,
      nombreArchivo: nombreArchivo ?? this.nombreArchivo,
      formatoEntrada: formatoEntrada ?? this.formatoEntrada,
      formatoActual: formatoActual ?? this.formatoActual,
      rutaLocal: rutaLocal ?? this.rutaLocal,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
