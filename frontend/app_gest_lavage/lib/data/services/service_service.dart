import 'package:app_gest_lavage/data/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceService {
  final SupabaseClient clientSpb = Supabase.instance.client;

  Future<List<Service>> getServices({required bool isAdmin}) async {
    try {
      print('Fetching services for isAdmin: $isAdmin');
      final query = clientSpb
          .from('services')
          .select('id, name, description, price, duration, created_at');

      final response = await query;
      print('Raw services response: $response');

      return response.map((map) {
        try {
          return Service.fromMap(map);
        } catch (e) {
          print('Error parsing service map: $map, error: $e');
          throw Exception('Failed to parse service: $e');
        }
      }).toList();
    } catch (e) {
      print('getServices() failed with exception: $e');
      rethrow; // Rethrow to allow caller to handle the error
    }
  }

  Future<bool> updateService({
    required String id,
    String? name,
    String? description,
    int? price,
    int? duration,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
      }
      if (description != null) {
        updates['description'] = description.trim();
      }
      if (price != null && price >= 0) {
        updates['price'] = price;
      }
      if (duration != null && duration >= 0) {
        updates['duration'] = duration;
      }

      if (updates.isEmpty) {
        print('No updates provided for service');
        return true;
      }

      final response = await clientSpb
          .from('services')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      print('Service updated: $response');
      return true;
    } catch (e) {
      print('updateService() failed: $e');
      return false;
    }
  }

  Future<bool> addService({
    required String name,
    String? description,
    required int price,
    required int duration,
  }) async {
    try {
      final data = {
        'name': name.trim(),
        'description': description?.trim(),
        'price': price,
        'duration': duration,
      };
      print('Adding service with data: $data');
      final response =
          await clientSpb.from('services').insert(data).select().single();
      print('Service added: $response');
      return true;
    } catch (e) {
      print('addService() failed: $e');
      return false;
    }
  }
}
