import 'package:cloud_firestore/cloud_firestore.dart';

class Caso {
  final String? id;
  final String nombreCaso;
  final String tipocasoId;
  final String expedienteId;
  final String procuradorId;
  final String? descripcion;
  final String demandanteId;
  final String demandadoId;
  final String juzgadoId;
  final DateTime plazo;
  final double costo;
  final String estado;
  final bool eliminado;
  final DateTime? creadoEl;
  final DateTime? actualizadoEl;

  Caso({
    this.id,
    required this.nombreCaso,
    required this.tipocasoId,
    required this.expedienteId,
    required this.procuradorId,
    this.descripcion,
    required this.demandanteId,
    required this.demandadoId,
    required this.juzgadoId,
    required this.plazo,
    required this.costo,
    required this.estado,
    this.eliminado = false,
    this.creadoEl,
    this.actualizadoEl,
  });

  factory Caso.fromMap(Map<String, dynamic> map, String documentId) => Caso(
    id: documentId,
    nombreCaso: map['nombre_caso'] ?? '',
    tipocasoId: map['tipocaso_id'] ?? '',
    expedienteId: map['expediente_id'] ?? '',
    procuradorId: map['procurador_id'] ?? '',
    descripcion: map['descripcion'],
    demandanteId: map['demandante_id'] ?? '',
    demandadoId: map['demandado_id'] ?? '',
    juzgadoId: map['juzgado_id'] ?? '',
    plazo: map['plazo'] != null
        ? (map['plazo'] as Timestamp).toDate()
        : DateTime.now(),
    costo: (map['costo'] ?? 0.0).toDouble(),
    estado: map['estado'] ?? 'pendiente',
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
    'tipocaso_id': tipocasoId,
    'expediente_id': expedienteId,
    'procurador_id': procuradorId,
    'descripcion': descripcion,
    'demandante_id': demandanteId,
    'demandado_id': demandadoId,
    'juzgado_id': juzgadoId,
    'plazo': Timestamp.fromDate(plazo),
    'costo': costo,
    'estado': estado,
    'eliminado': eliminado,
    'creado_el': creadoEl != null
        ? Timestamp.fromDate(creadoEl!)
        : FieldValue.serverTimestamp(),
    'actualizado_el': FieldValue.serverTimestamp(),
  };

  Caso copyWith({
    String? id,
    String? nombreCaso,
    String? tipocasoId,
    String? expedienteId,
    String? procuradorId,
    String? descripcion,
    String? demandanteId,
    String? demandadoId,
    String? juzgadoId,
    DateTime? plazo,
    double? costo,
    String? estado,
    bool? eliminado,
    DateTime? creadoEl,
    DateTime? actualizadoEl,
  }) {
    return Caso(
      id: id ?? this.id,
      nombreCaso: nombreCaso ?? this.nombreCaso,
      tipocasoId: tipocasoId ?? this.tipocasoId,
      expedienteId: expedienteId ?? this.expedienteId,
      procuradorId: procuradorId ?? this.procuradorId,
      descripcion: descripcion ?? this.descripcion,
      demandanteId: demandanteId ?? this.demandanteId,
      demandadoId: demandadoId ?? this.demandadoId,
      juzgadoId: juzgadoId ?? this.juzgadoId,
      plazo: plazo ?? this.plazo,
      costo: costo ?? this.costo,
      estado: estado ?? this.estado,
      eliminado: eliminado ?? this.eliminado,
      creadoEl: creadoEl ?? this.creadoEl,
      actualizadoEl: actualizadoEl ?? this.actualizadoEl,
    );
  }
}
