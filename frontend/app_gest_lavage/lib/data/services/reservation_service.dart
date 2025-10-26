import 'package:app_gest_lavage/data/models/reservation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationService {
  final SupabaseClient clientSpb = Supabase.instance.client;

  Future<List<Reservation>> getReservations({required bool isAdmin}) async {
    try {
      final userId = clientSpb.auth.currentUser?.id;
      print('Fetching reservations for user: $userId, isAdmin: $isAdmin');
      final query = clientSpb
          .from('reservations')
          .select(
              'id, client_id, service_id, car_id, date_time, status, created_at, service:services(id, name, price, duration)')
          .order('date_time', ascending: true);

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
    required String clientId,
    required String serviceId,
    required String carId,
    required DateTime dateTime,
    String status = 'pending',
  }) async {
    try {
      final data = {
        'client_id': clientId,
        'service_id': serviceId,
        'car_id': carId,
        'date_time': dateTime.toIso8601String(),
        'status': status,
      };
      print('Adding reservation with data: $data');
      final response =
          await clientSpb.from('reservations').insert(data).select().single();
      print('Reservation added response: $response ');
      return true;
    } catch (e) {
      print(
          'addReservation() failed with exception: $e, details: ${e.toString()}');
      return false;
    }
  }

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
