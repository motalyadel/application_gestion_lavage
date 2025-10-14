import 'dart:io';

import 'package:app_gest_lavage/data/models/car_model.dart';
import 'package:app_gest_lavage/core/network/api_fetcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarService {
  final clientSpb = Supabase.instance.client;
  final apiFetcher = ApiFetcher(
    accessToken: Supabase.instance.client.auth.currentSession?.accessToken,
    baseUrl: 'http://10.0.2.2:3000',
  );

  Future<List<Car>> getCars({bool isAdmin = false}) async {
    try {
      final query = clientSpb.from('cars').select(
          'id, user_id, marque, modele, immatriculation, created_at, updated_at');

      if (!isAdmin) {
        final userId = clientSpb.auth.currentUser?.id;
        if (userId == null) {
          print('No user logged in');
          throw Exception('Utilisateur non connecté');
        }
        print('Filtering cars for user_id: $userId');
        query.eq('user_id', userId);
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

  Future<List<Car>> getAllCars() async {
    try {
      print('Fetching all cars...');

      final userId = clientSpb.auth.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        throw Exception('Utilisateur non connecté');
      }

      bool isAdmin = false;
      final roleResponse = await clientSpb
          .from('user_roles')
          .select('role_id')
          .eq('user_id', userId)
          .maybeSingle();
      print('Role response for user $userId: $roleResponse');
      if (roleResponse != null && roleResponse['role_id'] == 'admin') {
        isAdmin = true;
      }
      print('isAdmin: $isAdmin');

      final query = clientSpb.from('cars').select(
          'id, user_id, marque, modele, immatriculation, created_at, updated_at');

      if (!isAdmin) {
        print('Filtering cars for user_id: $userId');
        query.eq('user_id', userId);
      } else {
        print('Fetching all cars for admin');
      }

      final response = await query;
      print('Raw cars response: $response');

      if (response.isEmpty) {
        print('No cars found.');
        return [];
      }

      final cars = response.map((map) {
        print('Mapping car: $map');
        return Car.fromMap(map);
      }).toList();

      print('Fetched ${cars.length} cars');
      return cars;
    } catch (e) {
      print('getAllCars() failed: $e');
      return [];
    }
  }

  Future<bool> addCar({
    required String userId,
    String? marque,
    String? modele,
    required String immatriculation,
  }) async {
    try {
      final data = {
        'user_id': userId,
        'marque': marque?.trim(),
        'modele': modele?.trim(),
        'immatriculation': immatriculation.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      print('Adding car with data: $data');
      final response =
          await clientSpb.from('cars').insert(data).select().single();
      print('Car added: $response');
      return true;
    } catch (e) {
      print('addCar() failed: $e');
      return false;
    }
  }

  Future<bool> updateCar({
    required String id,
    String? marque,
    String? modele,
    String? immatriculation,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (marque != null && marque.trim().isNotEmpty) {
        updates['marque'] = marque.trim();
      }
      if (modele != null && modele.trim().isNotEmpty) {
        updates['modele'] = modele.trim();
      }
      if (immatriculation != null && immatriculation.trim().isNotEmpty) {
        updates['immatriculation'] = immatriculation.trim();
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (updates.isEmpty) {
        print('No updates provided for car');
        return true;
      }

      final response = await clientSpb
          .from('cars')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      print('Car updated: $response');
      return true;
    } catch (e) {
      print('updateCar() failed: $e');
      return false;
    }
  }

  Future<bool> deleteCar(String id) async {
    try {
      if (clientSpb.auth.currentUser == null) {
        print('No user logged in, attempting to refresh session'); stdout.flush();
        await clientSpb.auth.refreshSession();
        if (clientSpb.auth.currentUser == null) {
          print('Session refresh failed'); stdout.flush();
          throw Exception('Utilisateur non connecté');
        }
      }

      // Update apiFetcher with latest token
      final apiFetcher = ApiFetcher(
        accessToken: Supabase.instance.client.auth.currentSession?.accessToken,
        baseUrl: 'http://10.0.2.2:3000', // Update to 'https://xxxx.ngrok.io' if using ngrok
      );

      // Call the POST /delete-car endpoint
      final response = await apiFetcher.post('delete-car', body: {'id': id}).timeout(Duration(seconds: 15));
      print('Delete car response: $response'); stdout.flush();

      if (!response.isSuccess) {
        print('Failed to delete car: ${response.error} (Status: ${response.status})'); stdout.flush();
        throw Exception('Échec de la suppression de la voiture : ${response.error}');
      }

      print('Car deleted: $id'); stdout.flush();
      return true;
    } catch (e, stackTrace) {
      print('deleteCar() failed: $e'); stdout.flush();
      print('Stack trace: $stackTrace'); stdout.flush();
      throw Exception('Échec de la suppression de la voiture : $e');
    }
  }
}
