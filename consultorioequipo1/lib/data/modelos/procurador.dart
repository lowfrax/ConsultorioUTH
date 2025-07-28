class Procurador {
  final int? id;
  final String nombre;
  final String password;
  final String email;
  final int telefono;
  final int cuatrimestreId;
  final int eliminado;

  Procurador({
    this.id,
    required this.nombre,
    required this.password,
    required this.email,
    required this.telefono,
    required this.cuatrimestreId,
    this.eliminado = 0,
  });

  factory Procurador.fromMap(Map<String, dynamic> map) => Procurador(
    id: map['id'],
    nombre: map['nombre'],
    password: map['password'],
    email: map['email'],
    telefono: map['telefono'],
    cuatrimestreId: map['cuatrimestre_id'],
    eliminado: map['eliminado'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'password': password,
    'email': email,
    'telefono': telefono,
    'cuatrimestre_id': cuatrimestreId,
    'eliminado': eliminado,
  };
}
