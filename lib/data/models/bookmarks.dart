class Bookmark {
  final String questionId;
  final String bookmarkId;
  final String? note;

  Bookmark({
    required this.questionId,
    required this.bookmarkId,
    this.note,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      questionId: json['questionId'].toString(),
      bookmarkId: json['bookmarkId'].toString(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
    "questionId": questionId,
    "bookmarkId": bookmarkId,
    "note": note,
  };
}