
class Car {
  final String id;
  final String userId; // Changed from clientId
  final String? marque;
  final String? modele;
  final String immatriculation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Car({
    required this.id,
    required this.userId,
    this.marque,
    this.modele,
    required this.immatriculation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      userId: map['user_id'] as String, // Changed from client_id
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
      'user_id': userId, // Changed from client_id
      'marque': marque,
      'modele': modele,
      'immatriculation': immatriculation,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, marque, modele, immatriculation, createdAt, updatedAt];
}