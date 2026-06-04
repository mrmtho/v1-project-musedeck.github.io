import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';

class LyricEditor extends StatefulWidget {
  const LyricEditor({super.key});

  @override
  State<LyricEditor> createState() => _LyricEditorState();
}

class _LyricEditorState extends State<LyricEditor> {
  final TextEditingController _lyricsController = TextEditingController();
  final TextEditingController _commitNoteController = TextEditingController();
  String? _activeSongId;
  LyricVersion? _selectedCompareVersion;
  bool _showHistory = false;

  @override
  void dispose() {
    _lyricsController.dispose();
    _commitNoteController.dispose();
    super.dispose();
  }

  void _saveSnapshot(SongProvider provider, Song song) {
    final note = _commitNoteController.text.trim();
    final text = _lyricsController.text;
    final chordsStr = song.chords.join(' ');

    provider.saveLyricVersion(text, chordsStr, note);
    _commitNoteController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(note.isNotEmpty ? 'Saved snapshot: "$note"' : 'Lyric snapshot saved!'),
        backgroundColor: const Color(0xFFD03BFF),
      ),
    );
  }

  void _restoreVersion(SongProvider provider, LyricVersion version) {
    setState(() {
      _lyricsController.text = version.lyrics;
      _selectedCompareVersion = null;
      _showHistory = false;
    });

    // Save a new version tracking the restore
    final chordsList = version.chords.split(' ').where((c) => c.isNotEmpty).toList();
    provider.updateActiveSongChords(chordsList);
    provider.saveLyricVersion(
      version.lyrics,
      version.chords,
      'Restored: ${version.note.isNotEmpty ? version.note : "Previous Draft"}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restored past lyric and chord draft!'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final song = provider.activeSong;

    if (song == null) return const SizedBox();

    // Reset controllers if switching songs
    if (_activeSongId != song.id) {
      _activeSongId = song.id;
      _lyricsController.text = song.currentLyrics;
      _selectedCompareVersion = null;
      _showHistory = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: Color(0xFFD03BFF)),
                    const SizedBox(width: 8),
                    const Text(
                      'Lyric Drafts',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Toggle History pane
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showHistory ? const Color(0xFFD03BFF) : const Color(0xFF2E2E3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    setState(() {
                      _showHistory = !_showHistory;
                      if (!_showHistory) {
                        _selectedCompareVersion = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.history, size: 16),
                  label: Text(_showHistory ? 'Hide History' : 'Version History'),
                ),
              ],
            ),
          ),
          // Main Body
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text Editor
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Save Snapshot Input field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commitNoteController,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Enter snapshot note (e.g. Added chorus lyrics)...',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFF13131A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD03BFF).withOpacity(0.2),
                                foregroundColor: const Color(0xFFD03BFF),
                                side: const BorderSide(color: Color(0xFFD03BFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => _saveSnapshot(provider, song),
                              child: const Text('Commit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Main Lyrics input
                        Expanded(
                          child: TextField(
                            controller: _lyricsController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                              fontFamily: 'RobotoMono',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Start writing your lyric verses and choruses here...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              // Autosave to memory model without creating commits
                              if (song.lyricVersions.isNotEmpty) {
                                final activeVerList = List<LyricVersion>.from(song.lyricVersions);
                                if (activeVerList.isNotEmpty) {
                                  final popped = activeVerList.removeLast();
                                  activeVerList.add(LyricVersion(
                                    id: popped.id,
                                    lyrics: val,
                                    chords: popped.chords,
                                    timestamp: DateTime.now(),
                                    note: popped.note,
                                  ));
                                  song.lyricVersions = activeVerList;
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Version History Sidebar (if enabled)
                if (_showHistory) ...[
                  const VerticalDivider(width: 1, color: Colors.white10),
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: const Color(0xFF13131A).withOpacity(0.5),
                      child: _selectedCompareVersion != null
                          ? _buildCompareView(provider)
                          : _buildHistoryListView(song),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView(Song song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'VERSION LOG',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: song.lyricVersions.length,
            itemBuilder: (context, idx) {
              // Show in reverse chronological order
              final index = song.lyricVersions.length - 1 - idx;
              final ver = song.lyricVersions[index];
              final isCurrent = index == song.lyricVersions.length - 1;
              final formattedTime = DateFormat('MMM dd, hh:mm a').format(ver.timestamp);

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  dense: true,
                  title: Text(
                    ver.note.isNotEmpty ? ver.note : 'Snapshot $index',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '$formattedTime • ${ver.chords.isNotEmpty ? ver.chords : "No Chords"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  onTap: () {
                    setState(() {
                      _selectedCompareVersion = ver;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompareView(SongProvider provider) {
    final selectedVer = _selectedCompareVersion!;
    final formattedTime = DateFormat('MMM dd, hh:mm a').format(selectedVer.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compare Header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black.withOpacity(0.25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                onPressed: () {
                  setState(() {
                    _selectedCompareVersion = null;
                  });
                },
              ),
              const Text(
                'Compare Snapshot',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        // Compare Card details
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  selectedVer.note.isNotEmpty ? selectedVer.note : 'Snapshot Draft',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: $formattedTime',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(height: 6),
                if (selectedVer.chords.isNotEmpty) ...[
                  Text(
                    'Chords: ${selectedVer.chords}',
                    style: const TextStyle(color: Color(0xFFD03BFF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _restoreVersion(provider, selectedVer),
                  icon: const Icon(Icons.restore, size: 14),
                  label: const Text('Restore This Draft', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DRAFT LYRICS:',
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Text(
                    selectedVer.lyrics,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.5,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
