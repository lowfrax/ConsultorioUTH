import 'package:consultorioequipo1/data/modelos/expediente.dart';
import 'package:consultorioequipo1/data/modelos/archivoexpediente.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Caso {
  final String? id;
  final String nombreCaso;
  final String tipocasoId;
  final String expedienteId;
  final Expediente? expediente;
  final List<ArchivoExpediente> archivos;
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
    this.expediente,
    this.archivos = const [],
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreCaso': nombreCaso,
      'tipocasoId': tipocasoId,
      'expedienteId': expedienteId,
      'expediente': expediente?.toMap(),
      'archivos': archivos.map((a) => a.toMap()).toList(),
      'procuradorId': procuradorId,
      'descripcion': descripcion,
      'demandanteId': demandanteId,
      'demandadoId': demandadoId,
      'juzgadoId': juzgadoId,
      'plazo': Timestamp.fromDate(plazo), // Convertir DateTime a Timestamp
      'costo': costo,
      'estado': estado,
      'eliminado': eliminado,
      'creadoEl': creadoEl != null ? Timestamp.fromDate(creadoEl!) : null,
      'actualizadoEl': actualizadoEl != null
          ? Timestamp.fromDate(actualizadoEl!)
          : null,
    };
  }

  factory Caso.fromMap(Map<String, dynamic> map, [String? documentId]) {
    // Función para parsear fechas desde diferentes formatos
    DateTime parseFecha(dynamic fecha) {
      if (fecha == null) return DateTime.now();
      if (fecha is Timestamp) return fecha.toDate();
      if (fecha is String) {
        try {
          return DateTime.parse(fecha);
        } catch (e) {
          // Manejar otros formatos de fecha si es necesario
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Caso(
      id: documentId ?? map['id'],
      nombreCaso: map['nombre_caso'] ?? map['nombreCaso'] ?? '',
      tipocasoId: map['tipocaso_id'] ?? map['tipocasoId'] ?? '',
      expedienteId: map['expediente_id'] ?? map['expedienteId'] ?? '',
      procuradorId: map['procurador_id'] ?? map['procuradorId'] ?? '',
      descripcion: map['descripcion'] ?? map['descripción'],
      demandanteId: map['demandante_id'] ?? map['demandanteId'] ?? '',
      demandadoId: map['demandado_id'] ?? map['demandadoId'] ?? '',
      juzgadoId: map['juzgado_id'] ?? map['juzgadoId'] ?? '',
      plazo: parseFecha(map['plazo']),
      costo: (map['costo'] ?? 0.0).toDouble(),
      estado: map['estado'] ?? 'pendiente',
      eliminado: map['eliminado'] ?? false,
      creadoEl: parseFecha(map['creado_el'] ?? map['creadoEl']),
      actualizadoEl: parseFecha(map['actualizado_el'] ?? map['actualizadoEl']),
    );
  }

  Caso copyWith({
    String? id,
    String? nombreCaso,
    String? tipocasoId,
    String? expedienteId,
    Expediente? expediente,
    List<ArchivoExpediente>? archivos,
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
      expediente: expediente ?? this.expediente,
      archivos: archivos ?? this.archivos,
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
