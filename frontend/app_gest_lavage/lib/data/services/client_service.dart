import 'package:app_gest_lavage/core/network/api_fetcher.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/base_service.dart';

class ClientService extends BaseService<AuthModel> {
  late ApiFetcher apiFetcher;

  ClientService() {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    apiFetcher = ApiFetcher(accessToken: accessToken);
  }
  
  Future<List<Client>> getAllEmployees() async {
    try {
      print('Fetching all employees...');
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

}