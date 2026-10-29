class RoomReport {
  const RoomReport({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.priority,
    required this.reportedBy,
    required this.reportedAt,
    this.resolvedAt,
  });

  final int id;
  final String title;
  final String description;
  final String location;
  final String status;
  final String priority;
  final String reportedBy;
  final DateTime reportedAt;
  final DateTime? resolvedAt;

  factory RoomReport.fromJson(Map<String, dynamic> json) {
    return RoomReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? 'Issue Report').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? 'General').toString(),
      status: (json['status'] ?? 'open').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      reportedBy: (json['reportedBy'] ?? 'Facility Staff').toString(),
      reportedAt: json['reportedAt'] != null
          ? (DateTime.tryParse(json['reportedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
    );
  }

  factory RoomReport.newReport({
    required int id,
    required String title,
    required String description,
    required String location,
    required String priority,
    required String reportedBy,
  }) {
    return RoomReport(
      id: id,
      title: title,
      description: description,
      location: location,
      status: 'open',
      priority: priority,
      reportedBy: reportedBy,
      reportedAt: DateTime.now(),
    );
  }
}
