class Juzgado {
  final int? id;
  final String nombreJuzgado;
  final String direccion;
  final int telefono;
  final int eliminado;

  Juzgado({
    this.id,
    required this.nombreJuzgado,
    required this.direccion,
    required this.telefono,
    this.eliminado = 0,
  });

  factory Juzgado.fromMap(Map<String, dynamic> map) => Juzgado(
    id: map['id'],
    nombreJuzgado: map['nombre_juzgado'],
    direccion: map['direccion'],
    telefono: map['telefono'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre_juzgado': nombreJuzgado,
    'direccion': direccion,
    'telefono': telefono,
    'eliminado': eliminado,
  };
}
