import 'package:path/path.dart' as p;

class Document {
  final int id;
  final int categoryId;
  final String? titleRu;
  final String? titleEn;
  final String? originalFilename;
  final String fileType;
  final String? relativePath;
  final int textLength;
  final int fileSize;

  Document({
    required this.id,
    required this.categoryId,
    this.titleRu,
    this.titleEn,
    this.originalFilename,
    required this.fileType,
    this.relativePath,
    this.textLength = 0,
    this.fileSize = 0,
  });

  factory Document.fromMap(Map<String, dynamic> map) => Document(
        id: map['id'] as int,
        categoryId: map['category_id'] as int,
        titleRu: map['title_ru'] as String?,
        titleEn: map['title_en'] as String?,
        originalFilename: map['original_filename'] as String?,
        fileType: map['file_type'] as String,
        relativePath: map['relative_path'] as String?,
        textLength: (map['text_length'] as int?) ?? 0,
        fileSize: (map['file_size'] as int?) ?? 0,
      );

  String get pdfAssetPath {
    // Use relative_path (e.g. "01_Engine\HFC4GB2.4D\01.01...docx")
    // to build nested PDF path: "assets/pdf/01_Engine/HFC4GB2.4D/01.01....pdf"
    if (relativePath != null && relativePath!.isNotEmpty) {
      // Normalize backslashes to forward slashes for cross-platform (Android/iOS)
      final normalPath = relativePath!.replaceAll('\\', '/');
      final stem = p.setExtension(normalPath, '.pdf');
      return 'assets/pdf/$stem';
    }
    // Fallback for documents without relative_path
    final name = originalFilename ?? '';
    final stem = p.setExtension(name, '.pdf');
    return 'assets/pdf/$stem';
  }
}
