class WebProjectImage {
  final String id;
  final String projectId;
  final String storagePath;
  final String caption;
  final int sortOrder;
  final DateTime createdAt;

  const WebProjectImage({
    required this.id,
    required this.projectId,
    required this.storagePath,
    required this.caption,
    required this.sortOrder,
    required this.createdAt,
  });

  factory WebProjectImage.fromJson(Map<String, dynamic> json) {
    return WebProjectImage(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      storagePath: json['storage_path'] as String,
      caption: json['caption'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
