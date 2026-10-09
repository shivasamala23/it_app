class TicketModel {
  final int id;
  final String ticketNumber;
  final String name;
  final String stage; // draft | new | in_progress | resolved | cancelled
  final String priority; // 0=Low, 1=Medium, 2=High, 3=Urgent
  final String description;
  final String resolutionNotes;
  final String cancellationReason;
  final String email;
  final String phone;
  final String? createDate;
  final String? dateResolved;
  final double? resolutionTime;

  final int? departmentId;
  final String? departmentName;

  final int? subjectId;
  final String? subjectName;

  final int? employeeId;
  final String? employeeName;

  final int? assignedUserId;
  final String? assignedUserName;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.name,
    required this.stage,
    required this.priority,
    this.description = '',
    this.resolutionNotes = '',
    this.cancellationReason = '',
    this.email = '',
    this.phone = '',
    this.createDate,
    this.dateResolved,
    this.resolutionTime,
    this.departmentId,
    this.departmentName,
    this.subjectId,
    this.subjectName,
    this.employeeId,
    this.employeeName,
    this.assignedUserId,
    this.assignedUserName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic val) {
      if (val is Map) return val['id'];
      if (val is List && val.isNotEmpty) return val[0];
      return null;
    }

    String? parseName(dynamic val) {
      if (val is Map) return val['name'];
      if (val is List && val.length > 1) return val[1].toString();
      return null;
    }

    return TicketModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      ticketNumber: json['ticket_number'] ?? 'IT#${json['id']}',
      name: json['name'] ?? '',
      stage: json['stage'] ?? 'draft',
      priority: json['priority']?.toString() ?? '1',
      description: json['description'] ?? '',
      resolutionNotes: json['resolution_notes'] ?? '',
      cancellationReason: json['cancellation_reason'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createDate: json['create_date'],
      dateResolved: json['date_resolved'],
      resolutionTime: (json['resolution_time'] as num?)?.toDouble(),
      departmentId: parseId(json['department'] ?? json['department_id']),
      departmentName: parseName(json['department'] ?? json['department_id']),
      subjectId: parseId(json['subject'] ?? json['subject_id']),
      subjectName: parseName(json['subject'] ?? json['subject_id']),
      employeeId: parseId(json['employee'] ?? json['employee_id']),
      employeeName: parseName(json['employee'] ?? json['employee_id']),
      assignedUserId: parseId(json['assigned_to'] ?? json['assigned_user_id']),
      assignedUserName: parseName(json['assigned_to'] ?? json['assigned_user_id']),
    );
  }

  String get priorityLabel {
    switch (priority) {
      case '0': return 'Low';
      case '1': return 'Medium';
      case '2': return 'High';
      case '3': return 'Urgent';
      default: return 'Medium';
    }
  }

  String get stageLabel {
    switch (stage) {
      case 'draft': return 'Draft';
      case 'new': return 'New';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'cancelled': return 'Cancelled';
      default: return stage;
    }
  }
}

class ChatterMessage {
  final int id;
  final String authorName;
  final String body;
  final String date;

  ChatterMessage({
    required this.id,
    required this.authorName,
    required this.body,
    required this.date,
  });

  factory ChatterMessage.fromJson(Map<String, dynamic> json) {
    String author = 'System';
    if (json['author_id'] is List && (json['author_id'] as List).length > 1) {
      author = json['author_id'][1];
    }
    return ChatterMessage(
      id: json['id'] ?? 0,
      authorName: author,
      body: json['body'] ?? '',
      date: json['date'] ?? '',
    );
  }
}
