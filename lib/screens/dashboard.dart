import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../widgets/chord_progression_editor.dart';
import '../widgets/creative_timeline.dart';
import '../widgets/inspiration_board.dart';
import '../widgets/lyric_editor.dart';
import '../widgets/rhythmic_memo_recorder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _activeSongId;

  // Active navigation view: 'capture', 'library', 'collab', 'vault', 'workspace'
  String _activeView = 'library';
  String _vaultSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(SongStatus status) {
    switch (status) {
      case SongStatus.idea:
        return const Color(0xFF9E9E9E);
      case SongStatus.drafting:
        return const Color(0xFFD03BFF);
      case SongStatus.recording:
        return const Color(0xFFFF5252);
      case SongStatus.mixing:
        return const Color(0xFF00FFCC);
      case SongStatus.mastered:
        return const Color(0xFFFFD700);
    }
  }

  Widget _buildSidebar(SongProvider provider, List<Song> songs, Song? activeSong, {bool isDrawer = false}) {
    return Container(
      width: 260,
      color: const Color(0xFF13131A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FFCC), Color(0xFFD03BFF)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.blur_on, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MuseDeck',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD03BFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD03BFF).withOpacity(0.4), width: 0.8),
                      ),
                      child: const Text(
                        'v0.01',
                        style: TextStyle(
                          color: Color(0xFFD03BFF),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'AI Powered Music Organizer for Modern Artists',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sidebar Nav Items
          _buildSidebarNavItem(
            icon: Icons.mic,
            label: 'Capture (Inbox)',
            isSelected: _activeView == 'capture',
            badgeCount: provider.inbox.length,
            onTap: () {
              setState(() => _activeView = 'capture');
              if (isDrawer) Navigator.of(context).pop();
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.library_music,
            label: 'Song Library',
            isSelected: _activeView == 'library',
            onTap: () {
              setState(() => _activeView = 'library');
              if (isDrawer) Navigator.of(context).pop();
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.people,
            label: 'Collaborations',
            isSelected: _activeView == 'collab',
            onTap: () {
              setState(() => _activeView = 'collab');
              if (isDrawer) Navigator.of(context).pop();
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.archive,
            label: 'The Vault',
            isSelected: _activeView == 'vault',
            onTap: () {
              setState(() => _activeView = 'vault');
              if (isDrawer) Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          _buildSidebarNavItem(
            icon: Icons.notifications_none,
            label: 'Updates',
            isSelected: false,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              _showUpdatesDialog(context);
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.more_horiz,
            label: 'More',
            isSelected: false,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              _showMoreDialog(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFF1E1E2E) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? const Color(0xFF00FFCC) : Colors.grey[400],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Changelog - v0.01',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '🎉 Welcome to MuseDeck!',
                style: TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                '• Left side panel navigation system linking Capture, Song Library, Collaborations, and The Vault.\n'
                '• Enhanced moodboard with YouTube thumbnail extractors and Spotify/SoundCloud placeholders.\n'
                '• Continuous press-and-hold sound synthesis with sustaining audio envelopes.\n'
                '• Multi-track backing generator synchronized directly with active session BPM.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Great', style: TextStyle(color: Color(0xFF00FFCC))),
            ),
          ],
        );
      },
    );
  }

  void _showMoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'MuseDeck Workspace Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Audio Preferences', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.grey),
                title: const Text('Backup Workspace Data', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text('Interactive Guide', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(SongProvider provider, Song? activeSong, bool showSidebar) {
    if (_activeView == 'workspace') {
      if (activeSong == null) {
        return const Center(
          child: Text('Create or select a song to open workspace', style: TextStyle(color: Colors.white)),
        );
      }
      return _buildWorkspaceView(provider, activeSong, showSidebar);
    } else if (_activeView == 'capture') {
      return _buildCaptureInboxView(provider);
    } else if (_activeView == 'collab') {
      return _buildCollaborationsView(provider);
    } else if (_activeView == 'vault') {
      return _buildTheVaultView(provider);
    } else {
      return _buildSongLibraryView(provider);
    }
  }

  // View: Capture Inbox (Inbox)
  Widget _buildCaptureInboxView(SongProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎙️ Capture Inbox',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Landing pad for quick ideas. Capture now, organize later.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // Massive Action Button Row
          Row(
            children: [
              Expanded(
                child: _buildMassiveCaptureButton(
                  icon: Icons.mic,
                  label: 'Hum Riff / Audio',
                  color: const Color(0xFFD03BFF),
                  onTap: () {
                    provider.addCaptureItem(
                      'Hum Idea #${Random().nextInt(100)}',
                      'audio',
                      'mock_record_inbox.wav',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Captured audio memo to inbox!'), backgroundColor: Color(0xFFD03BFF)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMassiveCaptureButton(
                  icon: Icons.edit_note,
                  label: 'Draft Text Note',
                  color: const Color(0xFF00FFCC),
                  onTap: () => _showAddTextCaptureDialog(context, provider),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMassiveCaptureButton(
                  icon: Icons.add_a_photo,
                  label: 'Scan Photo Reference',
                  color: const Color(0xFFFFD700),
                  onTap: () {
                    provider.addCaptureItem(
                      'Synthesizer Reference',
                      'photo',
                      'https://images.unsplash.com/photo-1598653222000-6b7b7a552625',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Captured photo scan reference!'), backgroundColor: Color(0xFFFFD700)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Unorganized Inbox Ideas',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provider.inbox.isEmpty
                ? const Center(
                    child: Text('Inbox is clean! All ideas sorted.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: provider.inbox.length,
                    itemBuilder: (context, index) {
                      final item = provider.inbox[index];
                      IconData typeIcon = Icons.notes;
                      Color typeColor = Colors.grey;
                      if (item.type == 'audio') {
                        typeIcon = Icons.audiotrack;
                        typeColor = const Color(0xFFD03BFF);
                      } else if (item.type == 'photo') {
                        typeIcon = Icons.photo;
                        typeColor = const Color(0xFFFFD700);
                      } else if (item.type == 'text') {
                        typeIcon = Icons.text_snippet;
                        typeColor = const Color(0xFF00FFCC);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: typeColor.withOpacity(0.1),
                              child: Icon(typeIcon, color: typeColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.content,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'UNORGANIZED',
                                style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00FFCC).withOpacity(0.15),
                                foregroundColor: const Color(0xFF00FFCC),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => _showSortCaptureDialog(context, provider, item),
                              icon: const Icon(Icons.sort, size: 14),
                              label: const Text('Sort / Workspace', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () => provider.deleteCaptureItem(item.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMassiveCaptureButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTextCaptureDialog(BuildContext context, SongProvider provider) {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text('Quick Note Capture', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(labelText: 'Write thoughts...', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFCC), foregroundColor: Colors.black),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && noteCtrl.text.isNotEmpty) {
                  provider.addCaptureItem(titleCtrl.text, 'text', noteCtrl.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _showSortCaptureDialog(BuildContext context, SongProvider provider, CaptureItem item) {
    final titleCtrl = TextEditingController(text: item.title);
    SongGroupType selectedGroup = SongGroupType.single;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text('Sort to Song Workspace', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'New Song Title', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Group Into:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<SongGroupType>(
                      dropdownColor: const Color(0xFF1E1E2E),
                      value: selectedGroup,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: SongGroupType.values.map((val) {
                        return DropdownMenuItem<SongGroupType>(
                          value: val,
                          child: Text(songGroupTypeToString(val)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedGroup = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFCC), foregroundColor: Colors.black),
                  onPressed: () {
                    provider.convertCaptureToSong(item.id, titleCtrl.text, selectedGroup);
                    Navigator.pop(context);
                    setState(() {
                      _activeView = 'workspace';
                    });
                  },
                  child: const Text('Create Workspace'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // View: Song Library (Macro Library representation)
  Widget _buildSongLibraryView(SongProvider provider) {
    // Exclude archived songs
    final songs = provider.songs.where((s) => !s.isArchived).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎵 Song Library',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFCC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  provider.createNewSong(title: 'New Workspace #${songs.length + 1}');
                  setState(() => _activeView = 'workspace');
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Song Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildLibrarySection(provider, songs, SongGroupType.single, '💿 Singles'),
                _buildLibrarySection(provider, songs, SongGroupType.ep, '📼 EPs'),
                _buildLibrarySection(provider, songs, SongGroupType.album, '🎸 Albums'),
                _buildLibrarySection(provider, songs, SongGroupType.liveSet, '🎤 Live Sets'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrarySection(SongProvider provider, List<Song> allSongs, SongGroupType type, String sectionTitle) {
    final filtered = allSongs.where((s) => s.groupType == type).toList();
    if (filtered.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            sectionTitle,
            style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.9,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final song = filtered[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    provider.selectSong(song);
                    setState(() => _activeView = 'workspace');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${song.bpm} BPM • ${song.keySignature} • ${song.timeSignature}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.archive_outlined, color: Colors.grey, size: 18),
                              onPressed: () {
                                provider.archiveSong(song.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Archived "${song.title}" to The Vault!')),
                                );
                              },
                            ),
                          ],
                        ),
                        // Custom visual progress bar representing Writing -> Mastered
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Progress status:', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text(
                                  songStatusToString(song.status),
                                  style: TextStyle(
                                    color: _getStatusColor(song.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildProgressNodes(song.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressNodes(SongStatus currentStatus) {
    final List<SongStatus> stages = SongStatus.values;
    final int currentIndex = stages.indexOf(currentStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        final nodeWidth = constraints.maxWidth;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            
            return Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFF00FFCC)
                        : (isCompleted ? const Color(0xFFD03BFF) : Colors.white10),
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00FFCC).withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (index < stages.length - 1)
                  Container(
                    width: (nodeWidth - 50) / (stages.length - 1),
                    height: 2,
                    color: index < currentIndex
                        ? const Color(0xFFD03BFF)
                        : Colors.white10,
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  // View: Collaborations Panel
  Widget _buildCollaborationsView(SongProvider provider) {
    // Songs containing collaborators
    final songs = provider.songs.where((s) => s.collaborators.isNotEmpty && !s.isArchived).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Collaborations',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track files, split sheets, and shared sessions.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No active collaboration workspaces.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'BPM: ${song.bpm} • Key: ${song.keySignature} • Time: ${song.timeSignature}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FFCC).withOpacity(0.15),
                                    foregroundColor: const Color(0xFF00FFCC),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () {
                                    provider.selectSong(song);
                                    setState(() => _activeView = 'workspace');
                                  },
                                  icon: const Icon(Icons.exit_to_app, size: 14),
                                  label: const Text('Open Workspace', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            const Text('Collaborators & Split shares', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: song.collaborators.map((c) {
                                // Mock some splits
                                final int splitShare = (100 / (song.collaborators.length + 1)).round();
                                return Chip(
                                  backgroundColor: const Color(0xFF1E1E2E),
                                  side: BorderSide.none,
                                  label: Text(
                                    '$c ($splitShare%)',
                                    style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 11),
                                  ),
                                  avatar: CircleAvatar(
                                    backgroundColor: const Color(0xFFD03BFF),
                                    child: Text(
                                      c[0],
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }).toList()
                                ..add(
                                  Chip(
                                    backgroundColor: const Color(0xFF1E1E2E),
                                    side: BorderSide.none,
                                    label: Text(
                                      'Me (${(100 / (song.collaborators.length + 1) + (100 % (song.collaborators.length + 1))).round()}%)',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    avatar: const CircleAvatar(
                                      backgroundColor: Color(0xFF00FFCC),
                                      child: Icon(Icons.person, color: Colors.black, size: 10),
                                    ),
                                  ),
                                ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // View: The Vault (Archived ideas)
  Widget _buildTheVaultView(SongProvider provider) {
    // Search filter
    final songs = provider.songs
        .where((s) => s.isArchived && s.title.toLowerCase().contains(_vaultSearchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🗃️ The Vault (Archived Ideas)',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fully searchable repository for old drafts or discarded riffs.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          // Vault Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search archive by riff/melody title...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF13131A),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00FFCC)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _vaultSearchQuery = val;
              });
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text('No archived ideas match search.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final lastModStr = DateFormat('MMMM dd, yyyy').format(song.lastModified);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Archived: $lastModStr • ${song.bpm} BPM',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD03BFF).withOpacity(0.15),
                                    foregroundColor: const Color(0xFFD03BFF),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    provider.restoreSong(song.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Restored "${song.title}" to active library!')),
                                    );
                                  },
                                  icon: const Icon(Icons.unarchive, size: 14),
                                  label: const Text('Restore', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    provider.deleteSong(song.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Permanently deleted "${song.title}"')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // View: Song Workspace Panel (Edit song contents - Chords, Lyrics, metronome etc.)
  Widget _buildWorkspaceView(SongProvider provider, Song activeSong, bool showSidebar) {
    final bool stackPanels = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _activeView = 'library';
            });
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Song Title',
                ),
                onChanged: (val) {
                  provider.updateActiveSongTitle(val);
                },
              ),
            ),
            const SizedBox(width: 8),
            _buildMetadataDropdown(
              label: 'Key',
              value: activeSong.keySignature,
              items: ['C Maj', 'G Maj', 'D Maj', 'A Maj', 'E Maj', 'F Maj', 'A Min', 'E Min', 'D Min', 'B Min'],
              onChanged: (val) {
                if (val != null) {
                  provider.updateActiveSongMetadata(keySignature: val);
                }
              },
            ),
            const SizedBox(width: 8),
            _buildMetadataDropdown(
              label: 'Time',
              value: activeSong.timeSignature,
              items: ['4/4', '3/4', '6/8', '5/4'],
              onChanged: (val) {
                if (val != null) {
                  provider.updateActiveSongMetadata(timeSignature: val);
                }
              },
            ),
          ],
        ),
      ),
      body: stackPanels
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ChordProgressionEditor(),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 400,
                    child: LyricEditor(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 480,
                    child: _buildTabsPanel(),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ChordProgressionEditor(),
                        SizedBox(height: 20),
                        Expanded(child: LyricEditor()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                    child: _buildTabsPanel(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF00FFCC),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00FFCC),
            tabs: const [
              Tab(icon: Icon(Icons.mic, size: 18), text: 'Sketches'),
              Tab(icon: Icon(Icons.lightbulb, size: 18), text: 'Moodboard'),
              Tab(icon: Icon(Icons.timeline, size: 18), text: 'Roadmap'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                RhythmicMemoRecorder(),
                InspirationBoard(),
                CreativeTimeline(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E1E2E),
              value: value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              items: items.map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final songs = provider.songs;
    final activeSong = provider.activeSong;

    if (activeSong != null && _activeSongId != activeSong.id) {
      _activeSongId = activeSong.id;
      _titleController.text = activeSong.title;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showSidebar = constraints.maxWidth >= 950;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D14),
          drawer: !showSidebar ? Drawer(child: _buildSidebar(provider, songs, activeSong, isDrawer: true)) : null,
          body: Row(
            children: [
              // Left Sidebar
              if (showSidebar) _buildSidebar(provider, songs, activeSong),
              
              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Header bar with drawer trigger for mobile
                    if (!showSidebar)
                      AppBar(
                        backgroundColor: const Color(0xFF13131A),
                        leading: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        title: const Text('MuseDeck', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    Expanded(
                      child: _buildMainContent(provider, activeSong, showSidebar),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
