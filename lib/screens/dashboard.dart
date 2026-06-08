import 'dart:math';
import 'dart:ui' as ui;
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
import '../utils/synth_engine.dart';
import 'landing_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _activeSongId;

  // Active navigation view: 'capture', 'library', 'collab', 'vault', 'workspace'
  String _activeView = 'library';
  String _selectedContactName = 'Aria North';
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _mockMessages = [
    {
      'contact': 'Aria North',
      'sender': 'Aria North',
      'text': 'Hey! Did you have a chance to look at the chorus vocals for Glass House?',
      'time': '10:24 AM',
    },
    {
      'contact': 'Aria North',
      'sender': 'me',
      'text': 'Yes! Sounds incredible. I added some subtle tape saturation and a light stereo delay.',
      'time': '10:28 AM',
    },
    {
      'contact': 'Aria North',
      'sender': 'Aria North',
      'text': 'Ooh that sounds warm. Can we bounce a draft mix? I want to test it in my car.',
      'time': '10:30 AM',
    },
    {
      'contact': 'kai.wav',
      'sender': 'kai.wav',
      'text': 'Lofi drum stems are ready. Bpm is 78.',
      'time': 'Yesterday',
    },
    {
      'contact': 'Chloe Keys',
      'sender': 'Chloe Keys',
      'text': 'Sure, I can lay down the Rhodes chords tonight.',
      'time': '2 days ago',
    },
  ];
  String _vaultSearchQuery = '';
  String _selectedGenre = 'Synthwave';
  String _selectedCountry = 'Global';

  // Sidebar collapsible state variables
  bool _playgroundExpanded = true;
  bool _industryExpanded = true;
  bool _moreExpanded = false;
  bool _userExpanded = false;

  // DAW State Variables
  String _dawViewMode = 'mixer'; // 'track' or 'mixer'
  bool _dawPlaying = false;
  bool _dawLooping = false;
  bool _dawRecording = false;
  int _dawBars = 1;
  int _dawBeats = 1;
  int _dawTicks = 0;

  final List<Map<String, dynamic>> _dawTracks = [
    {
      'name': 'Vocal Mic In',
      'type': 'Audio',
      'color': const Color(0xFF4D8DFF),
      'icon': Icons.mic,
    },
    {
      'name': 'Chords Synth',
      'type': 'Instrument',
      'color': const Color(0xFFD03BFF),
      'icon': Icons.keyboard,
    },
    {
      'name': 'Backing Drums',
      'type': 'Audio',
      'color': const Color(0xFF00FFCC),
      'icon': Icons.audiotrack,
    },
    {
      'name': 'Synth Bass',
      'type': 'MIDI',
      'color': const Color(0xFFFFD700),
      'icon': Icons.music_note,
    },
  ];

  late List<double> _dawVolumes;
  late List<double> _dawPans;
  late List<bool> _dawMutes;
  late List<bool> _dawSolos;
  late List<bool> _dawRecordArms;
  late List<bool> _dawMonitors;
  late List<Map<String, bool>> _dawEffectsBypasses;

  double _masterVolume = 0.8;
  double _bottomPanelHeight = 240.0;
  bool _bottomPanelCollapsed = false;
  String _bottomPanelTab =
      'piano_roll'; // 'piano_roll', 'plugin_editor', 'automation', 'ai_assistant'
  int _selectedTrackIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize DAW track parameters
    _dawVolumes = List.filled(_dawTracks.length, 0.7);
    _dawPans = List.filled(_dawTracks.length, 0.0); // -1.0 to 1.0 (L to R)
    _dawMutes = List.filled(_dawTracks.length, false);
    _dawSolos = List.filled(_dawTracks.length, false);
    _dawRecordArms = List.filled(_dawTracks.length, false);
    _dawMonitors = List.filled(_dawTracks.length, false);
    _dawEffectsBypasses = List.generate(
      _dawTracks.length,
      (_) => {'EQ': false, 'Comp': false, 'Reverb': true, 'Delay': true},
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _searchController.dispose();
    _messageController.dispose();
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

  Widget _buildSidebar(
    SongProvider provider,
    List<Song> songs,
    Song? activeSong, {
    bool isDrawer = false,
  }) {
    return Container(
      width: 260,
      color: const Color(0xFF13131A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo Header (Clicking routes user back to Landing Page)
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LandingPageScreen(),
                ),
              );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.03)),
                  ),
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
                          child: const Icon(
                            Icons.blur_on,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Studduo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD03BFF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFD03BFF).withOpacity(0.4),
                              width: 0.8,
                            ),
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
                      'AI Powered Workstation for Music Artists',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Sidebar Nav Items to prevent vertical overflow
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. PLAYGROUND
                  _buildSidebarHeader(
                    icon: Icons.palette_outlined,
                    label: 'Playground',
                    isExpanded: _playgroundExpanded,
                    onTap: () => setState(
                      () => _playgroundExpanded = !_playgroundExpanded,
                    ),
                  ),
                  if (_playgroundExpanded) ...[
                    _buildSidebarNavItem(
                      icon: Icons.mic_none,
                      label: 'Capture',
                      isSelected: _activeView == 'capture',
                      badgeCount: provider.inbox.length,
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'capture');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.library_music_outlined,
                      label: 'Song Library',
                      isSelected: _activeView == 'library',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'library');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.archive_outlined,
                      label: 'Vault',
                      isSelected: _activeView == 'vault',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'vault');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                  ],

                  const SizedBox(height: 8),

                  // 2. MIXER CONSOLE
                  _buildSidebarNavItem(
                    icon: Icons.tune,
                    label: 'Mixer Console',
                    isSelected: _activeView == 'mixer',
                    onTap: () {
                      setState(() => _activeView = 'mixer');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                  // 3. PROJECTS
                  _buildSidebarNavItem(
                    icon: Icons.folder_open,
                    label: 'Projects',
                    isSelected: _activeView == 'projects',
                    onTap: () {
                      setState(() => _activeView = 'projects');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                  // 4. NETWORK (Collaborators)
                  _buildSidebarNavItem(
                    icon: Icons.people_outline,
                    label: 'Network',
                    isSelected: _activeView == 'collab',
                    onTap: () {
                      setState(() => _activeView = 'collab');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                  _buildSidebarNavItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    isSelected: _activeView == 'messages',
                    badgeCount: 3,
                    onTap: () {
                      setState(() => _activeView = 'messages');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                  _buildSidebarNavItem(
                    icon: Icons.group_outlined,
                    label: 'Team Members',
                    isSelected: _activeView == 'team',
                    onTap: () {
                      setState(() => _activeView = 'team');
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                  const SizedBox(height: 8),

                  // 5. INDUSTRY
                  _buildSidebarHeader(
                    icon: Icons.business_center_outlined,
                    label: 'Industry',
                    isExpanded: _industryExpanded,
                    onTap: () =>
                        setState(() => _industryExpanded = !_industryExpanded),
                  ),
                  if (_industryExpanded) ...[
                    _buildSidebarNavItem(
                      icon: Icons.newspaper_outlined,
                      label: 'News',
                      isSelected: _activeView == 'news',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'news');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Charts',
                      isSelected: _activeView == 'charts',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'charts');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                  ],

                  const SizedBox(height: 8),

                  // 6. MORE
                  _buildSidebarHeader(
                    icon: Icons.more_horiz_outlined,
                    label: 'More',
                    isExpanded: _moreExpanded,
                    onTap: () => setState(() => _moreExpanded = !_moreExpanded),
                  ),
                  if (_moreExpanded) ...[
                    _buildSidebarNavItem(
                      icon: Icons.info_outline,
                      label: 'Company',
                      isSelected: _activeView == 'company',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'company');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.notifications_none,
                      label: 'Updates',
                      isSelected: false,
                      indent: 12,
                      onTap: () {
                        if (isDrawer) Navigator.of(context).pop();
                        _showUpdatesDialog(context);
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.check_circle_outline,
                      label: 'Status',
                      isSelected: _activeView == 'status',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'status');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.gavel,
                      label: 'Legals',
                      isSelected: _activeView == 'legals',
                      indent: 12,
                      onTap: () {
                        setState(() => _activeView = 'legals');
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // 7. USER (positioned at the bottom left)
          _buildSidebarHeader(
            icon: Icons.person_outline,
            label: 'User',
            isExpanded: _userExpanded,
            onTap: () => setState(() => _userExpanded = !_userExpanded),
          ),
          if (_userExpanded) ...[
            _buildSidebarNavItem(
              icon: Icons.account_box_outlined,
              label: 'Account',
              isSelected: _activeView == 'account',
              indent: 12,
              onTap: () {
                setState(() => _activeView = 'account');
                if (isDrawer) Navigator.of(context).pop();
              },
            ),
            _buildSidebarNavItem(
              icon: Icons.person_pin_outlined,
              label: 'Profile',
              isSelected: _activeView == 'profile',
              indent: 12,
              onTap: () {
                setState(() => _activeView = 'profile');
                if (isDrawer) Navigator.of(context).pop();
              },
            ),
            _buildSidebarNavItem(
              icon: Icons.settings_outlined,
              label: 'Preferences',
              isSelected: _activeView == 'preferences',
              indent: 12,
              onTap: () {
                setState(() => _activeView = 'preferences');
                if (isDrawer) Navigator.of(context).pop();
              },
            ),
            _buildSidebarNavItem(
              icon: Icons.logout,
              label: 'Logout',
              isSelected: false,
              indent: 12,
              onTap: () {
                if (isDrawer) Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LandingPageScreen(),
                  ),
                );
              },
            ),
          ],
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
    double indent = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 12 + indent, right: 12, top: 3, bottom: 3),
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
                  color: isSelected
                      ? const Color(0xFF00FFCC)
                      : Colors.grey[400],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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

  Widget _buildSidebarHeader({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.white.withOpacity(0.35)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 14,
                color: Colors.white.withOpacity(0.35),
              ),
            ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Changelog - v0.01',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '🎉 Welcome to Studduo!',
                style: TextStyle(
                  color: Color(0xFF00FFCC),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
              child: const Text(
                'Great',
                style: TextStyle(color: Color(0xFF00FFCC)),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'MuseDeck Workspace Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text(
                  'Audio Preferences',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.grey),
                title: const Text(
                  'Backup Workspace Data',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text(
                  'Interactive Guide',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
    SongProvider provider,
    Song? activeSong,
    bool showSidebar,
  ) {
    if (_activeView == 'workspace') {
      if (activeSong == null) {
        if (provider.songs.isNotEmpty) {
          // Select first song if none is active
          provider.selectSong(provider.songs.first);
          return _buildWorkspaceView(
            provider,
            provider.songs.first,
            showSidebar,
          );
        }
        return const Center(
          child: Text(
            'Create or select a song to open workspace',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return _buildWorkspaceView(provider, activeSong, showSidebar);
    } else if (_activeView == 'mixer') {
      return _buildEmptyMixerView();
    } else if (_activeView == 'capture') {
      return _buildCaptureInboxView(provider);
    } else if (_activeView == 'collab') {
      return _buildCollaborationsView(provider);
    } else if (_activeView == 'vault') {
      return _buildTheVaultView(provider);
    } else if (_activeView == 'news') {
      return _buildIndustryNewsView();
    } else if (_activeView == 'charts') {
      return _buildChartsView();
    } else if (_activeView == 'projects') {
      return _buildProjectsView(provider);
    } else if (_activeView == 'company') {
      return _buildCompanyView();
    } else if (_activeView == 'status') {
      return _buildStatusView();
    } else if (_activeView == 'legals') {
      return _buildLegalsView();
    } else if (_activeView == 'messages') {
      return _buildDMsMessagesView();
    } else if (_activeView == 'team') {
      return _buildTeamMembersView();
    } else if (_activeView == 'account') {
      return _buildAccountView();
    } else if (_activeView == 'profile') {
      return _buildProfileView();
    } else if (_activeView == 'preferences') {
      return _buildPreferencesView();
    } else {
      return _buildSongLibraryView(provider);
    }
  }

  // View: Capture Inbox (Inbox)
  Widget _buildCaptureInboxView(SongProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '🎙️ Capture Inbox',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
                    const SnackBar(
                      content: Text('Captured audio memo to inbox!'),
                      backgroundColor: Color(0xFFD03BFF),
                    ),
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
                    const SnackBar(
                      content: Text('Captured photo scan reference!'),
                      backgroundColor: Color(0xFFFFD700),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Unorganized Inbox Ideas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.inbox.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Inbox is clean! All ideas sorted.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'UNORGANIZED',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00FFCC,
                        ).withOpacity(0.15),
                        foregroundColor: const Color(0xFF00FFCC),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () =>
                          _showSortCaptureDialog(context, provider, item),
                      icon: const Icon(Icons.sort, size: 14),
                      label: const Text(
                        'Sort / Workspace',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () => provider.deleteCaptureItem(item.id),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
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
          title: const Text(
            'Quick Note Capture',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Write thoughts...',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFCC),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && noteCtrl.text.isNotEmpty) {
                  provider.addCaptureItem(
                    titleCtrl.text,
                    'text',
                    noteCtrl.text,
                  );
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

  void _showSortCaptureDialog(
    BuildContext context,
    SongProvider provider,
    CaptureItem item,
  ) {
    final titleCtrl = TextEditingController(text: item.title);
    SongGroupType selectedGroup = SongGroupType.single;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text(
                'Sort to Song Workspace',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'New Song Title',
                        labelStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Group Into:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
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
                        if (val != null)
                          setDialogState(() => selectedGroup = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFCC),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    provider.convertCaptureToSong(
                      item.id,
                      titleCtrl.text,
                      selectedGroup,
                    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int columns = 3;
        double aspectRatio = 1.05;

        if (width < 650) {
          columns = 2;
          aspectRatio = 0.85; // Consistently keep grid view even on mobile
        } else if (width < 1000) {
          columns = 2;
          aspectRatio = 1.15;
        }

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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFCC),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      provider.createNewSong(
                        title: 'New Workspace #${songs.length + 1}',
                      );
                      setState(() => _activeView = 'workspace');
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'New Song Workspace',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: songs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No active songs in library.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a new song workspace above to get started.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              return _buildSongCard(provider, songs[index]);
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildFooterSection(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSongThumbnail(Song song) {
    for (final item in song.inspirationItems) {
      if (item.type == 'image') {
        return item.content;
      }
    }
    final List<String> fallbackCovers = [
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819', // Concert lights
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4', // Vintage mic
      'https://images.unsplash.com/photo-1507838153414-b4b713384a76', // Turntable / headphones
      'https://images.unsplash.com/photo-1518609878373-06d740f60d8b', // Recording room
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745', // DJ neon console
    ];
    final hash = song.id.hashCode.abs();
    return fallbackCovers[hash % fallbackCovers.length];
  }

  Widget _buildSongCard(SongProvider provider, Song song) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.archive_outlined,
                            color: Colors.grey,
                            size: 16,
                          ),
                          onPressed: () {
                            provider.archiveSong(song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Archived "${song.title}" to The Vault!',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${song.bpm} BPM • ${song.keySignature} • ${song.timeSignature}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          songStatusToString(song.status),
                          style: TextStyle(
                            color: _getStatusColor(song.status),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildProgressNodes(song.status),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Image.network(
                    _getSongThumbnail(song),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: const Color(0xFF252535),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibrarySection(
    SongProvider provider,
    List<Song> allSongs,
    SongGroupType type,
    String sectionTitle,
    int columns,
    double aspectRatio,
  ) {
    final filtered = allSongs.where((s) => s.groupType == type).toList();
    if (filtered.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              color: Color(0xFF00FFCC),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildSongCard(provider, filtered[index]);
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
                        : (isCompleted
                              ? const Color(0xFFD03BFF)
                              : Colors.white10),
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
    final songs = provider.songs
        .where((s) => s.collaborators.isNotEmpty && !s.isArchived)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '👥 Collaborations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track files, split sheets, and shared sessions.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (songs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No active collaboration workspaces.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'BPM: ${song.bpm} • Key: ${song.keySignature} • Time: ${song.timeSignature}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00FFCC,
                            ).withOpacity(0.15),
                            foregroundColor: const Color(0xFF00FFCC),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            provider.selectSong(song);
                            setState(() => _activeView = 'workspace');
                          },
                          icon: const Icon(Icons.exit_to_app, size: 14),
                          label: const Text(
                            'Open Workspace',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    const Text(
                      'Collaborators & Split shares',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          song.collaborators.map((c) {
                            final int splitShare =
                                (100 / (song.collaborators.length + 1)).round();
                            return Chip(
                              backgroundColor: const Color(0xFF1E1E2E),
                              side: BorderSide.none,
                              label: Text(
                                '$c ($splitShare%)',
                                style: const TextStyle(
                                  color: Color(0xFF00FFCC),
                                  fontSize: 11,
                                ),
                              ),
                              avatar: CircleAvatar(
                                backgroundColor: const Color(0xFFD03BFF),
                                child: Text(
                                  c[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList()..add(
                            Chip(
                              backgroundColor: const Color(0xFF1E1E2E),
                              side: BorderSide.none,
                              label: Text(
                                'Me (${(100 / (song.collaborators.length + 1) + (100 % (song.collaborators.length + 1))).round()}%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              avatar: const CircleAvatar(
                                backgroundColor: Color(0xFF00FFCC),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 10,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  // View: The Vault (Archived ideas)
  Widget _buildTheVaultView(SongProvider provider) {
    final songs = provider.songs
        .where(
          (s) =>
              s.isArchived &&
              s.title.toLowerCase().contains(_vaultSearchQuery.toLowerCase()),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '🗃️ The Vault (Archived Ideas)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fully searchable repository for old drafts or discarded riffs.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
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
        if (songs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No archived ideas match search.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final lastModStr = DateFormat(
                'MMMM dd, yyyy',
              ).format(song.lastModified);
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _getSongThumbnail(song),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFF252535),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Archived: $lastModStr • ${song.bpm} BPM',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFD03BFF,
                            ).withOpacity(0.15),
                            foregroundColor: const Color(0xFFD03BFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            provider.restoreSong(song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Restored "${song.title}" to active library!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.unarchive, size: 14),
                          label: const Text(
                            'Restore',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () {
                            provider.deleteSong(song.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Permanently deleted "${song.title}"',
                                ),
                              ),
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
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  // View: Song Workspace Panel (Edit song contents - Chords, Lyrics, metronome etc.)
  Widget _buildWorkspaceView(
    SongProvider provider,
    Song activeSong,
    bool showSidebar,
  ) {
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
              items: [
                'C Maj',
                'G Maj',
                'D Maj',
                'A Maj',
                'E Maj',
                'F Maj',
                'A Min',
                'E Min',
                'D Min',
                'B Min',
              ],
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
                  const SizedBox(height: 400, child: LyricEditor()),
                  const SizedBox(height: 16),
                  SizedBox(height: 480, child: _buildTabsPanel()),
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
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E1E2E),
              value: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              items: items.map((val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
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
          drawer: !showSidebar
              ? Drawer(
                  child: _buildSidebar(
                    provider,
                    songs,
                    activeSong,
                    isDrawer: true,
                  ),
                )
              : null,
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
                        title: const Text(
                          'MuseDeck',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    Expanded(
                      child: _buildMainContent(
                        provider,
                        activeSong,
                        showSidebar,
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

  Widget _buildIndustryNewsView() {
    final newsList = [
      {
        'title': 'Synth Design is Reaching a New Golden Age',
        'source': 'Pitchfork',
        'time': '2 hours ago',
        'desc':
            'How bedroom producers and modular synthesis enthusiasts are driving the hardware design revival. We look at the latest semi-modular releases from Moog and Behringer.',
        'image': 'https://images.unsplash.com/photo-1598653222000-6b7b7a552625',
      },
      {
        'title': 'Billboard Hot 100: Synthwave and Retro Beats Take Over',
        'source': 'Billboard',
        'time': '5 hours ago',
        'desc':
            'Analysis of this week\'s charts shows a massive surge in analog-sounding basslines and heavy 80s gated reverb snare drums in mainstream pop.',
        'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
      },
      {
        'title': 'The Rise of AI Collaborations in Modern Songwriting',
        'source': 'Sound on Sound',
        'time': '1 day ago',
        'desc':
            'A look at how tools like MuseDeck are allowing songwriters to brainstorm chord progression templates and sync draft memos collaboratively.',
        'image': 'https://images.unsplash.com/photo-1507838153414-b4b713384a76',
      },
      {
        'title': 'How Live Streaming Changed Indie Concert Touring Forever',
        'source': 'NME',
        'time': '3 days ago',
        'desc':
            'Even as physical venues return to full capacity, hybrid digital tickets and live stream archives are generating up to 40% of total tour revenues for independent artists.',
        'image': 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '📰 Industry News',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Stay updated with snippets from Billboard, Pitchfork, and other media sources.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(news['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD03BFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            news['source']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                news['desc']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            news['time']!,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildChartsView() {
    final Map<String, List<Map<String, dynamic>>> genreCharts = {
      'Synthwave': [
        {
          'rank': 1,
          'change': 'new',
          'title': 'Resonance Shift',
          'artist': 'Laserhawk',
          'bpm': 112,
          'key': 'A Min',
        },
        {
          'rank': 2,
          'change': '+1',
          'title': 'Glow Rider',
          'artist': 'Kavinsky',
          'bpm': 118,
          'key': 'D Min',
        },
        {
          'rank': 3,
          'change': '-1',
          'title': 'Turbo Drive',
          'artist': 'FM-84',
          'bpm': 120,
          'key': 'C Maj',
        },
        {
          'rank': 4,
          'change': '+3',
          'title': 'Outrun Sunset',
          'artist': 'The Midnight',
          'bpm': 105,
          'key': 'G Maj',
        },
      ],
      'Pop': [
        {
          'rank': 1,
          'change': '=',
          'title': 'Neon Hearts',
          'artist': 'Dua Lipa',
          'bpm': 122,
          'key': 'C Maj',
        },
        {
          'rank': 2,
          'change': 'new',
          'title': 'Midnight Dance',
          'artist': 'The Weeknd',
          'bpm': 120,
          'key': 'A Min',
        },
        {
          'rank': 3,
          'change': '+2',
          'title': 'Rainy Day',
          'artist': 'Taylor Swift',
          'bpm': 98,
          'key': 'F Maj',
        },
        {
          'rank': 4,
          'change': '-1',
          'title': 'Golden Summer',
          'artist': 'Harry Styles',
          'bpm': 115,
          'key': 'D Min',
        },
      ],
      'Techno': [
        {
          'rank': 1,
          'change': '+2',
          'title': 'Acid Pulse',
          'artist': 'Charlotte de Witte',
          'bpm': 135,
          'key': 'E Min',
        },
        {
          'rank': 2,
          'change': '-1',
          'title': 'Industrial Noise',
          'artist': 'Amelie Lens',
          'bpm': 138,
          'key': 'A Min',
        },
        {
          'rank': 3,
          'change': 'new',
          'title': 'Dark Space',
          'artist': 'Carl Cox',
          'bpm': 130,
          'key': 'D Min',
        },
        {
          'rank': 4,
          'change': '=',
          'title': 'Modulation Loop',
          'artist': 'Enrico Sangiuliano',
          'bpm': 132,
          'key': 'C Maj',
        },
      ],
    };

    final chartsList = genreCharts[_selectedGenre] ?? genreCharts['Synthwave']!;

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 Music Charts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weekly charts for $_selectedGenre • $_selectedCountry',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            Row(
              children: [
                _buildFilterDropdown(
                  value: _selectedGenre,
                  items: ['Synthwave', 'Pop', 'Techno'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGenre = val);
                  },
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _selectedCountry,
                  items: ['Global', 'US', 'UK', 'Japan'],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCountry = val);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chartsList.length,
          itemBuilder: (context, index) {
            final track = chartsList[index];
            final rank = track['rank'] as int;
            final change = track['change'] as String;
            final bpm = track['bpm'] as int;
            final key = track['key'] as String;

            Color changeColor = Colors.grey;
            IconData changeIcon = Icons.remove;
            if (change == 'new') {
              changeColor = const Color(0xFFD03BFF);
              changeIcon = Icons.fiber_new;
            } else if (change.startsWith('+')) {
              changeColor = const Color(0xFF00FFCC);
              changeIcon = Icons.arrow_drop_up;
            } else if (change.startsWith('-')) {
              changeColor = Colors.redAccent;
              changeIcon = Icons.arrow_drop_down;
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
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(changeIcon, color: changeColor, size: 16),
                      if (change != '=' && change != 'new')
                        Text(
                          change.substring(1),
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00FFCC).withOpacity(0.4),
                          const Color(0xFFD03BFF).withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${track['artist']} • $bpm BPM • Key: $key',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF00FFCC,
                      ).withOpacity(0.15),
                      foregroundColor: const Color(0xFF00FFCC),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      final List<String> chords;
                      if (key.contains('Min') || key.contains('m')) {
                        chords = ['Am', 'F', 'Dm', 'E'];
                      } else {
                        chords = ['C', 'G', 'Am', 'F'];
                      }
                      SynthEngine.playChord(chords[0]);
                      SynthEngine.playDrum('kick');
                      Future.delayed(const Duration(milliseconds: 300), () {
                        SynthEngine.playDrum('hat');
                      });
                      Future.delayed(const Duration(milliseconds: 600), () {
                        SynthEngine.playDrum('snare');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Previewing vibe of "${track['title']}" in $key ($bpm BPM)',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.audiotrack, size: 14),
                    label: const Text(
                      'Vibe Check',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF1E1E2E),
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: items.map((val) {
            return DropdownMenuItem<String>(value: val, child: Text(val));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- FOOTER SECTION ---
  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF040406),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isMobile = constraints.maxWidth < 800;
                  return Column(
                    children: [
                      if (isMobile) ...[
                        _buildFooterAbout(),
                        const SizedBox(height: 40),
                        _buildFooterLinks(),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildFooterAbout()),
                            const Spacer(),
                            Expanded(flex: 6, child: _buildFooterLinks()),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const Divider(height: 60, color: Colors.white10),
              // Bottom bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 Studduo. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF13131A),
                    value: 'English',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Row(
                          children: [
                            Icon(Icons.language, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'English',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterAbout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD03BFF), Color(0xFF00FFCC)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.waves, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Studduo',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'AI Powered Workstation for Music Artists',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSocialIcon(Icons.camera_alt),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.chat_bubble_outline),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.play_circle_outline),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.hub_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
      ),
      child: Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
    );
  }

  Widget _buildFooterLinks() {
    Widget buildCol(String title, List<String> links) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...links.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                link,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCol('Company', ['About Us', 'Contact Us', 'Operational Status']),
        buildCol('Resources', [
          'Help Center',
          'Pricing',
          'Blog',
          'Community',
          'Download Android',
          'Download iOS',
          'Download Huawei',
        ]),
        buildCol('Legal', [
          'Terms and Conditions',
          'Privacy Policy',
          'Cookie Policy',
        ]),
      ],
    );
  }

  // --- PROJECTS (ASSET MANAGEMENT) VIEW ---
  Widget _buildProjectsView(SongProvider provider) {
    final songs = provider.songs.where((s) => !s.isArchived).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int columns = 3;
        double aspectRatio = 1.05;

        if (width < 650) {
          columns = 2;
          aspectRatio = 0.85;
        } else if (width < 1000) {
          columns = 2;
          aspectRatio = 1.15;
        }

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              '📂 Projects & Assets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your multi-track stems, master files, samples, and exports.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Storage Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cloud Storage Space',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '4.2 GB of 10.0 GB (42%)',
                        style: TextStyle(
                          color: Color(0xFF00FFCC),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.42,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: const Color(0xFF00FFCC),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Folders Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                _buildProjectFolderCard(
                  Icons.audiotrack,
                  'Stems & Multi-tracks',
                  '14 files',
                  const Color(0xFFD03BFF),
                ),
                _buildProjectFolderCard(
                  Icons.album,
                  'Mixdowns & Masters',
                  '8 files',
                  const Color(0xFF00FFCC),
                ),
                _buildProjectFolderCard(
                  Icons.library_music,
                  'Samples & Loops',
                  '32 files',
                  const Color(0xFFFFD700),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Multi-track Files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...provider.songs
                .take(3)
                .map(
                  (song) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13131A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.white.withOpacity(0.5),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${song.title} - Mixdown.wav',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Last modified: 1 day ago • 38.4 MB',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.download_outlined,
                            color: Color(0xFF00FFCC),
                            size: 18,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Downloading stem package for "${song.title}"...',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 32),
            const Text(
              '📁 Projects & Categorization',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLibrarySection(
              provider,
              songs,
              SongGroupType.single,
              '💿 Singles',
              columns,
              aspectRatio,
            ),
            _buildLibrarySection(
              provider,
              songs,
              SongGroupType.ep,
              '📼 EPs',
              columns,
              aspectRatio,
            ),
            _buildLibrarySection(
              provider,
              songs,
              SongGroupType.album,
              '🎸 Albums',
              columns,
              aspectRatio,
            ),
            _buildLibrarySection(
              provider,
              songs,
              SongGroupType.liveSet,
              '🎤 Live Sets',
              columns,
              aspectRatio,
            ),
            const SizedBox(height: 40),
            _buildFooterSection(),
          ],
        );
      },
    );
  }

  Widget _buildProjectFolderCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPANY VIEW ---
  Widget _buildCompanyView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '🏢 About Studduo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Brewing every idea at your pace. Go deep, not just fast.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Our Philosophy',
                style: TextStyle(
                  color: Color(0xFF00FFCC),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Studduo was born from the belief that great music needs space. Not just a physical studio, but a mental space free from stressors, algorithms, and deadlines. '
                'We design toolkits that capture transient thoughts seamlessly, allowing you to nurse them into full compositions over time.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              const Text(
                'Built by Artists, for Artists',
                style: TextStyle(
                  color: Color(0xFFD03BFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our team consists of acoustic engineers, software developers, synth designers, and touring musicians working collectively to bridge the gap between creative spark and finished master. '
                'Thank you for joining our community. Enjoy the quiet creative playground.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  // --- STATUS VIEW ---
  Widget _buildStatusView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '🟢 Operational Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Real-time health statistics for Studduo core sub-systems.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _buildStatusNodeCard(
              'Synthesizer Engine',
              'Operational',
              '12ms latency',
              const Color(0xFF00FFCC),
            ),
            _buildStatusNodeCard(
              'Backing Track Generator',
              'Operational',
              '85ms latency',
              const Color(0xFF00FFCC),
            ),
            _buildStatusNodeCard(
              'Real-time Cloud Sync',
              'Operational',
              '45ms latency',
              const Color(0xFF00FFCC),
            ),
            _buildStatusNodeCard(
              'Audio Recording Pipeline',
              'Operational',
              '2ms latency',
              const Color(0xFF00FFCC),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildStatusNodeCard(
    String title,
    String status,
    String metric,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  metric,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LEGALS VIEW ---
  Widget _buildLegalsView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '⚖️ Legals & Agreement',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Read our terms of service, privacy policy, and licensing agreements.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  color: Color(0xFF00FFCC),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By using Studduo, you retain full copyright ownership of all melodies, lyrics, synthesizer presets, and rhythm arrangements generated using the platform. '
                'We do not claim ownership, royalties, or licensing cuts from any work exported or finished using our toolkits.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFFD03BFF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We collect local sketch files and telemetry data solely to run synthesizer synthesis pipelines, synchronise backups, and diagnostic testing. '
                'Your files are never shared with third parties or used to train general generative audio AI models without your explicit consent.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  // --- ACCOUNT VIEW ---
  Widget _buildAccountView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '💳 Account Subscription',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage your billing, subscription tier, and receipts.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Tier',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pro Producer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00FFCC).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF00FFCC),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              _buildAccountInfoRow('Billing Cycle', 'Monthly'),
              _buildAccountInfoRow('Pricing Plan', '\$9.99 / month'),
              _buildAccountInfoRow('Next Invoice', 'July 06, 2026'),
              _buildAccountInfoRow('Payment Method', 'Visa ending in 4022'),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFCC),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redirecting to Stripe Billing Portal...'),
                    ),
                  );
                },
                child: const Text(
                  'Manage Billing Portal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildAccountInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- PROFILE VIEW ---
  Widget _buildProfileView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '👤 Artist Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Personalize how other collaborators see your credit details.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD03BFF), Color(0xFF00FFCC)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'HS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HotSnow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Indie Synthwave Producer',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              _buildProfileField('Username', 'HotSnow'),
              _buildProfileField('Contact Email', 'hotsnow@example.com'),
              _buildProfileField('Country', 'Norway'),
              _buildProfileField('Primary Genre', 'Synthwave / Outrun'),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD03BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile changes saved successfully!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Update Profile Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: value),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E1E2E).withOpacity(0.5),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD03BFF)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PREFERENCES VIEW ---
  Widget _buildPreferencesView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          '⚙️ Workstation Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Adjust sample buffer rates, default metronome ticks, and AI assistance modules.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audio Settings',
                style: TextStyle(
                  color: Color(0xFF00FFCC),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceDropdown('Sample Rate', '48,000 Hz', [
                '44,100 Hz',
                '48,000 Hz',
                '96,000 Hz',
              ]),
              _buildPreferenceDropdown('Buffer Size', '256 samples', [
                '64 samples',
                '128 samples',
                '256 samples',
                '512 samples',
              ]),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              const Text(
                'Workstation Metronome',
                style: TextStyle(
                  color: Color(0xFFD03BFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceDropdown('Click Sound', 'Woodblock', [
                'Beep',
                'Woodblock',
                'Rimshot',
                'Hi-hat',
              ]),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable AI Co-Pilot Suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Auto-generate matching chord paths as you type lyrics',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  Switch(
                    value: true,
                    activeColor: const Color(0xFF00FFCC),
                    onChanged: (val) {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildFooterSection(),
      ],
    );
  }

  Widget _buildPreferenceDropdown(
    String label,
    String value,
    List<String> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E1E2E),
                value: value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: items
                    .map(
                      (val) => DropdownMenuItem<String>(
                        value: val,
                        child: Text(val),
                      ),
                    )
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CLOUD-NATIVE AI DAW WORKSPACE ---
  Widget _buildEmptyMixerView() {
    final activeSong = Provider.of<SongProvider>(context).activeSong;
    final songTitle = activeSong?.title ?? 'Summer Lights';
    final songBpm = activeSong?.bpm ?? 128;
    final songKey = activeSong?.keySignature ?? 'G Min';
    final songTime = activeSong?.timeSignature ?? '4/4';

    // DAW visual theme colors
    const Color colorBg = Color(0xFF111318);
    const Color colorPanel = Color(0xFF1A1E25);
    const Color colorSecondaryPanel = Color(0xFF222833);
    const Color colorGrid = Color(0xFF2F3542);
    const Color colorAccent = Color(0xFF4D8DFF);
    const Color colorRecord = Color(0xFFFF4D5A);
    const Color colorWaveform = Color(0xFF62B6FF);

    return Container(
      color: colorBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP NAVIGATION BAR (56px height)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: colorPanel,
              border: Border(bottom: BorderSide(color: colorGrid, width: 1)),
            ),
            child: Row(
              children: [
                // Project Details
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Norway Mix',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorAccent.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'v0.01',
                            style: TextStyle(
                              color: colorAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.cloud_done_outlined,
                          color: Colors.greenAccent.withOpacity(0.5),
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Musical Metadata Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorSecondaryPanel,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorGrid, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      _buildMetadataUnit('BPM', '$songBpm'),
                      _buildMetadataSeparator(),
                      _buildMetadataUnit('KEY', songKey),
                      _buildMetadataSeparator(),
                      _buildMetadataUnit('SIGN', songTime),
                      _buildMetadataSeparator(),
                      _buildMetadataUnit('MODE', 'TEMPO'),
                    ],
                  ),
                ),
                const Spacer(),
                // Project Actions & User
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.undo,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                      onPressed: () {},
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.redo,
                        color: Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                      onPressed: () {},
                      tooltip: 'Redo',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Saving project automatically to cloud sync...',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TRANSPORT BAR (48px height)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: colorSecondaryPanel,
              border: Border(bottom: BorderSide(color: colorGrid, width: 1)),
            ),
            child: Row(
              children: [
                // Transport Buttons
                Row(
                  children: [
                    _buildTransportButton(
                      icon: Icons.skip_previous,
                      onPressed: () => setState(() {
                        _dawBars = 1;
                        _dawBeats = 1;
                        _dawTicks = 0;
                      }),
                      tooltip: 'Return to Start',
                    ),
                    _buildTransportButton(
                      icon: Icons.stop,
                      isSelected: !_dawPlaying && !_dawRecording,
                      onPressed: () => setState(() {
                        _dawPlaying = false;
                        _dawRecording = false;
                      }),
                      tooltip: 'Stop',
                    ),
                    _buildTransportButton(
                      icon: _dawPlaying ? Icons.pause : Icons.play_arrow,
                      isSelected: _dawPlaying,
                      color: const Color(0xFF3DDC84),
                      onPressed: () => setState(() {
                        _dawPlaying = !_dawPlaying;
                        if (_dawPlaying) _dawRecording = false;
                      }),
                      tooltip: 'Play/Pause',
                    ),
                    _buildTransportButton(
                      icon: Icons.fiber_manual_record,
                      isSelected: _dawRecording,
                      color: colorRecord,
                      onPressed: () => setState(() {
                        _dawRecording = !_dawRecording;
                        if (_dawRecording) _dawPlaying = true;
                      }),
                      tooltip: 'Record',
                    ),
                    _buildTransportButton(
                      icon: Icons.loop,
                      isSelected: _dawLooping,
                      onPressed: () =>
                          setState(() => _dawLooping = !_dawLooping),
                      tooltip: 'Loop Region',
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Position Counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorGrid, width: 1),
                  ),
                  child: Text(
                    '${_dawBars.toString().padLeft(3, '0')} . ${_dawBeats.toString().padLeft(2, '0')} . ${_dawTicks.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF3DDC84),
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Performance indicators
                Row(
                  children: [
                    _buildPerformanceMetric('CPU', '14%'),
                    _buildPerformanceMetric('BUFFER', '256 smpl'),
                    _buildPerformanceMetric('LATENCY', '12 ms'),
                    _buildPerformanceMetric('AUDIO', '48 kHz'),
                  ],
                ),
              ],
            ),
          ),

          // 3. WORKSPACE BODY (ARRANGEMENT OR MIXER)
          Expanded(
            child: Column(
              children: [
                // Mode Switcher Header
                Container(
                  color: colorBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // View switcher Segmented Control
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorPanel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorGrid, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            _buildSwitcherSegment(
                              'track',
                              'Arrangement Timeline',
                              Icons.linear_scale,
                            ),
                            _buildSwitcherSegment(
                              'mixer',
                              'Mixer Console',
                              Icons.tune,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Metronome & Settings
                      IconButton(
                        icon: Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                        onPressed: () {},
                        tooltip: 'Metronome sound',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                        onPressed: () {},
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ),
                // Main Workspace Switcher
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _dawViewMode == 'track'
                        ? _buildDawArrangementTimeline()
                        : _buildDawMixerConsole(),
                  ),
                ),
              ],
            ),
          ),

          // 4. BOTTOM PANEL EDITOR
          Container(
            height: _bottomPanelCollapsed ? 32 : _bottomPanelHeight,
            decoration: const BoxDecoration(
              color: colorPanel,
              border: Border(top: BorderSide(color: colorGrid, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bottom panel tab headers & collapse trigger
                Container(
                  height: 32,
                  color: colorSecondaryPanel,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _bottomPanelCollapsed
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 14,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(
                          () => _bottomPanelCollapsed = !_bottomPanelCollapsed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildBottomPanelTab('piano_roll', '🎹 Piano Roll'),
                      _buildBottomPanelTab(
                        'plugin_editor',
                        '🔌 FX Plugin Editor',
                      ),
                      _buildBottomPanelTab(
                        'automation',
                        '📈 Automation Curves',
                      ),
                      _buildBottomPanelTab('ai_assistant', '✨ AI Co-Pilot'),
                      const Spacer(),
                      if (!_bottomPanelCollapsed)
                        GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _bottomPanelHeight =
                                  (details.globalPosition.dy - 500).clamp(
                                    160,
                                    450,
                                  );
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeUpDown,
                            child: Container(
                              width: 50,
                              color: colorGrid.withOpacity(0.5),
                              child: const Icon(
                                Icons.drag_handle,
                                size: 12,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Expanded tab contents
                if (!_bottomPanelCollapsed)
                  Expanded(
                    child: Container(
                      color: colorBg,
                      child: _buildBottomPanelContent(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP BAR SUB WIDGETS ---
  Widget _buildMetadataUnit(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF4D8DFF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSeparator() {
    return Container(
      width: 1,
      height: 18,
      color: const Color(0xFF2F3542),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // --- TRANSPORT BAR SUB WIDGETS ---
  Widget _buildTransportButton({
    required IconData icon,
    bool isSelected = false,
    Color? color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final activeColor = color ?? const Color(0xFF4D8DFF);
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.white.withOpacity(0.6),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- WORKSPACE VIEW SWITCHER ---
  Widget _buildSwitcherSegment(String mode, String label, IconData icon) {
    final bool isSelected = _dawViewMode == mode;
    return Material(
      color: isSelected ? const Color(0xFF222833) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => setState(() => _dawViewMode = mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF4D8DFF) : Colors.grey[400],
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TRACK ARRANGEMENT VIEW ---
  Widget _buildDawArrangementTimeline() {
    const Color colorGrid = Color(0xFF2F3542);
    const Color colorArrangementBg = Color(0xFF13151A);

    return Row(
      children: [
        // A. Left side track list header
        SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header spacer matching ruler
              Container(
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1E25),
                  border: Border(
                    bottom: BorderSide(color: colorGrid),
                    right: BorderSide(color: colorGrid),
                  ),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  'Track List',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Track headers
              Expanded(
                child: Container(
                  color: const Color(0xFF1A1E25),
                  child: ListView.builder(
                    itemCount: _dawTracks.length,
                    itemBuilder: (context, index) {
                      final track = _dawTracks[index];
                      final isSelected = _selectedTrackIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTrackIndex = index),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF222833)
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(color: colorGrid, width: 0.8),
                              right: BorderSide(color: colorGrid, width: 1.5),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Track colored accent block
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: track['color'] as Color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    track['icon'] as IconData,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      track['name'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _buildTrackControlToggle(
                                        'M',
                                        _dawMutes[index],
                                        () {
                                          setState(
                                            () => _dawMutes[index] =
                                                !_dawMutes[index],
                                          );
                                        },
                                      ),
                                      _buildTrackControlToggle(
                                        'S',
                                        _dawSolos[index],
                                        () {
                                          setState(
                                            () => _dawSolos[index] =
                                                !_dawSolos[index],
                                          );
                                        },
                                      ),
                                      _buildTrackControlToggle(
                                        'R',
                                        _dawRecordArms[index],
                                        () {
                                          setState(
                                            () => _dawRecordArms[index] =
                                                !_dawRecordArms[index],
                                          );
                                        },
                                        color: const Color(0xFFFF4D5A),
                                      ),
                                      _buildTrackControlToggle(
                                        'I',
                                        _dawMonitors[index],
                                        () {
                                          setState(
                                            () => _dawMonitors[index] =
                                                !_dawMonitors[index],
                                          );
                                        },
                                        color: const Color(0xFF4D8DFF),
                                      ),
                                    ],
                                  ),
                                  // Tiny meter indicator
                                  Container(
                                    width: 50,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: _dawMutes[index] ? 0 : 35,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3DDC84),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // B. Right side arrangement grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, gridConstraints) {
              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ruler header
                      Container(
                        height: 28,
                        color: const Color(0xFF1A1E25),
                        child: CustomPaint(
                          painter: TimelineRulerPainter(colorGrid),
                        ),
                      ),
                      // Grid items
                      Expanded(
                        child: Container(
                          color: colorArrangementBg,
                          child: Stack(
                            children: [
                              // Horizontal grid backgrounds
                              ListView.builder(
                                itemCount: _dawTracks.length,
                                itemBuilder: (context, index) {
                                  final track = _dawTracks[index];
                                  return Container(
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colorGrid,
                                          width: 0.6,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Stack(
                                      children: [
                                        // Grid Background divisions lines
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: GridVerticalLinePainter(
                                              colorGrid,
                                            ),
                                          ),
                                        ),
                                        // Mock Clips
                                        if (index == 0)
                                          _buildArrangementClip(
                                            startBar: 2,
                                            endBar: 14,
                                            color: track['color'] as Color,
                                            isAudio: true,
                                            label: 'Lead Vocals Norway.wav',
                                          ),
                                        if (index == 1)
                                          _buildArrangementClip(
                                            startBar: 1,
                                            endBar: 16,
                                            color: track['color'] as Color,
                                            isAudio: false,
                                            label: 'Synthesizer Chord Pattern',
                                          ),
                                        if (index == 2)
                                          _buildArrangementClip(
                                            startBar: 4,
                                            endBar: 15,
                                            color: track['color'] as Color,
                                            isAudio: true,
                                            label:
                                                'BPM Backing Groove_Full.wav',
                                          ),
                                        if (index == 3)
                                          _buildArrangementClip(
                                            startBar: 5,
                                            endBar: 13,
                                            color: track['color'] as Color,
                                            isAudio: false,
                                            label: 'Bass Synth Line MIDI',
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Vertical playhead line
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 160, // Mock current playhead position
                                child: Container(
                                  width: 2,
                                  color: Colors.redAccent,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        top: 0,
                                        left: -4,
                                        child: Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.redAccent,
                                          size: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackControlToggle(
    String label,
    bool value,
    VoidCallback onTap, {
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFFE2E212);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.black45,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: value ? Colors.black : Colors.grey[400],
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildArrangementClip({
    required int startBar,
    required int endBar,
    required Color color,
    required bool isAudio,
    required String label,
  }) {
    double unitWidth = 45.0; // horizontal grid scale size per bar
    double leftOffset = startBar * unitWidth;
    double clipWidth = (endBar - startBar) * unitWidth;

    return Positioned(
      left: leftOffset,
      width: clipWidth,
      top: 2,
      bottom: 2,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Stack(
          children: [
            // Waveform mock visualizer
            if (isAudio)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: CustomPaint(painter: AudioClipWavePainter(color)),
                ),
              ),
            // MIDI mock note strips
            if (!isAudio)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: CustomPaint(painter: MidiClipNotesPainter(color)),
                ),
              ),
            // Clip title label
            Positioned(
              top: 4,
              left: 8,
              child: Text(
                label,
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
    );
  }

  // --- MIXER CONSOLE VIEW ---
  Widget _buildDawMixerConsole() {
    const Color colorGrid = Color(0xFF2F3542);
    return Row(
      children: [
        // Side-by-side horizontal channel strips
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dawTracks.length,
            itemBuilder: (context, index) {
              final track = _dawTracks[index];
              return Container(
                width: 110,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1E25),
                  border: Border(right: BorderSide(color: colorGrid, width: 1)),
                ),
                child: Column(
                  children: [
                    // Top Color bar
                    Container(height: 4, color: track['color'] as Color),
                    const SizedBox(height: 8),
                    // Track Title & Icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            track['icon'] as IconData,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              track['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Input select box
                    Container(
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        track['type'] == 'Audio' ? 'Mic In 1' : 'Inst Synth 1',
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Inserts FX rack
                    const Text(
                      'INSERTS',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildEffectsInsertSlot(index, 'EQ'),
                    _buildEffectsInsertSlot(index, 'Comp'),
                    _buildEffectsInsertSlot(index, 'Reverb'),
                    _buildEffectsInsertSlot(index, 'Delay'),
                    const SizedBox(height: 12),
                    // Sends Section
                    const Text(
                      'SENDS',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSendDial('A', 0.25),
                        _buildSendDial('B', 0.60),
                        _buildSendDial('C', 0.10),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Pan Control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'C',
                          style: TextStyle(color: Colors.grey, fontSize: 8),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: Transform.rotate(
                            angle: _dawPans[index] * 1.5,
                            child: const Center(
                              child: Divider(
                                color: Color(0xFF4D8DFF),
                                endIndent: 10,
                                thickness: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Volume Fader & Metering Row
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Vertical volume fader
                          RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: const Color(0xFF4D8DFF),
                                inactiveTrackColor: Colors.black26,
                                thumbColor: Colors.grey[350],
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                              ),
                              child: Slider(
                                value: _dawVolumes[index],
                                onChanged: (val) =>
                                    setState(() => _dawVolumes[index] = val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Track Meter indicator
                          Container(
                            width: 6,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: _dawMutes[index]
                                  ? 0
                                  : (_dawVolumes[index] * 110),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.green,
                                    Colors.yellow,
                                    Colors.red,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fader db text
                    Text(
                      _dawMutes[index]
                          ? '-inf dB'
                          : '${((_dawVolumes[index] - 0.7) * 20).toStringAsFixed(1)} dB',
                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                    ),
                    const SizedBox(height: 12),
                    // Controls (Mute / Solo / Record Arm)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTrackControlToggle('M', _dawMutes[index], () {
                          setState(() => _dawMutes[index] = !_dawMutes[index]);
                        }),
                        _buildTrackControlToggle('S', _dawSolos[index], () {
                          setState(() => _dawSolos[index] = !_dawSolos[index]);
                        }),
                        _buildTrackControlToggle(
                          'R',
                          _dawRecordArms[index],
                          () {
                            setState(
                              () => _dawRecordArms[index] =
                                  !_dawRecordArms[index],
                            );
                          },
                          color: const Color(0xFFFF4D5A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
        // Master Output Channel strip (Pinned far right)
        Container(
          width: 120,
          decoration: const BoxDecoration(
            color: Color(0xFF111318),
            border: Border(left: BorderSide(color: colorGrid, width: 2)),
          ),
          child: Column(
            children: [
              Container(height: 4, color: const Color(0xFFFF4D5A)),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.waves, size: 12, color: Color(0xFFFF4D5A)),
                  SizedBox(width: 4),
                  Text(
                    'MASTER OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Pinned input mode
              Container(
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Stereo Master',
                  style: TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ),
              const SizedBox(height: 12),
              // Master FX inserts
              const Text(
                'MASTER FX',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildMasterFxSlot('Bus Compressor', true),
              _buildMasterFxSlot('EQ Master', true),
              _buildMasterFxSlot('Tape Saturation', false),
              _buildMasterFxSlot('Limiter Max', true),
              const SizedBox(height: 20),
              // Stereo Outputs meter & master fader
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Fader slider
                    RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: const Color(0xFFFF4D5A),
                          inactiveTrackColor: Colors.black26,
                          thumbColor: Colors.grey[300],
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                        ),
                        child: Slider(
                          value: _masterVolume,
                          onChanged: (val) =>
                              setState(() => _masterVolume = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Large Stereo Level Indicator
                    Row(
                      children: [
                        _buildMasterOutputMeterLevel(_masterVolume),
                        const SizedBox(width: 2),
                        _buildMasterOutputMeterLevel(_masterVolume),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${((_masterVolume - 0.8) * 20).toStringAsFixed(1)} dB',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Master solo & mute safe toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTrackControlToggle(
                    'C',
                    false,
                    () {},
                    color: Colors.blueAccent,
                  ),
                  _buildTrackControlToggle(
                    'L',
                    true,
                    () {},
                    color: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsInsertSlot(int trackIdx, String fxName) {
    final bool bypass = _dawEffectsBypasses[trackIdx][fxName] ?? true;
    return GestureDetector(
      onTap: () {
        setState(() {
          _dawEffectsBypasses[trackIdx][fxName] = !bypass;
        });
      },
      child: Container(
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: bypass ? Colors.black38 : const Color(0xFF2E3E2F),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: bypass
                ? Colors.white10
                : const Color(0xFF3DDC84).withOpacity(0.3),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          fxName,
          style: TextStyle(
            color: bypass
                ? Colors.white.withOpacity(0.35)
                : const Color(0xFF3DDC84),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMasterFxSlot(String name, bool active) {
    return Container(
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF382329) : Colors.black38,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active
              ? const Color(0xFFFF4D5A).withOpacity(0.3)
              : Colors.white10,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: TextStyle(
          color: active ? const Color(0xFFFF4D5A) : Colors.white24,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSendDial(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8)),
        const SizedBox(height: 2),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Transform.rotate(
            angle: value * 3.14,
            child: const Center(
              child: Divider(
                color: Colors.white30,
                endIndent: 8,
                thickness: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterOutputMeterLevel(double volume) {
    return Container(
      width: 6,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: _dawPlaying ? (volume * 135) : 0,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.yellow, Colors.red],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // --- BOTTOM PANEL TAB SWITCHER ---
  Widget _buildBottomPanelTab(String tab, String label) {
    final bool isSelected = _bottomPanelTab == tab;
    return GestureDetector(
      onTap: () => setState(() {
        _bottomPanelTab = tab;
        _bottomPanelCollapsed = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111318) : Colors.transparent,
          border: Border(right: const BorderSide(color: Color(0xFF2F3542))),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4D8DFF) : Colors.grey[400],
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- TAB CONTENT BUILDERS ---
  Widget _buildBottomPanelContent() {
    if (_bottomPanelTab == 'piano_roll') {
      return _buildPianoRollEditor();
    } else if (_bottomPanelTab == 'plugin_editor') {
      return _buildPluginEditorView();
    } else if (_bottomPanelTab == 'automation') {
      return _buildAutomationEditorView();
    } else {
      return _buildAiAssistantPanelView();
    }
  }

  Widget _buildPianoRollEditor() {
    const Color colorGrid = Color(0xFF2F3542);
    // Render basic DAW Piano roll keyboard keys and midi note grid blocks
    return Row(
      children: [
        // Keyboard Keys
        Container(
          width: 50,
          color: const Color(0xFF1E1E25),
          child: ListView.builder(
            itemCount: 16,
            reverse: true,
            itemBuilder: (context, index) {
              final isBlackKey = [1, 3, 6, 8, 10, 13, 15].contains(index % 12);
              return Container(
                height: 20,
                decoration: BoxDecoration(
                  color: isBlackKey ? Colors.black87 : Colors.white,
                  border: const Border(
                    bottom: BorderSide(color: Colors.black26),
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  isBlackKey ? '' : 'C${(index / 12).floor() + 3}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        // Midi grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: ListView.builder(
                itemCount: 16,
                reverse: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, keyIdx) {
                  return Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colorGrid, width: 0.5),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Grid lines vertical
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridVerticalLinePainter(colorGrid),
                          ),
                        ),
                        // Mock MIDI notes
                        if (keyIdx == 4)
                          _buildMidiNoteBox(2, 6, const Color(0xFFD03BFF)),
                        if (keyIdx == 7)
                          _buildMidiNoteBox(4, 9, const Color(0xFFD03BFF)),
                        if (keyIdx == 11)
                          _buildMidiNoteBox(8, 12, const Color(0xFF00FFCC)),
                        if (keyIdx == 2)
                          _buildMidiNoteBox(11, 15, const Color(0xFF00FFCC)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMidiNoteBox(int startCol, int endCol, Color color) {
    double barSize = 45.0; // matching ruler subdivisions
    return Positioned(
      left: startCol * barSize,
      width: (endCol - startCol) * barSize,
      top: 2,
      bottom: 2,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildPluginEditorView() {
    // Render a high-fidelity visual parametric EQ graph interface
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // EQ Parametric Graph Canvas
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2F3542)),
              ),
              child: CustomPaint(painter: ParametricEqPainter()),
            ),
          ),
          const SizedBox(width: 16),
          // Control parameters dials
          Expanded(
            flex: 4,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildPluginParamDial('LOW CUT', '24 Hz', 0.1),
                _buildPluginParamDial('MID GAIN', '+1.2 dB', 0.55),
                _buildPluginParamDial('HIGH SHLF', '8.4 kHz', 0.75),
                _buildPluginParamDial('Q FACTOR', '0.70', 0.35),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginParamDial(String title, String val, double pct) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2F3542)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4D8DFF), width: 2),
            ),
            transform: Matrix4.rotationZ(pct * 3.14),
            child: const Center(
              child: VerticalDivider(color: Colors.white70, thickness: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationEditorView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Automation lane:',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Track 1 - Volume Fader',
                  style: TextStyle(
                    color: Color(0xFF4D8DFF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2F3542)),
              ),
              child: CustomPaint(painter: AutomationCurvePainter()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantPanelView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ AI Co-Pilot Assistant Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cloud-Native intelligent workflows inside Studduo.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 900 ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
              children: [
                _buildAiWorkflowCard(
                  Icons.auto_awesome,
                  'Generate Chords',
                  'Builds premium harmonic progressions',
                ),
                _buildAiWorkflowCard(
                  Icons.graphic_eq,
                  'Mix Assistant',
                  'Balances relative track volumes & pans',
                ),
                _buildAiWorkflowCard(
                  Icons.analytics_outlined,
                  'Stem Separator',
                  'Extracts vocals & backing stems',
                ),
                _buildAiWorkflowCard(
                  Icons.star_border,
                  'Mastering Guide',
                  'Applies dynamic curves & EQ limits',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiWorkflowCard(IconData icon, String title, String desc) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4D8DFF).withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Starting AI processor workflow for: "$title"...',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF4D8DFF), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDMsMessagesView() {
    final activeMessages = _mockMessages.where((msg) => msg['contact'] == _selectedContactName).toList();
    final List<String> contacts = ['Aria North', 'kai.wav', 'Chloe Keys', 'DJ Spark', 'Luna Eclipse', 'Zoe Synth'];

    return Row(
      children: [
        // Left Column - Contacts List
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF13131A),
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'DMs & Messages',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = contact == _selectedContactName;
                    
                    // Find last message snippet
                    final lastMsg = _mockMessages.lastWhere(
                      (msg) => msg['contact'] == contact,
                      orElse: () => {'text': 'Click to start conversation...', 'time': ''},
                    );

                    return InkWell(
                      onTap: () => setState(() => _selectedContactName = contact),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: isSelected ? const Color(0xFF6C3BF5).withOpacity(0.15) : Colors.transparent,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF6C3BF5),
                              child: Text(contact[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        contact,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        lastMsg['time'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 9),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMsg['text'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF00FFCC) : Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Right Column - Active Chat Thread
        Expanded(
          child: Container(
            color: const Color(0xFF0D0D14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header of active contact
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF00FFCC),
                        child: Text(_selectedContactName[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedContactName,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: Color(0xFF00FFCC), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text('Online & in workspace', style: TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Messages thread
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: activeMessages.length,
                    itemBuilder: (context, index) {
                      final msg = activeMessages[index];
                      final isMe = msg['sender'] == 'me';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: const BoxConstraints(maxWidth: 450),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF6C3BF5) : const Color(0xFF1E1E28),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.02)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  msg['time'] ?? '',
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Typing Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.music_note, color: Color(0xFFD03BFF), size: 20),
                        tooltip: 'Share track draft',
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey, size: 20),
                        tooltip: 'Attach stems/samples',
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Write a response...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isEmpty) return;
                              setState(() {
                                _mockMessages.add({
                                  'contact': _selectedContactName,
                                  'sender': 'me',
                                  'text': val,
                                  'time': 'Just now',
                                });
                                _messageController.clear();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6C3BF5),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 16),
                          onPressed: () {
                            final val = _messageController.text;
                            if (val.trim().isEmpty) return;
                            setState(() {
                              _mockMessages.add({
                                'contact': _selectedContactName,
                                'sender': 'me',
                                'text': val,
                                'time': 'Just now',
                              });
                              _messageController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMembersView() {
    final List<Map<String, dynamic>> team = [
      {
        'name': 'Aria North',
        'role': 'Lead Vocalist & Songwriter',
        'avatar': 'A',
        'status': 'In melody session 🎧',
        'online': true,
        'projects': 'Glass House, Bloom',
      },
      {
        'name': 'kai.wav',
        'role': 'Beatmaker & Co-Producer',
        'avatar': 'K',
        'status': 'Arranging drums 🥁',
        'online': true,
        'projects': 'Rainy Sundays, Chilled Waves',
      },
      {
        'name': 'Chloe Keys',
        'role': 'Pianist & String Arranger',
        'avatar': 'C',
        'status': 'Recording acoustic grand',
        'online': true,
        'projects': 'Ambient Keys',
      },
      {
        'name': 'DJ Spark',
        'role': 'Mixing & Audio Engineer',
        'avatar': 'S',
        'status': 'Away',
        'online': false,
        'projects': 'Tech House Build',
      },
      {
        'name': 'Bax Beatbox',
        'role': 'Sound Designer / Vocal Effects',
        'avatar': 'B',
        'status': 'Modulating layers',
        'online': true,
        'projects': 'Voice Percussion v1',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👥 Team Workspace',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Collaborators and roles on your active song projects.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3BF5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invitation link copied to clipboard!')),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Invite Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 800;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 1 : 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: isMobile ? 2.0 : 1.35,
              ),
              itemCount: team.length,
              itemBuilder: (context, index) {
                final member = team[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: member['online'] ? const Color(0xFF00FFCC).withOpacity(0.15) : Colors.white10,
                            child: Text(member['avatar'], style: TextStyle(color: member['online'] ? const Color(0xFF00FFCC) : Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member['role'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shared tracks: ${member['projects']}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: member['online'] ? const Color(0xFF00FFCC) : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    member['status'],
                                    style: const TextStyle(color: Colors.grey, fontSize: 10.5, fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
        ),
      ],
    );
  }
}

// --- CUSTOM PAINTERS FOR TIMELINE & AUDIO/MIDI GRAPHICS ---

class TimelineRulerPainter extends CustomPainter {
  final Color gridColor;
  TimelineRulerPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    double barSize = 45.0; // Bar grid horizontal spacing
    int totalBars = (size.width / barSize).ceil();

    for (int i = 0; i < totalBars; i++) {
      double x = i * barSize;
      // draw major line
      canvas.drawLine(
        Offset(x, size.height - 12),
        Offset(x, size.height),
        paint,
      );
      // text bar number
      final textSpan = TextSpan(
        text: '${i + 1}',
        style: const TextStyle(color: Colors.grey, fontSize: 8),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 4, 4));

      // minor beats ticks
      for (int b = 1; b < 4; b++) {
        double bx = x + (b * barSize / 4);
        canvas.drawLine(
          Offset(bx, size.height - 6),
          Offset(bx, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridVerticalLinePainter extends CustomPainter {
  final Color gridColor;
  GridVerticalLinePainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withOpacity(0.4)
      ..strokeWidth = 0.5;

    double barSize = 45.0;
    int totalBars = (size.width / barSize).ceil();

    for (int i = 0; i < totalBars; i++) {
      double x = i * barSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AudioClipWavePainter extends CustomPainter {
  final Color waveColor;
  AudioClipWavePainter(this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor.withOpacity(0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    double midY = size.height / 2;
    path.moveTo(0, midY);

    for (double x = 0; x < size.width; x += 4) {
      double sample = sin(x * 0.1) * cos(x * 0.02) * (size.height * 0.4);
      path.lineTo(x, midY + sample);
      path.moveTo(x, midY - sample);
      path.lineTo(x, midY + sample);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MidiClipNotesPainter extends CustomPainter {
  final Color noteColor;
  MidiClipNotesPainter(this.noteColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = noteColor.withOpacity(0.45)
      ..style = PaintingStyle.fill;

    // Draw little grid blocks representing MIDI notes in a clip
    canvas.drawRect(Rect.fromLTWH(10, 8, 30, 4), paint);
    canvas.drawRect(Rect.fromLTWH(50, 16, 20, 4), paint);
    canvas.drawRect(Rect.fromLTWH(80, 12, 40, 4), paint);
    canvas.drawRect(Rect.fromLTWH(130, 24, 25, 4), paint);
    canvas.drawRect(Rect.fromLTWH(160, 16, 30, 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParametricEqPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2F3542).withOpacity(0.3)
      ..strokeWidth = 0.5;

    // Draw vertical and horizontal grid lines
    for (double x = 50; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 20; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // EQ Curve
    final curvePaint = Paint()
      ..color = const Color(0xFF4D8DFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final curvePath = Path();
    double midY = size.height / 2;
    curvePath.moveTo(0, midY);

    for (double x = 0; x < size.width; x++) {
      // Create a curve with a low cut, a peak mid filter boost, and high shelf roll off
      double y = midY;
      // Low cut roll off
      if (x < 60) {
        y += (60 - x) * 0.8;
      }
      // Mid peak boost
      double midPos = size.width * 0.45;
      double dist = (x - midPos).abs();
      if (dist < 80) {
        y -= (80 - dist) * 0.35 * sin((80 - dist) * 3.14 / 160);
      }
      // High shelf boost
      if (x > size.width * 0.75) {
        y -= (x - size.width * 0.75) * 0.15;
      }
      curvePath.lineTo(x, y.clamp(0, size.height));
    }
    canvas.drawPath(curvePath, curvePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AutomationCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    // Nodes
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.35, size.height * 0.25),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width, size.height * 0.1),
    ];

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    for (var pt in points) {
      canvas.drawCircle(pt, 4.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
