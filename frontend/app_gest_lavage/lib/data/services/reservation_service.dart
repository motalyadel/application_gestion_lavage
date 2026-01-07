import 'dart:convert';

import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class ReservationService {
  final SupabaseClient clientSpb = Supabase.instance.client;
  // final String _n8nBaseUrl = 'http://localhost:5678/webhook-test';
  final String _n8nBaseUrl = 'http://10.0.2.2:5678/webhook-test';

  Future<List<Reservation>> getReservations({required bool isAdmin}) async {
    try {
      final userId = clientSpb.auth.currentUser?.id;
      print('Fetching reservations for user: $userId, isAdmin: $isAdmin');
      final query = clientSpb
          .from('reservations')
          .select(
              'id, client_id, service_id, car_id, position, expected_time, status, created_at, car:cars(id, user_id, marque, modele, immatriculation, created_at, updated_at ), service:services(id, name, price, duration)')
          .order('created_at', ascending: true);

      print('Executing query: ${query.toString()}');
      final response = await query;
      print('Reservations response raw: $response');

      if (response.isEmpty) {
        print('No reservations found for user: $userId, isAdmin: $isAdmin');
      }

      return response.map((map) => Reservation.fromMap(map)).toList();
    } catch (e) {
      print('getReservations() failed with exception: $e ');
      rethrow;
    }
  }

  Future<bool> addReservation({
    required BuildContext context,
    required String clientId,
    required String clientName,
    required String clientPhone,
    required String serviceId,
    required String serviceName,
    // required int serviceDuration,
    required String carId,
    // required DateTime dateTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_n8nBaseUrl/create-reservation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'client_id': clientId,
          'client_name': clientName,
          'client_phone': clientPhone,
          'service_id': serviceId,
          'service_name': serviceName,
          // 'service_duration': serviceDuration,
          'car_id': carId,
          // 'date_time': dateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Erreur appel n8n: $e');
      return false;
    }
  }

  // Future<bool> addReservation({
  //   required String clientId,
  //   required String serviceId,
  //   required String carId,
  //   required DateTime dateTime,
  //   String status = 'pending',
  // }) async {
  //   try {
  //     final data = {
  //       'client_id': clientId,
  //       'service_id': serviceId,
  //       'car_id': carId,
  //       'date_time': dateTime.toIso8601String(),
  //       'status': status,
  //     };
  //     print('Adding reservation with data: $data');
  //     final response =
  //         await clientSpb.from('reservations').insert(data).select().single();
  //     print('Reservation added response: $response ');
  //     return true;
  //   } catch (e) {
  //     print(
  //         'addReservation() failed with exception: $e, details: ${e.toString()}');
  //     return false;
  //   }
  // }

  Future<bool> updateReservation({
    required String id,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;

      if (updates.isEmpty) {
        print('No updates provided for reservation');
        return true;
      }

      final response = await clientSpb
          .from('reservations')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      print('Reservation updated: $response');
      return true;
    } catch (e) {
      print('updateReservation() failed: $e');
      return false;
    }
  }
}
