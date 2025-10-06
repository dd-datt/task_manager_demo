class Task {
  final int? id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;

  Task({this.id, required this.title, this.description = '', this.isDone = false, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  // Chuyển đổi Task thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Tạo Task từ Map (đọc từ SQLite)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isDone: (map['isDone'] ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Tạo bản sao Task với các thông tin được cập nhật
  Task copyWith({int? id, String? title, String? description, bool? isDone, DateTime? createdAt}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, description: $description, isDone: $isDone, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
