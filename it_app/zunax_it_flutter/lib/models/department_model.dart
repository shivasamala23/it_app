class DepartmentModel {
  final int id;
  final String name;
  final String emailAlias;
  final int ticketCount;
  final int resolvedCount;

  DepartmentModel({
    required this.id,
    required this.name,
    this.emailAlias = '',
    this.ticketCount = 0,
    this.resolvedCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      emailAlias: json['email_alias'] ?? '',
      ticketCount: json['ticket_count'] ?? 0,
      resolvedCount: json['resolved_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email_alias': emailAlias,
      };
}
