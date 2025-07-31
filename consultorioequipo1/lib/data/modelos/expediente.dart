import 'package:cloud_firestore/cloud_firestore.dart';

class Expediente {
  final String? id;
  final String nombreExpediente;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  Expediente({
    this.id,
    required this.nombreExpediente,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory Expediente.fromMap(Map<String, dynamic> map, String documentId) =>
      Expediente(
        id: documentId,
        nombreExpediente: map['nombre_expediente'] ?? '',
        eliminado: map['eliminado'] ?? false,
        creadoEl: map['creado_el'] != null
            ? (map['creado_el'] as Timestamp).toDate()
            : null,
        actualizadoEl: map['actualizado_el'] != null
            ? (map['actualizado_el'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
    'nombre_expediente': nombreExpediente,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  Expediente copyWith({
    String? id,
    String? nombreExpediente,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return Expediente(
      id: id ?? this.id,
      nombreExpediente: nombreExpediente ?? this.nombreExpediente,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
