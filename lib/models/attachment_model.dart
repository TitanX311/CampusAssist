// lib/models/attachment_model.dart

class Attachment {
  final String id;
  final String filename;
  final String mimeType;
  final int size; // bytes
  final String? url; // pre-signed or direct download URL, if returned by API
  final DateTime uploadedAt;

  const Attachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.size,
    this.url,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    id: json['id'] as String,
    filename: json['filename'] as String? ?? '',
    mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
    size: json['size'] as int? ?? 0,
    url: json['url'] as String?,
    uploadedAt: DateTime.parse(
      json['uploaded_at'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'mime_type': mimeType,
    'size': size,
    'url': url,
    'uploaded_at': uploadedAt.toIso8601String(),
  };
}
