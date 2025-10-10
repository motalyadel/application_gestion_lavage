import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarService {
  final clientSpb = Supabase.instance.client;

  Future<List<Car>> getCars({bool isAdmin = false}) async {
    try {
      final query = clientSpb.from('cars').select(
          'id, client_id, marque, modele, immatriculation, created_at, updated_at');

      if (!isAdmin) {
        final userId = clientSpb.auth.currentUser?.id;
        if (userId == null) {
          print('No user logged in');
          throw Exception('Utilisateur non connecté');
        }
        print('Filtering cars for client_id: $userId');
        query.eq('client_id', userId);
      } else {
        print('Fetching all cars for admin');
      }

      final response = await query;
      print('Cars response: $response');

      return response.map((map) => Car.fromMap(map)).toList();
    } catch (e) {
      print('getCars() failed: $e');
      return [];
    }
  }

  // Future<bool> addCar({
  //   required String clientId,
  //   String? marque,
  //   String? modele,
  //   required String immatriculation,
  // }) async {
  //   try {
  //     final data = {
  //       'client_id': clientId,
  //       'marque': marque?.trim(),
  //       'modele': modele?.trim(),
  //       'immatriculation': immatriculation.trim(),
  //       'updated_at': DateTime.now().toIso8601String(),
  //     };
  //     final response =
  //         await clientSpb.from('cars').insert(data).select().single();
  //     print('Car added: $response');
  //     return true;
  //   } catch (e) {
  //     print('addCar() failed: $e');
  //     return false;
  //   }
  // }

  // Future<bool> updateCar({
  //   required String id,
  //   String? marque,
  //   String? modele,
  //   String? immatriculation,
  // }) async {
  //   try {
  //     final updates = <String, dynamic>{};
  //     if (marque != null && marque.trim().isNotEmpty) {
  //       updates['marque'] = marque.trim();
  //     }
  //     if (modele != null && modele.trim().isNotEmpty) {
  //       updates['modele'] = modele.trim();
  //     }
  //     if (immatriculation != null && immatriculation.trim().isNotEmpty) {
  //       updates['immatriculation'] = immatriculation.trim();
  //     }
  //     updates['updated_at'] = DateTime.now().toIso8601String();

  //     if (updates.isEmpty) {
  //       print('No updates provided for car');
  //       return true;
  //     }

  //     final response = await clientSpb
  //         .from('cars')
  //         .update(updates)
  //         .eq('id', id)
  //         .select()
  //         .single();
  //     print('Car updated: $response');
  //     return true;
  //   } catch (e) {
  //     print('updateCar() failed: $e');
  //     return false;
  //   }
  // }

  // Future<bool> deleteCar(String id) async {
  //   try {
  //     await clientSpb.from('cars').delete().eq('id', id);
  //     print('Car deleted: $id');
  //     return true;
  //   } catch (e) {
  //     print('deleteCar() failed: $e');
  //     return false;
  //   }
  // }
}
