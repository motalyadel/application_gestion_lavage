class Car {
  final String id;
  final String clientId;
  final String? marque;
  final String? modele;
  final String immatriculation;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.clientId,
    this.marque,
    this.modele,
    required this.immatriculation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      marque: map['marque'] as String?,
      modele: map['modele'] as String?,
      immatriculation: map['immatriculation'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}