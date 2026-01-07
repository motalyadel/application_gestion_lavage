import 'package:equatable/equatable.dart';

class Service extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int price;
  final int duration;
  final DateTime createdAt;

  const Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    required this.createdAt,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    try {
      return Service(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        price: map['price'] is String
            ? int.parse(map['price'])
            : map['price'] as int,
        duration: map['duration'] is String
            ? int.parse(map['duration'])
            : map['duration'] as int,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing Service from map: $map, error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, price, duration, createdAt];
}
