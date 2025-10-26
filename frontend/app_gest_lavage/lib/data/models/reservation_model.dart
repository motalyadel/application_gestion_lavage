import 'package:equatable/equatable.dart';
import 'package:app_gest_lavage/data/models/service_model.dart';

class Reservation extends Equatable {
  final String id;
  final String clientId;
  final String serviceId;
  final String carId; 
  final DateTime dateTime;
  final String status;
  final DateTime createdAt;
  final Service? service; // Optional service details if fetched

  const Reservation({
    required this.id,
    required this.clientId,
    required this.serviceId,
    required this.carId, 
    required this.dateTime,
    required this.status,
    required this.createdAt,
    this.service,
  });

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      serviceId: map['service_id'] as String,
      carId: map['car_id'] as String, 
      dateTime: DateTime.parse(map['date_time'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      service: map['service'] != null ? Service.fromMap(map['service']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'service_id': serviceId,
      'car_id': carId, 
      'date_time': dateTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, clientId, serviceId, carId, dateTime, status, createdAt, service];
}