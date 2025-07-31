import 'package:cloud_firestore/cloud_firestore.dart';

class RolLegitario {
  final String? id;
  final String rol;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  RolLegitario({
    this.id,
    required this.rol,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory RolLegitario.fromMap(Map<String, dynamic> map, String documentId) =>
      RolLegitario(
        id: documentId,
        rol: map['rol'] ?? '',
        eliminado: map['eliminado'] ?? false,
        creadoEl: map['creado_el'] != null
            ? (map['creado_el'] as Timestamp).toDate()
            : null,
        actualizadoEl: map['actualizado_el'] != null
            ? (map['actualizado_el'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
    'rol': rol,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  RolLegitario copyWith({
    String? id,
    String? rol,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return RolLegitario(
      id: id ?? this.id,
      rol: rol ?? this.rol,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
