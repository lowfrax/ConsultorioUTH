class Caso {
  final String nombre;
  final String tipo;
  final String procurador;
  final String juzgado;
  final String demandante;
  final String demandado;
  final String fecha;
  String estado;

  Caso({
    required this.nombre,
    required this.tipo,
    required this.procurador,
    required this.juzgado,
    required this.demandante,
    required this.demandado,
    required this.fecha,
    this.estado = 'Pendiente',
  });
}