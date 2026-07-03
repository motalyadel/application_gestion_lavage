import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:equatable/equatable.dart';
import 'package:app_gest_lavage/data/models/service_model.dart';

class Reservation extends Equatable {
  final String id;
  final String clientId;
  final String serviceId;
  final String carId;
  final int? position;
  final DateTime? expectedTime;
  final String status;
  final DateTime createdAt;
  final DateTime? startedAt; // ✅ AJOUT : heure de début réelle du lavage
  final Service? service;
  final Car? car;

  const Reservation({
    required this.id,
    required this.clientId,
    required this.serviceId,
    required this.carId,
    this.position,
    this.expectedTime,
    required this.status,
    required this.createdAt,
    this.startedAt, // ✅ AJOUT
    this.service,
    this.car,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      serviceId: map['service_id'] as String,
      carId: map['car_id'] as String,
      position: map['position'],
      expectedTime: map['expected_time'] != null
          ? DateTime.parse(map['expected_time'])
          : null,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      // ✅ AJOUT : parsing de started_at (null si le lavage n'a pas démarré)
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'])
          : null,
      service: map['service'] != null ? Service.fromMap(map['service']) : null,
      car: map['car'] != null ? Car.fromMap(map['car']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'service_id': serviceId,
      'car_id': carId,
      'position': position,
      'expected_time': expectedTime,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(), // ✅ AJOUT
    };
  }

  @override
  List<Object?> get props =>
      [id, clientId, serviceId, carId, status, createdAt, startedAt, service];
}