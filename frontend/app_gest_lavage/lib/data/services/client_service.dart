// import 'package:app_gest_lavage/core/network/api_fetcher.dart';
// import 'package:app_gest_lavage/data/models/auth_model.dart';
// import 'package:app_gest_lavage/data/services/base_service.dart'; // Adjust import
// import 'package:cross_file/cross_file.dart' as cross_file; // For XFile
// import 'package:image_picker/image_picker.dart'; // For XFile
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ClientService extends BaseService {
//   late final SupabaseClient client;
//   late final ApiFetcher apiFetcher;

//   ClientService() {
//     client = Supabase.instance.client;
//     apiFetcher = ApiFetcher(
//       accessToken: client.auth.currentSession?.accessToken,
//       baseUrl: 'http://10.0.2.2:3000', // Match your backend URL
//     );
//   }

//   bool _isValidContact(String contact) {
//     const phoneRegExp = r'^\+?[1-9]\d{1,14}$';
//     const emailRegExp = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
//     return RegExp(phoneRegExp).hasMatch(contact) ||
//         RegExp(emailRegExp).hasMatch(contact);
//   }

//   Future<List<Client>> getAllClients() async {
//     try {
//       print('Fetching all Clients...');
//       // Fetch users with the 'client' role
//       final roleResponse = await client
//           .from('user_roles')
//           .select('user_id')
//           .eq('role_id', 'client'); // Changed from app_role_id to role_id
//       print('Users with client role: $roleResponse');
//       if (roleResponse.isEmpty) {
//         print('No users with client role found.');
//         return [];
//       }
//       final userIds =
//           roleResponse.map((item) => item['user_id'] as String).toList();
//       print('Client user IDs: $userIds');

//       // Fetch user data with client details
//       final response = await client.from('users').select('''
//           id,
//           name,
//           status,
//           client!left(contact, details, photo, start_date),
//           roles:user_roles(role_id, app_role!inner(id)) // Adjusted to use role_id
//         ''').inFilter('id', userIds);
//       print('Raw Supabase response: $response');
//       if (response.isEmpty) {
//         print('No matching users found in the users table.');
//       } else {
//         for (var item in response) {
//           print('Response item: $item');
//           print('Client field: ${item['client']}');
//         }
//       }

//       final clients = response.map((map) {
//         print('Mapping client: $map');
//         return Client.fromMap(map);
//       }).toList();
//       print('Fetched ${clients.length} clients');
//       return clients;
//     } catch (e) {
//       print("getAllClients() failed: $e");
//       return [];
//     }
//   }

//   Future<bool> createClient({
//     required String name,
//     required String email,
//     required String password,
//     String? contact,
//     String? details,
//     DateTime? startDate,
//     Status? status,
//   }) async {
//     try {
//       final currentUser = client.auth.currentUser;
//       final isAdmin = currentUser != null &&
//           (await client
//                   .from('user_roles')
//                   .select('app_role(id)')
//                   .eq('user_id', currentUser.id)
//                   .single())['app_role']['id'] ==
//               'admin';

//       if (isAdmin) {
//         // Admin creates client with full options
//         final success = await createUser(
//           email: email,
//           password: password,
//           name: name,
//           contact: contact,
//           details: details,
//           startDate: startDate,
//           status: status?.value,
//           roles: ['client'],
//         );
//         return success;
//       } else {
//         // Public client registration
//         final startDateStr =
//             startDate?.toIso8601String() ?? DateTime.now().toIso8601String();
//         return await registerAndConfirmClient(
//           name: name,
//           email: email,
//           password: password,
//           contact: contact ?? '',
//           start_date: startDateStr,
//         );
//       }
//     } catch (e) {
//       print('❌ createClient failed: $e');
//       return false;
//     }
//   }

//   @override
//   Future<AuthModel?> getUser() async {
//     try {
//       final user = client.auth.currentUser!;
//       print('Fetching user data for userId: ${user.id}');

//       final response = await client
//           .from('users')
//           .select(
//               'id, name, status, client(contact, details, photo, start_date), roles:user_roles(*, app_role(*))')
//           .eq('id', user.id)
//           .single();

//       print('Supabase response: $response');

//       final roleList = List<Map<String, dynamic>>.from(response['roles'] ?? []);
//       if (roleList.isEmpty) {
//         print('No roles found for user');
//         return null;
//       }

//       final role = roleList
//           .map((item) => AppRole.fromMap(item['app_role']))
//           .toList()
//           .first
//           .id;
//       print('User role: $role');

//       switch (role) {
//         case 'client':
//           return Client.fromMap(response);
//         case 'admin':
//           await client.from('admin').upsert({'id': user.id}).eq('id', user.id);
//           return Admin.fromMap(response);
//         default:
//           print('Unknown role: $role');
//           return null;
//       }
//     } catch (e) {
//       print("❌ getUser() failed: $e");
//       return null;
//     }
//   }

//   Future<bool> createUser({
//     required String email,
//     required String password,
//     required String name,
//     String? contact,
//     XFile? photo,
//     String? details,
//     DateTime? startDate,
//     String? status,
//     List<String>? roles,
//   }) async {
//     try {
//       final body = {
//         'email': email,
//         'password': password,
//         'name': name,
//         'contact': contact,
//         'details': details,
//         'start_date': startDate?.toIso8601String(),
//         'status': status ?? 'active',
//         'roles': roles ?? ['client'],
//       };
//       final response = await apiFetcher.post('/user', body: body, file: photo);
//       print('Create user response: $response');
//       return response.isSuccess && (response.data?['success'] ?? false);
//     } catch (e) {
//       print('❌ Create user failed: $e');
//       return false;
//     }
//   }

//   Future<bool> updateClient({
//     required String userId,
//     required String role,
//     String? name,
//     String? contact,
//     String? details,
//     Status? status,
//     String? email,
//   }) async {
//     try {
//       if (name != null && name.trim().isEmpty) {
//         print('Validation failed: Name cannot be empty');
//         return false;
//       }
//       if (contact != null && contact.trim().isEmpty) {
//         contact = null;
//       }
//       if (contact != null && !_isValidContact(contact)) {
//         print('Validation failed: Invalid contact format');
//         return false;
//       }
//       if (email != null &&
//           !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
//         print('Validation failed: Invalid email format');
//         return false;
//       }
//       final currentUser = client.auth.currentUser!;
//       final roleResponse = await client
//           .from('user_roles')
//           .select('app_role(id)')
//           .eq('user_id', currentUser.id)
//           .single();
//       final userRole = roleResponse['app_role']['id'];
//       final isAdmin = userRole == 'admin';
//       final isSelf = currentUser.id == userId;
//       if (!isAdmin && !isSelf) {
//         print(
//             'Unauthorized: Only admins or the user themselves can update this profile');
//         return false;
//       }
//       if (!isAdmin && status != null) {
//         print('Unauthorized: Only admins can update status');
//         return false;
//       }
//       final userUpdates = <String, dynamic>{};
//       final clientUpdates = <String, dynamic>{};
//       if ((email != null || name != null) && isSelf) {
//         final attributes = UserAttributes(
//           email: email?.trim(),
//           data: name != null ? {'name': name.trim()} : null,
//         );
//         await client.auth.updateUser(attributes);
//       }
//       if (name != null && name.trim().isNotEmpty)
//         userUpdates['name'] = name.trim();
//       if (status != null && isAdmin) userUpdates['status'] = status.value;

//       if (role == 'client') {
//         if (contact != null && contact.trim().isNotEmpty) {
//           clientUpdates['contact'] = contact.trim();
//         }
//         if (details != null && details.trim().isNotEmpty)
//           clientUpdates['details'] = details.trim();
//       }
//       print('User updates: $userUpdates');
//       print('Client updates: $clientUpdates');
//       if (userUpdates.isNotEmpty) {
//         await client
//             .from(AuthModel.usersTableName)
//             .update(userUpdates)
//             .eq('id', userId);
//       }
//       if (clientUpdates.isNotEmpty) {
//         await client.from('client').update(clientUpdates).eq('id', userId);
//       }
//       print('Updated client: $userId');
//       return true;
//     } catch (e) {
//       print("updateClient() failed: $e");
//       return false;
//     }
//   }

//   Future<String?> _uploadPhoto(cross_file.XFile photo, String path) async {
//     try {
//       print('Uploading photo');
//       final fileBytes = await photo.readAsBytes();
//       await client.storage.from('avatars').uploadBinary(
//             path,
//             fileBytes,
//             fileOptions: FileOptions(
//               upsert: true,
//               contentType: photo.mimeType ?? 'image/jpeg',
//             ),
//           );
//       print("Photo uploaded to avatars");
//       final publicUrl = client.storage.from('avatars').getPublicUrl(path);
//       print('Photo URL: $publicUrl');
//       return publicUrl;
//     } catch (e) {
//       print("Photo upload failed: $e");
//       return null;
//     }
//   }

//   Future<bool> registerAndConfirmClient({
//     required String name,
//     required String email,
//     required String password,
//     required String contact,
//     required String start_date,
//   }) async {
//     try {
//       final response = await apiFetcher.post('/register-public', body: {
//         'name': name,
//         'email': email,
//         'password': password,
//         'contact': contact,
//         'start_date': start_date,
//       });

//       if (response.isSuccess &&
//           response.data is Map &&
//           response.data['success'] == true) {
//         print('✅ Utilisateur inscrit via API admin');
//         return true;
//       } else {
//         print("❌ Erreur backend: ${response.error ?? response.data}");
//         return false;
//       }
//     } catch (e) {
//       print('❌ registerAndConfirmClient() failed: $e');
//       return false;
//     }
//   }

//   Future<bool> deleteClient(String clientId) async {
//     try {
//       print('Deleting client: $clientId');
//       final response = await apiFetcher.post('/delete-client', body: {
//         'id': clientId,
//       });

//       print('API response: $response');
//       if (response.isSuccess &&
//           response.data is Map &&
//           response.data['success'] == true) {
//         print('✅ Client deleted successfully');
//         return true;
//       } else {
//         print('❌ API error: ${response.error ?? response.data}');
//         return false;
//       }
//     } catch (e) {
//       print('❌ deleteClient failed: $e');
//       return false;
//     }
//   }
// }





import 'package:app_gest_lavage/core/network/api_fetcher.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/base_service.dart'; // Adjust import
import 'package:cross_file/cross_file.dart' as cross_file; // For XFile
import 'package:image_picker/image_picker.dart'; // For XFile
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientService extends BaseService {
  late final SupabaseClient clientSpb;
  late final ApiFetcher apiFetcher;

  ClientService() {
    clientSpb = Supabase.instance.client;
    apiFetcher = ApiFetcher(
      accessToken: clientSpb.auth.currentSession?.accessToken,
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
      // Fetch users with the 'client' role
      final roleResponse = await clientSpb
          .from('user_roles')
          .select('user_id')
          .eq('role_id', 'client'); // Changed from app_role_id to role_id
      print('Users with client role: $roleResponse');
      if (roleResponse.isEmpty) {
        print('No users with client role found.');
        return [];
      }
      final userIds =
          roleResponse.map((item) => item['user_id'] as String).toList();
      print('Client user IDs: $userIds');

      // Fetch user data with client details
      final response = await clientSpb.from('users').select('''
          id,
          name,
          status,
          client!left(contact, details, photo, start_date),
          roles:user_roles(role_id, app_role!inner(id)) // Adjusted to use role_id
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

      final clients = response.map((map) {
        print('Mapping client: $map');
        return Client.fromMap(map);
      }).toList();
      print('Fetched ${clients.length} clients');
      return clients;
    } catch (e) {
      print("getAllClients() failed: $e");
      return [];
    }
  }

  Future<bool> createClient({
    required String name,
    required String email,
    required String password,
    String? contact,
    String? details,
    DateTime? startDate,
    Status? status,
  }) async {
    try {
      final currentUser = clientSpb.auth.currentUser;
      final isAdmin = currentUser != null &&
          (await clientSpb
                  .from('user_roles')
                  .select('app_role(id)')
                  .eq('user_id', currentUser.id)
                  .single())['app_role']['id'] ==
              'admin';

      if (isAdmin) {
        // Admin creates client with full options
        final success = await createUser(
          email: email,
          password: password,
          name: name,
          contact: contact,
          details: details,
          startDate: startDate,
          status: status?.value,
          roles: ['client'],
        );
        return success;
      } else {
        // Public client registration
        final startDateStr =
            startDate?.toIso8601String() ?? DateTime.now().toIso8601String();
        return await registerAndConfirmClient(
          name: name,
          email: email,
          password: password,
          contact: contact ?? '',
          start_date: startDateStr,
        );
      }
    } catch (e) {
      print('❌ createClient failed: $e');
      return false;
    }
  }

  @override
  Future<AuthModel?> getUser() async {
    try {
      final user = clientSpb.auth.currentUser!;
      print('Fetching user data for userId: ${user.id}');

      final response = await clientSpb
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
          await clientSpb
              .from('admin')
              .upsert({'id': user.id}).eq('id', user.id);
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
    Status? status,
    String? email,
  }) async {
    try {
      if (name != null && name.trim().isEmpty) {
        print('Validation failed: Name cannot be empty');
        return false;
      }
      if (contact != null && contact.trim().isEmpty) {
        contact = null;
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
      final currentUser = clientSpb.auth.currentUser!;
      final roleResponse = await clientSpb
          .from('user_roles')
          .select('app_role(id)')
          .eq('user_id', currentUser.id)
          .single();
      final userRole = roleResponse['app_role']['id'];
      final isAdmin = userRole == 'admin';
      final isSelf = currentUser.id == userId;
      if (!isAdmin && !isSelf) {
        print(
            'Unauthorized: Only admins or the user themselves can update this profile');
        return false;
      }
      if (!isAdmin && status != null) {
        print('Unauthorized: Only admins can update status');
        return false;
      }
      final userUpdates = <String, dynamic>{};
      final clientUpdates = <String, dynamic>{};
      if ((email != null || name != null) && isSelf) {
        final attributes = UserAttributes(
          email: email?.trim(),
          data: name != null ? {'name': name.trim()} : null,
        );
        await clientSpb.auth.updateUser(attributes);
      }
      if (name != null && name.trim().isNotEmpty)
        userUpdates['name'] = name.trim();
      if (status != null && isAdmin) userUpdates['status'] = status.value;

      if (role == 'client') {
        if (contact != null && contact.trim().isNotEmpty) {
          clientUpdates['contact'] = contact.trim();
        }
        if (details != null && details.trim().isNotEmpty)
          clientUpdates['details'] = details.trim();
      }
      print('User updates: $userUpdates');
      print('Client updates: $clientUpdates');
      if (userUpdates.isNotEmpty) {
        await clientSpb
            .from(AuthModel.usersTableName)
            .update(userUpdates)
            .eq('id', userId);
      }
      if (clientUpdates.isNotEmpty) {
        await clientSpb.from('client').update(clientUpdates).eq('id', userId);
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
      await clientSpb.storage.from('avatars').uploadBinary(
            path,
            fileBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: photo.mimeType ?? 'image/jpeg',
            ),
          );
      print("Photo uploaded to avatars");
      final publicUrl = clientSpb.storage.from('avatars').getPublicUrl(path);
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
