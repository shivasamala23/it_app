class SubjectModel {
  final int id;
  final String name;
  final int? departmentId;
  final String? departmentName;

  SubjectModel({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    int? deptId;
    String? deptName;

    if (json['department'] is Map) {
      deptId = json['department']['id'];
      deptName = json['department']['name'];
    } else if (json['department_id'] is List && (json['department_id'] as List).isNotEmpty) {
      deptId = json['department_id'][0];
      deptName = json['department_id'][1]?.toString();
    }

    return SubjectModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      departmentId: deptId,
      departmentName: deptName,
    );
  }
}
