class UserModel {
  final int id;
  final String name;
  final String login;
  final String email;
  final bool isSupportStaff;
  final bool isManager;
  final int? employeeId;
  final String? employeeName;
  final String? workEmail;
  final String? mobilePhone;

  UserModel({
    required this.id,
    required this.name,
    required this.login,
    this.email = '',
    this.isSupportStaff = false,
    this.isManager = false,
    this.employeeId,
    this.employeeName,
    this.workEmail,
    this.mobilePhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] is Map ? json['employee'] : null;
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      login: json['login'] ?? '',
      email: json['email'] ?? '',
      isSupportStaff: json['is_support_staff'] ?? false,
      isManager: json['is_manager'] ?? false,
      employeeId: emp != null ? emp['id'] : null,
      employeeName: emp != null ? emp['name'] : null,
      workEmail: emp != null ? emp['work_email'] : null,
      mobilePhone: emp != null ? emp['mobile_phone'] : null,
    );
  }
}
