import 'package:app_gest_lavage/core/network/api_fetcher.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/base_service.dart'; // Adjust import
import 'package:cross_file/cross_file.dart' as cross_file; // For XFile
// For ApiFetcher integration
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService extends BaseService {
  late final SupabaseClient client;
  late final ApiFetcher apiFetcher;

  ClientService() {
    client = Supabase.instance.client;
    apiFetcher = ApiFetcher(
      accessToken: client.auth.currentSession?.accessToken,
      baseUrl: 'http://10.0.2.2:3000', // Match your backend URL
    );
  }

  bool _isValidContact(String contact) {
    const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
    const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(phoneRegExp).hasMatch(contact) ||
        RegExp(emailRegExp).hasMatch(contact);
  }

  Future<List<Client>> getAllClients() async {
    try {
      print('Fetching all Clients...');
      final roleResponse = await client
          .from('user_roles')
          .select('user_id')
          .eq('role_id', 'client');

      print('Users with client role: $roleResponse');
      if (roleResponse.isEmpty) {
        print('No users with client role found.');
        return [];
      }

      final userIds =
          roleResponse.map((item) => item['user_id'] as String).toList();
      print('Client user IDs: $userIds');

      final response = await client.from('users').select('''
          id,
          name,
          status,
          client!left(contact, details, photo, start_date),
          roles:user_roles(*, app_role!inner(id))
        ''').inFilter('id', userIds);

      print('Raw Supabase response: $response');
      if (response.isEmpty) {
        print('No matching users found in the users table.');
      } else {
        for (var item in response) {
          print('Response item: $item');
          print('Client field: ${item['client']}');
        }
      }

      final employees = response.map((map) {
        print('Mapping employee: $map');
        return Client.fromMap(map);
      }).toList();

      print('Fetched ${employees.length} employees');
      return employees;
    } catch (e) {
      print("getAllEmployees() failed: $e");
      return [];
    }
  }

  @override
  Future<AuthModel?> getUser() async {
    try {
      final user = client.auth.currentUser!;
      print('Fetching user data for userId: ${user.id}');

      final response = await client
          .from('users')
          .select(
              'id, name, status, client(contact, details, photo, start_date), roles:user_roles(*, app_role(*))')
          .eq('id', user.id)
          .single();

      print('Supabase response: $response');

      final roleList = List<Map<String, dynamic>>.from(response['roles'] ?? []);
      if (roleList.isEmpty) {
        print('No roles found for user');
        return null;
      }

      final role = roleList
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList()
          .first
          .id;
      print('User role: $role');

      switch (role) {
        case 'client':
          return Client.fromMap(response);
        case 'admin':
          await client.from('admin').upsert({'id': user.id}).eq('id', user.id);
          return Admin.fromMap(response);
        default:
          print('Unknown role: $role');
          return null;
      }
    } catch (e) {
      print("❌ getUser() failed: $e");
      return null;
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    String? contact,
    XFile? photo,
    String? details,
    DateTime? startDate,
    String? status,
    List<String>? roles,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'name': name,
        'contact': contact,
        'details': details,
        'start_date': startDate?.toIso8601String(),
        'status': status ?? 'active',
        'roles': roles ?? ['client'],
      };
      final response = await apiFetcher.post('/user', body: body, file: photo);
      print('Create user response: $response');
      return response.isSuccess && (response.data?['success'] ?? false);
    } catch (e) {
      print('❌ Create user failed: $e');
      return false;
    }
  }

  Future<bool> updateClient({
    required String userId,
    required String role,
    String? name,
    String? contact,
    String? details,
    cross_file.XFile? photo,
    DateTime? startDate,
    Status? status,
    String? email,
  }) async {
    try {
      // Validate inputs
      if (name != null && name.trim().isEmpty) {
        print('Validation failed: Name cannot be empty');
        return false;
      }
      if (contact != null && contact.trim().isEmpty) {
        contact = null; // Treat empty contact as null
      }
      if (contact != null && !_isValidContact(contact)) {
        print('Validation failed: Invalid contact format');
        return false;
      }
      if (email != null &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        print('Validation failed: Invalid email format');
        return false;
      }

      // Get current user and their role
      final currentUser = client.auth.currentUser!;
      final roleResponse = await client
          .from('user_roles')
          .select('app_role(id)')
          .eq('user_id', currentUser.id)
          .single();
      final userRole = roleResponse['app_role']['id'];
      final isAdmin = userRole == 'admin';
      final isSelf = currentUser.id == userId;

      // Authorize update if user is admin or updating their own profile
      if (!isAdmin && !isSelf) {
        print(
            'Unauthorized: Only admins or the user themselves can update this profile');
        return false;
      }
      if (!isAdmin && (startDate != null || status != null)) {
        print('Unauthorized: Only admins can update start_date or status');
        return false;
      }

      // Prepare updates for each table
      final userUpdates = <String, dynamic>{};
      final clientUpdates = <String, dynamic>{};
      String? photoUrl;

      // Update auth.users (email and user_metadata.name)
      if ((email != null || name != null) && isSelf) {
        final attributes = UserAttributes(
          email: email?.trim(),
          data: name != null ? {'name': name.trim()} : null,
        );
        await client.auth.updateUser(attributes);
      }

      // Update public.users (name and status)
      if (name != null && name.trim().isNotEmpty)
        userUpdates['name'] = name.trim();
      if (status != null && isAdmin) userUpdates['status'] = status.value;

      // Update public.client (client-specific fields)
      if (role == 'client') {
        if (contact != null && contact.trim().isNotEmpty) {
          clientUpdates['contact'] = contact.trim();
        }
        if (details != null && details.trim().isNotEmpty) {
          clientUpdates['details'] = details.trim();
        }
        if (photo != null) {
          final photoPath =
              '$role/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
          photoUrl = await _uploadPhoto(photo, photoPath);
          if (photoUrl == null) {
            print('❌ Photo upload failed');
            return false;
          }
          clientUpdates['photo'] = photoUrl;
        }
        if (isAdmin && startDate != null) {
          clientUpdates['start_date'] = startDate.toIso8601String();
        }
      }

      // Debug: Print updates to verify
      print('User updates: $userUpdates');
      print('Client updates: $clientUpdates');

      // Apply updates to public.users
      if (userUpdates.isNotEmpty) {
        await client
            .from(AuthModel.usersTableName)
            .update(userUpdates)
            .eq('id', userId);
      }

      // Apply updates to public.client
      if (clientUpdates.isNotEmpty) {
        await client.from('client').update(clientUpdates).eq('id', userId);
      }

      print('Updated client: $userId');
      return true;
    } catch (e) {
      print("updateClient() failed: $e");
      return false;
    }
  }

  Future<String?> _uploadPhoto(cross_file.XFile photo, String path) async {
    try {
      print('Uploading photo');
      final fileBytes = await photo.readAsBytes();
      await client.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: photo.mimeType ?? 'image/jpeg',
            ),
          );
      print("Photo uploaded to avatars");
      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      print('Photo URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print("Photo upload failed: $e");
      return null;
    }
  }

  Future<bool> registerAndConfirmClient({
    required String name,
    required String email,
    required String password,
    required String contact,
    required String start_date,
  }) async {
    try {
      final response = await apiFetcher.post('/register-public', body: {
        'name': name,
        'email': email,
        'password': password,
        'contact': contact,
        'start_date': start_date,
      });

      if (response.isSuccess &&
          response.data is Map &&
          response.data['success'] == true) {
        print('✅ Utilisateur inscrit via API admin');
        return true;
      } else {
        print("❌ Erreur backend: ${response.error ?? response.data}");
        return false;
      }
    } catch (e) {
      print('❌ registerAndConfirmClient() failed: $e');
      return false;
    }
  }

  // Future<bool> updateClient({
  //   required String id,
  //   String? name,
  //   String? status,
  //   String? contact,
  //   String? details,
  //   String? photo,
  //   DateTime? startDate,
  // }) async {
  //   try {
  //     print('Updating client: $id');
  //     final response = await apiFetcher.post('/update-client', body: {
  //       'id': id,
  //       'name': name,
  //       'status': status,
  //       'contact': contact,
  //       'details': details,
  //       'photo': photo,
  //       'start_date': startDate?.toIso8601String(),
  //     });

  //     print('API response: $response');
  //     if (response.isSuccess && response.data is Map && response.data['success'] == true) {
  //       print('✅ Client updated successfully');
  //       return true;
  //     } else {
  //       print('❌ API error: ${response.error ?? response.data}');
  //       return false;
  //     }
  //   } catch (e) {
  //     print('❌ updateClient failed: $e');
  //     return false;
  //   }
  // }

  Future<bool> deleteClient(String clientId) async {
    try {
      print('Deleting client: $clientId');
      final response = await apiFetcher.post('/delete-client', body: {
        'id': clientId,
      });

      print('API response: $response');
      if (response.isSuccess &&
          response.data is Map &&
          response.data['success'] == true) {
        print('✅ Client deleted successfully');
        return true;
      } else {
        print('❌ API error: ${response.error ?? response.data}');
        return false;
      }
    } catch (e) {
      print('❌ deleteClient failed: $e');
      return false;
    }
  }
}
