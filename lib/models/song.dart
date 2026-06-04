import 'package:uuid/uuid.dart';

enum SongStatus {
  idea,
  drafting,
  recording,
  mixing,
  mastered,
}

String songStatusToString(SongStatus status) {
  switch (status) {
    case SongStatus.idea:
      return 'Idea';
    case SongStatus.drafting:
      return 'Drafting';
    case SongStatus.recording:
      return 'Recording';
    case SongStatus.mixing:
      return 'Mixing';
    case SongStatus.mastered:
      return 'Mastered';
  }
}

class SongTask {
  final String id;
  String title;
  bool isCompleted;

  SongTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SongTask.fromJson(Map<String, dynamic> json) => SongTask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class LyricVersion {
  final String id;
  final String lyrics;
  final String chords; // Snapshot of chord progression at this draft
  final DateTime timestamp;
  final String note;

  LyricVersion({
    required this.id,
    required this.lyrics,
    required this.chords,
    required this.timestamp,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lyrics': lyrics,
        'chords': chords,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory LyricVersion.fromJson(Map<String, dynamic> json) => LyricVersion(
        id: json['id'] as String,
        lyrics: json['lyrics'] as String,
        chords: json['chords'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String? ?? '',
      );
}

class VoiceMemo {
  final String id;
  final String title;
  final int bpm;
  final String rhythmPattern;
  final DateTime dateCreated;
  final String filePath; // Can be mock or actual path

  VoiceMemo({
    required this.id,
    required this.title,
    required this.bpm,
    required this.rhythmPattern,
    required this.dateCreated,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'bpm': bpm,
        'rhythmPattern': rhythmPattern,
        'dateCreated': dateCreated.toIso8601String(),
        'filePath': filePath,
      };

  factory VoiceMemo.fromJson(Map<String, dynamic> json) => VoiceMemo(
        id: json['id'] as String,
        title: json['title'] as String,
        bpm: json['bpm'] as int? ?? 120,
        rhythmPattern: json['rhythmPattern'] as String? ?? 'Boom Bap',
        dateCreated: DateTime.parse(json['dateCreated'] as String),
        filePath: json['filePath'] as String? ?? '',
      );
}

class InspirationComment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;

  InspirationComment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory InspirationComment.fromJson(Map<String, dynamic> json) => InspirationComment(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Artist',
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class InspirationItem {
  final String id;
  final String title;
  final String type; // 'link', 'image', 'text'
  final String content;
  final List<InspirationComment> comments;
  final DateTime timestamp;

  InspirationItem({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.comments,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'content': content,
        'comments': comments.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory InspirationItem.fromJson(Map<String, dynamic> json) => InspirationItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled Inspiration',
        type: json['type'] as String? ?? 'text',
        content: json['content'] as String? ?? '',
        comments: (json['comments'] as List<dynamic>?)
                ?.map((e) => InspirationComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Song {
  final String id;
  String title;
  int bpm;
  String keySignature;
  String timeSignature;
  SongStatus status;
  List<String> chords; // e.g. ["C", "G", "Am", "F"]
  List<LyricVersion> lyricVersions;
  List<VoiceMemo> voiceMemos;
  List<InspirationItem> inspirationItems;
  List<SongTask> tasks;
  DateTime lastModified;

  Song({
    required this.id,
    required this.title,
    this.bpm = 120,
    this.keySignature = 'C Maj',
    this.timeSignature = '4/4',
    this.status = SongStatus.idea,
    required this.chords,
    required this.lyricVersions,
    required this.voiceMemos,
    required this.inspirationItems,
    required this.tasks,
    required this.lastModified,
  });

  String get currentLyrics {
    if (lyricVersions.isEmpty) return '';
    return lyricVersions.last.lyrics;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'bpm': bpm,
        'keySignature': keySignature,
        'timeSignature': timeSignature,
        'status': status.index,
        'chords': chords,
        'lyricVersions': lyricVersions.map((e) => e.toJson()).toList(),
        'voiceMemos': voiceMemos.map((e) => e.toJson()).toList(),
        'inspirationItems': inspirationItems.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'lastModified': lastModified.toIso8601String(),
      };

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'New Song',
      bpm: json['bpm'] as int? ?? 120,
      keySignature: json['keySignature'] as String? ?? 'C Maj',
      timeSignature: json['timeSignature'] as String? ?? '4/4',
      status: SongStatus.values[json['status'] as int? ?? 0],
      chords: List<String>.from(json['chords'] as List<dynamic>? ?? []),
      lyricVersions: (json['lyricVersions'] as List<dynamic>?)
              ?.map((e) => LyricVersion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      voiceMemos: (json['voiceMemos'] as List<dynamic>?)
              ?.map((e) => VoiceMemo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inspirationItems: (json['inspirationItems'] as List<dynamic>?)
              ?.map((e) => InspirationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => SongTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastModified: DateTime.parse(json['lastModified'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  static Song createNew() {
    final uuid = const Uuid().v4();
    return Song(
      id: uuid,
      title: 'Untitled Song',
      bpm: 120,
      keySignature: 'C Maj',
      timeSignature: '4/4',
      status: SongStatus.idea,
      chords: ['C', 'G', 'Am', 'F'],
      lyricVersions: [
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: '[Verse 1]\nStart writing your lyrics here...\n\n[Chorus]\nAnd add a chorus...',
          chords: 'C G Am F',
          timestamp: DateTime.now(),
          note: 'Initial Scratchpad',
        )
      ],
      voiceMemos: [],
      inspirationItems: [],
      tasks: [
        SongTask(id: const Uuid().v4(), title: 'Draft initial lyrics'),
        SongTask(id: const Uuid().v4(), title: 'Choose chord progression'),
        SongTask(id: const Uuid().v4(), title: 'Record a rhythmic voice memo'),
        SongTask(id: const Uuid().v4(), title: 'Refine vocal arrangement'),
      ],
      lastModified: DateTime.now(),
    );
  }
}
