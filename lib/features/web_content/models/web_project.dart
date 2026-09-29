class WebProject {
  final String id;
  final String? internalProjectId;
  final String title;
  final String category;
  final String location;
  final String description;
  final String? coverPath;
  final bool featured;
  final bool published;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WebProject({
    required this.id,
    this.internalProjectId,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    this.coverPath,
    required this.featured,
    required this.published,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebProject.fromJson(Map<String, dynamic> json) {
    return WebProject(
      id: json['id'] as String,
      internalProjectId: json['internal_project_id'] as String?,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'Construcción',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverPath: json['cover_path'] as String?,
      featured: json['featured'] as bool? ?? false,
      published: json['published'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
