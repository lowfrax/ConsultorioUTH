import 'package:cloud_firestore/cloud_firestore.dart';

class Legitario {
  final String? id;
  final String rolId;
  final String nombre;
  final String email;
  final String direccion;
  final String telefono;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  Legitario({
    this.id,
    required this.rolId,
    required this.nombre,
    required this.email,
    required this.direccion,
    required this.telefono,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory Legitario.fromMap(Map<String, dynamic> map, String documentId) =>
      Legitario(
        id: documentId,
        rolId: map['rol_id'] ?? '',
        nombre: map['nombre'] ?? '',
        email: map['email'] ?? '',
        direccion: map['direccion'] ?? '',
        telefono: map['telefono'] ?? '',
        eliminado: map['eliminado'] ?? false,
        creadoEl: map['creado_el'] != null
            ? (map['creado_el'] as Timestamp).toDate()
            : null,
        actualizadoEl: map['actualizado_el'] != null
            ? (map['actualizado_el'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toMap() => {
    'rol_id': rolId,
    'nombre': nombre,
    'email': email,
    'direccion': direccion,
    'telefono': telefono,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  Legitario copyWith({
    String? id,
    String? rolId,
    String? nombre,
    String? email,
    String? direccion,
    String? telefono,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return Legitario(
      id: id ?? this.id,
      rolId: rolId ?? this.rolId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
