abstract class AuthModel {
  final String id;
  final String? name;
  final String? status;
  final List<AppRole> roles;

  AppRole get currentRole => roles[0];

  AuthModel({
    required this.id,
    this.name,
    this.status,
    required this.roles,
  });

  Map<String, dynamic> toMap();

  AuthModel copyWith();

  static String get usersTableName => "users";

  get token => null;
}

enum Status {
  active('Active'),
  onLeave('On Leave'),
  resigned('Resigned');

  final String value;
  const Status(this.value);

  static Status fromString(String value) {
    return Status.values.firstWhere(
      (status) => status.value == value,
      orElse: () => Status.active,
    );
  }
}

class Client extends AuthModel {
  final String? contact;
  final String? details;
  final String? photo;
  final DateTime? startDate;

  Client({
    required super.id,
    required super.roles,
    super.name,
    super.status,
    this.contact,
    this.details,
    this.photo,
    this.startDate,
  });

  static String get tableName => "Client";

  factory Client.fromMap(Map<String, dynamic> map) {
    final roleList = List<Map<String, dynamic>>.from(map['roles'] ?? []);
    final roles =
        roleList.map((item) => AppRole.fromMap(item['app_role'])).toList();

    final clientData = map['client'] as Map<String, dynamic>? ?? {};
    return Client(
      id: map['id'] as String,
      name: map['name'] as String?,
      status: map['status'] as String?,
      contact: clientData['contact'] as String?,
      details: clientData['details'] as String?,
      photo: clientData['photo'] as String?,
      startDate: clientData['start_date'] != null
          ? DateTime.parse(clientData['start_date'] as String)
          : null,
      roles: roles.isNotEmpty ? roles : [AppRole(id: 'client')],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'contact': contact,
        'details': details,
        'photo': photo,
        'start_date': startDate?.toIso8601String(),
      };

  @override
  Client copyWith({
    String? name,
    String? status,
    String? contact,
    String? details,
    String? photo,
    DateTime? startDate,
  }) {
    return Client(
      id: id,
      roles: roles,
      name: name ?? this.name,
      status: status ?? this.status,
      contact: contact ?? this.contact,
      details: details ?? this.details,
      photo: photo ?? this.photo,
      startDate: startDate ?? this.startDate,
    );
  }
}

class Admin extends AuthModel {
  Admin({
    required super.id,
    required super.roles,
    super.name,
    super.status,
  });

  static String get tableName => "admin";

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'] as String,
      name: map['name'] as String?,
      status: map['status'] as String?,
      roles: List<Map<String, dynamic>>.from(map['roles'] ?? [])
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
      };

  @override
  Admin copyWith({
    String? name,
    String? status,
  }) {
    return Admin(
      id: id,
      roles: roles,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }
}
class AppRole {
  final String id;

  AppRole({required this.id});

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] as String,
    );
  }
}