import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  String? _activeSongId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
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
      width: 250,
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
          // Create New Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD03BFF).withOpacity(0.15),
                foregroundColor: const Color(0xFFD03BFF),
                side: const BorderSide(color: Color(0xFFD03BFF)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                provider.createNewSong();
                if (isDrawer) {
                  Navigator.of(context).pop(); // Close drawer
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Created new song workspace!'),
                    backgroundColor: Color(0xFFD03BFF),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'New Song Workspace',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Scrollable Songs list
          Expanded(
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final s = songs[index];
                final isActive = activeSong?.id == s.id;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Material(
                    color: isActive ? const Color(0xFF1E1E2E) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isActive ? Colors.white.withOpacity(0.05) : Colors.transparent,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    onTap: () {
                      provider.selectSong(s);
                      if (isDrawer) {
                        Navigator.of(context).pop(); // Close drawer
                      }
                    },
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[400],
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Text(
                            '${s.bpm} BPM • ${s.keySignature}',
                            style: TextStyle(
                              color: isActive ? Colors.white70 : Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(s.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: isActive
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                            onPressed: () {
                              provider.deleteSong(s.id);
                            },
                          )
                        : null,
                  ),
                ),
              );
            },
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
        final bool stackPanels = constraints.maxWidth < 850;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D14),
          // Attach Drawer on narrow screens
          drawer: !showSidebar ? Drawer(child: _buildSidebar(provider, songs, activeSong, isDrawer: true)) : null,
          body: Row(
            children: [
              // Left Sidebar (desktop only)
              if (showSidebar) _buildSidebar(provider, songs, activeSong),
              
              // Main content body
              Expanded(
                child: activeSong == null
                    ? Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: !showSidebar
                            ? AppBar(
                                backgroundColor: const Color(0xFF13131A),
                                leading: Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () => Scaffold.of(context).openDrawer(),
                                  ),
                                ),
                                title: const Text('MuseDeck', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              )
                            : null,
                        body: const Center(
                          child: Text(
                            'Create or select a song to get started',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Active Song Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
                            ),
                            child: Row(
                              children: [
                                // Menu trigger for collapsed drawer
                                if (!showSidebar) ...[
                                  Builder(
                                    builder: (context) => IconButton(
                                      icon: const Icon(Icons.menu, color: Colors.white),
                                      onPressed: () => Scaffold.of(context).openDrawer(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // Editable Title Input
                                Expanded(
                                  child: TextField(
                                    controller: _titleController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
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
                                // Key selector dropdown
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
                                // Time Signature selector
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
                          // Core Panels (Row on desktop, scrollable Column on smaller windows)
                          Expanded(
                            child: stackPanels
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const ChordProgressionEditor(),
                                        const SizedBox(height: 16),
                                        // Fixed-height lyric editor wrapper when stacked
                                        const SizedBox(
                                          height: 400,
                                          child: LyricEditor(),
                                        ),
                                        const SizedBox(height: 16),
                                        // Fixed-height tabs panel wrapper when stacked
                                        SizedBox(
                                          height: 480,
                                          child: _buildTabsPanel(),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: [
                                      // Left side: Chords + Lyric Editor
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
                                      // Right side: Tabs (Metronome / Inspiration / Roadmap)
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                                          child: _buildTabsPanel(),
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildTabsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: [
          // Tab bar headers
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
          // Tab views
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
}
