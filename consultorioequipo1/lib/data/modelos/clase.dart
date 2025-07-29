import 'package:cloud_firestore/cloud_firestore.dart';

class Clase {
  final String? id;
  final String codigoClase;
  final String nombreClase;
  final bool eliminado;
  final DateTime creadoEl;
  final DateTime actualizadoEl;

  Clase({
    this.id,
    required this.codigoClase,
    required this.nombreClase,
    this.eliminado = false,
    required this.creadoEl,
    required this.actualizadoEl,
  });

  factory Clase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Clase(
      id: doc.id,
      codigoClase: data['codigo_clase'] ?? '',
      nombreClase: data['nombre_clase'] ?? '',
      eliminado: data['eliminado'] ?? false,
      creadoEl: (data['creado_el'] as Timestamp).toDate(),
      actualizadoEl: (data['actualizado_el'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo_clase': codigoClase,
      'nombre_clase': nombreClase,
      'eliminado': eliminado,
      'creado_el': Timestamp.fromDate(creadoEl),
      'actualizado_el': Timestamp.fromDate(actualizadoEl),
    };
  }
}
