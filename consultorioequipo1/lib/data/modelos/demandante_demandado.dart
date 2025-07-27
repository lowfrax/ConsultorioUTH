class Parte {
  final int? id;
  final String nombre;
  final String dni;
  final String email;
  final String direccion;
  final int telefono;
  final int eliminado;

  Parte({
    this.id,
    required this.nombre,
    required this.dni,
    required this.email,
    required this.direccion,
    required this.telefono,
    this.eliminado = 0,
  });

  factory Parte.fromMap(Map<String, dynamic> map) => Parte(
    id: map['id'],
    nombre: map['nombre'],
    dni: map['dni'],
    email: map['email'],
    direccion: map['direccion'],
    telefono: map['telefono'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'dni': dni,
    'email': email,
    'direccion': direccion,
    'telefono': telefono,
    'eliminado': eliminado,
  };
}
