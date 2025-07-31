import 'package:cloud_firestore/cloud_firestore.dart';

class TipoCaso {
  final String? id;
  final String nombreCaso;
  final String descripcion;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  TipoCaso({
    this.id,
    required this.nombreCaso,
    required this.descripcion,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory TipoCaso.fromMap(Map<String, dynamic> map, String documentId) =>
      TipoCaso(
        id: documentId,
        nombreCaso: map['nombre_caso'] ?? '',
        descripcion: map['descripcion'] ?? '',
        eliminado: map['eliminado'] ?? false,
        creadoEl: map['creado_el'] != null
            ? (map['creado_el'] as Timestamp).toDate()
            : null,
        actualizadoEl: map['actualizado_el'] != null
            ? (map['actualizado_el'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
    'nombre_caso': nombreCaso,
    'descripcion': descripcion,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  TipoCaso copyWith({
    String? id,
    String? nombreCaso,
    String? descripcion,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return TipoCaso(
      id: id ?? this.id,
      nombreCaso: nombreCaso ?? this.nombreCaso,
      descripcion: descripcion ?? this.descripcion,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
