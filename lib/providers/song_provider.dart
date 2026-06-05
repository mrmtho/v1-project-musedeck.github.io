import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/song.dart';

class SongProvider with ChangeNotifier {
  final List<Song> _songs = [];
  final List<CaptureItem> _inbox = [];
  Song? _activeSong;

  SongProvider() {
    _loadInitialSongs();
  }

  List<Song> get songs => List.unmodifiable(_songs);
  List<CaptureItem> get inbox => List.unmodifiable(_inbox);
  Song? get activeSong => _activeSong;

  void _loadInitialSongs() {
    // Populate Capture Inbox demo items
    _inbox.addAll([
      CaptureItem(
        id: const Uuid().v4(),
        type: 'audio',
        title: 'Late Night Riff Humming',
        content: 'mock_record_path_1.wav',
        dateCreated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      CaptureItem(
        id: const Uuid().v4(),
        type: 'text',
        title: 'Bridge lyrics inspiration',
        content: 'Maybe start with "Silent waves under the moon..." and escalate to the vocal chorus.',
        dateCreated: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      CaptureItem(
        id: const Uuid().v4(),
        type: 'photo',
        title: 'Synthesizer Panel Settings Photo',
        content: 'https://images.unsplash.com/photo-1598653222000-6b7b7a552625',
        dateCreated: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    // Populate with dummy songs
    final demoSong1 = Song(
      id: const Uuid().v4(),
      title: 'Neon Horizon',
      bpm: 110,
      keySignature: 'A Min',
      timeSignature: '4/4',
      status: SongStatus.drafting,
      groupType: SongGroupType.album,
      isArchived: false,
      chords: ['Am', 'F', 'C', 'G', 'Am', 'F', 'Dm', 'E'],
      lyricVersions: [
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: '[Verse 1]\nWalking down the neon street\nFading shadows at my feet\nNo one left here to meet\nJust the echo of a beat\n\n[Chorus]\nOh, Neon Horizon, shine your light\nGuide me through the endless night\nEverything will be alright\nNeon Horizon, so bright',
          chords: 'Am F C G',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          note: 'First verse draft',
        ),
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: '[Verse 1]\nWalking down the neon street\nFading shadows at my feet\nNo one left here to meet\nJust the echo of a beat\n\n[Verse 2]\nCyber rain is falling down\nWash away this silent town\nSearching for a lost crown\nBut I think I\'m gonna drown\n\n[Chorus]\nOh, Neon Horizon, shine your light\nGuide me through the endless night\nEverything will be alright\nNeon Horizon, so bright',
          chords: 'Am F C G Am F Dm E',
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          note: 'Added verse 2 and expanded chords',
        )
      ],
      voiceMemos: [
        VoiceMemo(
          id: const Uuid().v4(),
          title: 'Vocal Melody Idea - Verse',
          bpm: 110,
          rhythmPattern: 'Boom Bap',
          dateCreated: DateTime.now().subtract(const Duration(days: 1)),
          filePath: '/memos/neon_horizon_verse.wav',
        )
      ],
      inspirationItems: [
        InspirationItem(
          id: const Uuid().v4(),
          title: 'Cyberpunk Aesthetic Photo',
          type: 'image',
          content: 'https://images.unsplash.com/photo-1515621061946-eff1c2a352bd',
          comments: [
            InspirationComment(
              id: const Uuid().v4(),
              author: 'Alex (Producer)',
              text: 'Love the glowing cyan tones. Let\'s make the synth bass sound like this visual.',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
            )
          ],
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        InspirationItem(
          id: const Uuid().v4(),
          title: 'Reference Track: Kavinsky - Nightcall',
          type: 'link',
          content: 'https://youtube.com/watch?v=MV_3Dpw-BRY',
          comments: [
            InspirationComment(
              id: const Uuid().v4(),
              author: 'Sarah (Vocals)',
              text: 'We should use a vocoder effect on the chorus similar to this track.',
              timestamp: DateTime.now().subtract(const Duration(hours: 8)),
            )
          ],
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        )
      ],
      tasks: [
        SongTask(id: const Uuid().v4(), title: 'Finish chorus melody', isCompleted: true),
        SongTask(id: const Uuid().v4(), title: 'Write Verse 3 lyrics'),
        SongTask(id: const Uuid().v4(), title: 'Record synth scratch track'),
        SongTask(id: const Uuid().v4(), title: 'Schedule vocal session with Sarah'),
      ],
      collaborators: ['Alex (Producer)', 'Sarah (Vocals)'],
      lastModified: DateTime.now().subtract(const Duration(hours: 4)),
    );

    final demoSong2 = Song(
      id: const Uuid().v4(),
      title: 'Acoustic Sunday',
      bpm: 85,
      keySignature: 'G Maj',
      timeSignature: '3/4',
      status: SongStatus.idea,
      groupType: SongGroupType.single,
      isArchived: false,
      chords: ['G', 'C', 'D', 'Em', 'G', 'C', 'Am', 'D'],
      lyricVersions: [
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: '[Verse 1]\nCoffee is brewing warm and sweet\nSunlight falling on the street\nSlowly waking up our feet\nSundays are the best treat\n\n[Chorus]\nSinging G, C, D on a Sunday afternoon\nHope the rain doesn\'t come too soon',
          chords: 'G C D Em',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          note: 'Acoustic jam layout',
        )
      ],
      voiceMemos: [],
      inspirationItems: [],
      tasks: [
        SongTask(id: const Uuid().v4(), title: 'Determine key structure'),
        SongTask(id: const Uuid().v4(), title: 'Write bridge lyrics'),
      ],
      collaborators: [],
      lastModified: DateTime.now().subtract(const Duration(days: 5)),
    );

    // Collaboration demo song
    final collabSong = Song(
      id: const Uuid().v4(),
      title: 'Midnight Drive',
      bpm: 124,
      keySignature: 'D Min',
      timeSignature: '4/4',
      status: SongStatus.recording,
      groupType: SongGroupType.ep,
      isArchived: false,
      chords: ['Dm', 'Gm', 'C', 'F'],
      lyricVersions: [
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: '[Chorus]\nDriving through the city lights\nLooking for the perfect heights\nMidnight drive, just you and I...',
          chords: 'Dm Gm C F',
          timestamp: DateTime.now().subtract(const Duration(days: 10)),
          note: 'Collab verse sketch',
        )
      ],
      voiceMemos: [],
      inspirationItems: [],
      tasks: [
        SongTask(id: const Uuid().v4(), title: 'Approve final mix down'),
      ],
      collaborators: ['Marcus (Synth Wave Band)', 'Dave (Manager)'],
      lastModified: DateTime.now().subtract(const Duration(days: 1)),
    );

    // Archived Vault demo song
    final archivedSong = Song(
      id: const Uuid().v4(),
      title: 'Echoes of 2023',
      bpm: 95,
      keySignature: 'C Maj',
      timeSignature: '4/4',
      status: SongStatus.mastered,
      groupType: SongGroupType.liveSet,
      isArchived: true,
      chords: ['C', 'G', 'Am', 'F'],
      lyricVersions: [
        LyricVersion(
          id: const Uuid().v4(),
          lyrics: 'This is an old nostalgic track from the vault.',
          chords: 'C G Am F',
          timestamp: DateTime.now().subtract(const Duration(days: 1000)),
          note: 'Vault record',
        )
      ],
      voiceMemos: [],
      inspirationItems: [],
      tasks: [],
      collaborators: [],
      lastModified: DateTime.now().subtract(const Duration(days: 1000)),
    );

    _songs.addAll([demoSong1, demoSong2, collabSong, archivedSong]);
    _activeSong = demoSong1;
    notifyListeners();
  }

  void selectSong(Song song) {
    _activeSong = song;
    notifyListeners();
  }

  void createNewSong({String title = 'Untitled Song', SongGroupType groupType = SongGroupType.single}) {
    final newSong = Song.createNew(title: title, groupType: groupType);
    _songs.add(newSong);
    _activeSong = newSong;
    notifyListeners();
  }

  void deleteSong(String id) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs.removeAt(index);
      if (_activeSong?.id == id) {
        _activeSong = _songs.isNotEmpty ? _songs.first : null;
      }
      notifyListeners();
    }
  }

  // Archive / Vault Management
  void archiveSong(String id) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index].isArchived = true;
      _songs[index].lastModified = DateTime.now();
      notifyListeners();
    }
  }

  void restoreSong(String id) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index].isArchived = false;
      _songs[index].lastModified = DateTime.now();
      notifyListeners();
    }
  }

  // Group Type management
  void updateSongGroupType(String id, SongGroupType groupType) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index].groupType = groupType;
      _songs[index].lastModified = DateTime.now();
      notifyListeners();
    }
  }

  // Collaborator management
  void addCollaborator(String id, String collaborator) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      if (!_songs[index].collaborators.contains(collaborator)) {
        _songs[index].collaborators.add(collaborator);
        _songs[index].lastModified = DateTime.now();
        notifyListeners();
      }
    }
  }

  void removeCollaborator(String id, String collaborator) {
    final index = _songs.indexWhere((s) => s.id == id);
    if (index != -1) {
      _songs[index].collaborators.remove(collaborator);
      _songs[index].lastModified = DateTime.now();
      notifyListeners();
    }
  }

  // Capture Inbox Management
  void addCaptureItem(String title, String type, String content) {
    final item = CaptureItem(
      id: const Uuid().v4(),
      type: type,
      title: title,
      content: content,
      dateCreated: DateTime.now(),
    );
    _inbox.insert(0, item);
    notifyListeners();
  }

  void deleteCaptureItem(String id) {
    _inbox.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void convertCaptureToSong(String captureId, String songTitle, SongGroupType groupType) {
    final index = _inbox.indexWhere((item) => item.id == captureId);
    if (index != -1) {
      final item = _inbox[index];
      
      // Create a new song using the capture content
      final newSong = Song.createNew(title: songTitle.isNotEmpty ? songTitle : item.title, groupType: groupType);
      
      if (item.type == 'text') {
        newSong.lyricVersions.add(LyricVersion(
          id: const Uuid().v4(),
          lyrics: item.content,
          chords: 'C G Am F',
          timestamp: DateTime.now(),
          note: 'Imported from Text Capture',
        ));
      } else if (item.type == 'audio') {
        newSong.voiceMemos.add(VoiceMemo(
          id: const Uuid().v4(),
          title: item.title,
          bpm: 120,
          rhythmPattern: 'Boom Bap',
          dateCreated: DateTime.now(),
          filePath: item.content,
        ));
      } else if (item.type == 'photo') {
        newSong.inspirationItems.add(InspirationItem(
          id: const Uuid().v4(),
          title: item.title,
          type: 'image',
          content: item.content,
          comments: [],
          timestamp: DateTime.now(),
        ));
      }

      _songs.add(newSong);
      _activeSong = newSong;
      _inbox.removeAt(index);
      notifyListeners();
    }
  }

  void updateActiveSongTitle(String title) {
    if (_activeSong == null) return;
    _activeSong!.title = title;
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void updateActiveSongMetadata({
    int? bpm,
    String? keySignature,
    String? timeSignature,
    SongStatus? status,
  }) {
    if (_activeSong == null) return;
    if (bpm != null) _activeSong!.bpm = bpm;
    if (keySignature != null) _activeSong!.keySignature = keySignature;
    if (timeSignature != null) _activeSong!.timeSignature = timeSignature;
    if (status != null) _activeSong!.status = status;
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void updateActiveSongChords(List<String> chords) {
    if (_activeSong == null) return;
    _activeSong!.chords = chords;
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void saveLyricVersion(String lyrics, String chordsSnapshot, String note) {
    if (_activeSong == null) return;
    final newVersion = LyricVersion(
      id: const Uuid().v4(),
      lyrics: lyrics,
      chords: chordsSnapshot,
      timestamp: DateTime.now(),
      note: note.isNotEmpty ? note : 'Snapshot ${DateTime.now().toLocal()}',
    );
    _activeSong!.lyricVersions.add(newVersion);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void addVoiceMemo(String title, int bpm, String rhythmPattern, String filePath) {
    if (_activeSong == null) return;
    final memo = VoiceMemo(
      id: const Uuid().v4(),
      title: title,
      bpm: bpm,
      rhythmPattern: rhythmPattern,
      dateCreated: DateTime.now(),
      filePath: filePath,
    );
    _activeSong!.voiceMemos.insert(0, memo);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void addInspirationItem(String title, String type, String content) {
    if (_activeSong == null) return;
    final item = InspirationItem(
      id: const Uuid().v4(),
      title: title,
      type: type,
      content: content,
      comments: [],
      timestamp: DateTime.now(),
    );
    _activeSong!.inspirationItems.insert(0, item);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void addInspirationComment(String itemId, String author, String text) {
    if (_activeSong == null) return;
    final index = _activeSong!.inspirationItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final comment = InspirationComment(
        id: const Uuid().v4(),
        author: author,
        text: text,
        timestamp: DateTime.now(),
      );
      _activeSong!.inspirationItems[index].comments.add(comment);
      _activeSong!.lastModified = DateTime.now();
      notifyListeners();
    }
  }

  void deleteInspirationItem(String itemId) {
    if (_activeSong == null) return;
    _activeSong!.inspirationItems.removeWhere((i) => i.id == itemId);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void deleteVoiceMemo(String memoId) {
    if (_activeSong == null) return;
    _activeSong!.voiceMemos.removeWhere((v) => v.id == memoId);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void toggleTask(String taskId) {
    if (_activeSong == null) return;
    final index = _activeSong!.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _activeSong!.tasks[index].isCompleted = !_activeSong!.tasks[index].isCompleted;
      _activeSong!.lastModified = DateTime.now();
      notifyListeners();
    }
  }

  void addTask(String title) {
    if (_activeSong == null) return;
    final task = SongTask(
      id: const Uuid().v4(),
      title: title,
    );
    _activeSong!.tasks.add(task);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }

  void deleteTask(String taskId) {
    if (_activeSong == null) return;
    _activeSong!.tasks.removeWhere((t) => t.id == taskId);
    _activeSong!.lastModified = DateTime.now();
    notifyListeners();
  }
}
