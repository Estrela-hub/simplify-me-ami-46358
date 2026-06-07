class Note {
  final String id;
  final String title;
  final String textContent;
  final String? imagePath;
  final String? audioPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    String? id,
    required this.title,
    required this.textContent,
    this.imagePath,
    this.audioPath,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Note copyWith({
    String? title,
    String? textContent,
    String? imagePath,
    String? audioPath,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}