import 'package:cloud_firestore/cloud_firestore.dart';

class RolProcurador {
  final String? id;
  final String rol;
  final bool eliminado;
  final DateTime creadoEl;
  final DateTime actualizadoEl;

  RolProcurador({
    this.id,
    required this.rol,
    this.eliminado = false,
    required this.creadoEl,
    required this.actualizadoEl,
  });

  factory RolProcurador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RolProcurador(
      id: doc.id,
      rol: data['rol'] ?? '',
      eliminado: data['eliminado'] ?? false,
      creadoEl: (data['creado_el'] as Timestamp).toDate(),
      actualizadoEl: (data['actualizado_el'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rol': rol,
      'eliminado': eliminado,
      'creado_el': Timestamp.fromDate(creadoEl),
      'actualizado_el': Timestamp.fromDate(actualizadoEl),
    };
  }
}
