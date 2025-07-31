import 'package:cloud_firestore/cloud_firestore.dart';

class Procurador {
  final String? id;
  final String nombre;
  final String usuario;
  final String password;
  final String email;
  final String telefono; // Cambiado a String para manejar el campo con tilde
  final String nCuenta; // Cambiado a String para consistencia
  final DocumentReference? idClase;
  final DocumentReference? idCuatrimestre;
  final DocumentReference? idRol;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  Procurador({
    this.id,
    required this.nombre,
    required this.usuario,
    required this.password,
    required this.email,
    required this.telefono,
    required this.nCuenta,
    this.idClase,
    this.idCuatrimestre,
    this.idRol,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory Procurador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Procurador(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      usuario: data['usuario'] ?? '',
      password: data['password'] ?? '',
      email: data['email'] ?? '',
      telefono: data['teléfono']?.toString() ?? '', // Maneja el campo con tilde
      nCuenta: data['n_cuenta']?.toString() ?? '', // Convertido a String
      idClase: data['id_clase'],
      idCuatrimestre: data['id_cuatrimestre'],
      idRol: data['id_rol'],
      eliminado: data['eliminado'] ?? false,
      creadoEl: data['creado_el'] != null
          ? (data['creado_el'] as Timestamp).toDate()
          : null,
      actualizadoEl: data['actualizado_el'] != null
          ? (data['actualizado_el'] as Timestamp).toDate()
          : null,
    );
  }

  factory Procurador.fromMap(Map<String, dynamic> map, String documentId) {
    return Procurador(
      id: documentId,
      nombre: map['nombre'] ?? '',
      usuario: map['usuario'] ?? '',
      password: map['password'] ?? '',
      email: map['email'] ?? '',
      telefono:
          map['teléfono']?.toString() ?? map['telefono']?.toString() ?? '',
      nCuenta: map['n_cuenta']?.toString() ?? '',
      idClase: map['id_clase'],
      idCuatrimestre: map['id_cuatrimestre'],
      idRol: map['id_rol'],
      eliminado: map['eliminado'] ?? false,
      creadoEl: map['creado_el'] != null
          ? (map['creado_el'] as Timestamp).toDate()
          : null,
      actualizadoEl: map['actualizado_el'] != null
          ? (map['actualizado_el'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'usuario': usuario,
      'password': password,
      'email': email,
      'teléfono': telefono, // Campo con tilde
      'n_cuenta': nCuenta,
      'id_clase': idClase,
      'id_cuatrimestre': idCuatrimestre,
      'id_rol': idRol,
      'eliminado': eliminado,
      'creado_el': creadoEl != null
          ? Timestamp.fromDate(creadoEl!)
          : FieldValue.serverTimestamp(),
      'actualizado_el': FieldValue.serverTimestamp(),
    };
  }
}
