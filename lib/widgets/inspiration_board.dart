import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../utils/synth_engine.dart';

class InspirationBoard extends StatefulWidget {
  const InspirationBoard({super.key});

  @override
  State<InspirationBoard> createState() => _InspirationBoardState();
}

class _InspirationBoardState extends State<InspirationBoard> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String _selectedType = 'link';

  // Audio Playback & Simulated Transports state
  AudioPlayer? _audioPlayer;
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Timer? _mockPlaybackTimer;
  Timer? _synthJamTimer;
  int _synthBeatIndex = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _commentController.dispose();
    _audioPlayer?.dispose();
    _mockPlaybackTimer?.cancel();
    _synthJamTimer?.cancel();
    super.dispose();
  }

  bool _isDirectAudioLink(String url) {
    final clean = url.toLowerCase().trim();
    return clean.endsWith('.mp3') ||
        clean.endsWith('.wav') ||
        clean.endsWith('.m4a') ||
        clean.endsWith('.ogg') ||
        clean.contains('.mp3?') ||
        clean.contains('.wav?');
  }

  String? _getYoutubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _togglePlay(InspirationItem item, Song activeSong) {
    if (_currentlyPlayingId == item.id) {
      if (_isPlaying) {
        _pauseCurrent();
      } else {
        _resumeCurrent(item, activeSong);
      }
    } else {
      _startPlay(item, activeSong);
    }
  }

  void _pauseCurrent() {
    _audioPlayer?.pause();
    _mockPlaybackTimer?.cancel();
    _synthJamTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resumeCurrent(InspirationItem item, Song activeSong) {
    if (_isDirectAudioLink(item.content)) {
      _audioPlayer?.resume();
    } else {
      _startSynthJam(item, activeSong);
    }
    setState(() {
      _isPlaying = true;
    });
  }

  void _startPlay(InspirationItem item, Song activeSong) {
    _audioPlayer?.stop();
    _mockPlaybackTimer?.cancel();
    _synthJamTimer?.cancel();

    setState(() {
      _currentlyPlayingId = item.id;
      _isPlaying = true;
      _position = Duration.zero;
      _duration = const Duration(seconds: 30); // Default duration for synth loop
    });

    if (_isDirectAudioLink(item.content)) {
      try {
        _audioPlayer?.play(UrlSource(item.content));
      } catch (e) {
        debugPrint("Error playing audio URL: $e");
      }
    } else {
      _startSynthJam(item, activeSong);
    }
  }

  void _startSynthJam(InspirationItem item, Song activeSong) {
    _mockPlaybackTimer?.cancel();
    _synthJamTimer?.cancel();

    // 1. Progress simulation
    _mockPlaybackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        final newMs = _position.inMilliseconds + 100;
        if (newMs >= _duration.inMilliseconds) {
          _position = _duration;
          _pauseCurrent();
        } else {
          _position = Duration(milliseconds: newMs);
        }
      });
    });

    // 2. Synth loop synchronized with song's BPM and Key!
    final bpm = activeSong.bpm;
    final beatIntervalMs = (60.0 / bpm * 1000).round();
    _synthBeatIndex = 0;

    final List<String> chords;
    if (activeSong.keySignature.contains('Min') || activeSong.keySignature.contains('m')) {
      chords = ['Am', 'Dm', 'Em', 'Am'];
    } else {
      chords = ['C', 'G', 'Am', 'F'];
    }

    _synthJamTimer = Timer.periodic(Duration(milliseconds: beatIntervalMs ~/ 2), (timer) {
      if (!mounted) return;

      final step = _synthBeatIndex % 8;

      // Rhythm backing track
      if (step == 0 || step == 4) {
        SynthEngine.playDrum('kick');
      } else if (step == 2 || step == 6) {
        SynthEngine.playDrum('snare');
      } else {
        SynthEngine.playDrum('hat');
      }

      // Chord backing track in current key
      if (step == 0) {
        final chord = chords[0];
        SynthEngine.playChord(chord);
      } else if (step == 4) {
        final chord = chords[2];
        SynthEngine.playChord(chord);
      }

      _synthBeatIndex++;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildCardThumbnail(InspirationItem item) {
    final String url = item.content;
    final bool isImage = item.type == 'image';
    final String? ytId = _getYoutubeId(url);
    final bool isSpotify = url.toLowerCase().contains('spotify.com');
    final bool isSoundCloud = url.toLowerCase().contains('soundcloud.com');

    if (isImage) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(item, 'Image Error'),
      );
    } else if (ytId != null) {
      return Image.network(
        'https://img.youtube.com/vi/$ytId/hqdefault.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(item, 'YouTube Video'),
      );
    } else if (isSpotify) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1DB954), Color(0xFF191414)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.white, size: 32),
              SizedBox(height: 6),
              Text(
                'SPOTIFY REFERENCE',
                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
        ),
      );
    } else if (isSoundCloud) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF5500), Color(0xFF13131A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud, color: Colors.white, size: 32),
              SizedBox(height: 6),
              Text(
                'SOUNDCLOUD Reference',
                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
        ),
      );
    } else {
      return _buildFallbackThumbnail(item, 'Audio Link');
    }
  }

  Widget _buildFallbackThumbnail(InspirationItem item, String label) {
    final int hash = item.id.hashCode;
    final List<Color> colors = _getGradientColors(hash);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, color: Colors.white, size: 32),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(int hash) {
    final List<List<Color>> palettes = [
      [const Color(0xFF6B11FF), const Color(0xFF00FFCC)],
      [const Color(0xFFFF2A54), const Color(0xFFFFBE00)],
      [const Color(0xFF0D47A1), const Color(0xFF00E5FF)],
      [const Color(0xFF8E24AA), const Color(0xFFFF4081)],
      [const Color(0xFF1B5E20), const Color(0xFFB9F6CA)],
    ];
    return palettes[hash.abs() % palettes.length];
  }

  void _showAddItemDialog(BuildContext context, SongProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add Inspiration Card',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Link/Track'),
                            selected: _selectedType == 'link',
                            selectedColor: const Color(0xFF00E5FF),
                            labelStyle: TextStyle(
                              color: _selectedType == 'link' ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setDialogState(() => _selectedType = 'link');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Image URL'),
                            selected: _selectedType == 'image',
                            selectedColor: const Color(0xFF00E5FF),
                            labelStyle: TextStyle(
                              color: _selectedType == 'image' ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setDialogState(() => _selectedType = 'image');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Title (e.g. Reference Track)',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: _selectedType == 'link'
                            ? 'YouTube / Spotify / Direct Audio Link'
                            : 'Unsplash Image Link',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    final content = _contentController.text.trim();
                    if (title.isNotEmpty && content.isNotEmpty) {
                      provider.addInspirationItem(title, _selectedType, content);
                      _titleController.clear();
                      _contentController.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommentsDialog(BuildContext context, SongProvider provider, InspirationItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Discussion: ${item.title}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                height: 350,
                child: Column(
                  children: [
                    Expanded(
                      child: item.comments.isEmpty
                          ? const Center(
                              child: Text(
                                'No comments yet. Start the conversation!',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              itemCount: item.comments.length,
                              itemBuilder: (context, index) {
                                final comment = item.comments[index];
                                final timeStr = DateFormat('hh:mm a').format(comment.timestamp);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF252535),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            comment.author,
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.text,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Add team comment...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                          onPressed: () {
                            final commentText = _commentController.text.trim();
                            if (commentText.isNotEmpty) {
                              provider.addInspirationComment(item.id, 'Artist (Me)', commentText);
                              _commentController.clear();
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final song = provider.activeSong;

    if (song == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 8),
                  const Text(
                    'Inspiration Board',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
                  foregroundColor: const Color(0xFF00E5FF),
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAddItemDialog(context, provider),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: song.inspirationItems.isEmpty
                ? const Center(
                    child: Text(
                      'No inspiration cards added. Build an references grid for tracks/moodboards.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: song.inspirationItems.length,
                    itemBuilder: (context, index) {
                      final item = song.inspirationItems[index];
                      final isPlayingThis = _currentlyPlayingId == item.id && _isPlaying;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Visual Preview Area with Play transport overlay
                            Expanded(
                              flex: 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: _buildCardThumbnail(item),
                                  ),
                                  // Hover/Play Overlay
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      onTap: () => _togglePlay(item, song),
                                      child: Container(
                                        color: isPlayingThis ? Colors.black.withOpacity(0.4) : Colors.black12,
                                        child: isPlayingThis
                                            ? const EqualizerBars()
                                            : const Center(
                                                child: CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: Colors.black54,
                                                  child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  // Progress Bar
                                  if (isPlayingThis)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: LinearProgressIndicator(
                                        value: _duration.inMilliseconds > 0
                                            ? _position.inMilliseconds / _duration.inMilliseconds
                                            : 0.0,
                                        backgroundColor: Colors.white10,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                                        minHeight: 3,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Footer Details
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isPlayingThis)
                                          Text(
                                            '${_formatDuration(_position)}/${_formatDuration(_duration)}',
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () => _showCommentsDialog(context, provider, item),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.comment, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${item.comments.length}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: Icon(
                                                isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                                size: 16,
                                                color: const Color(0xFF00E5FF),
                                              ),
                                              onPressed: () => _togglePlay(item, song),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                provider.deleteInspirationItem(item.id);
                                              },
                                              child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                            ),
                                          ],
                                        ),
                                      ],
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
          ),
        ],
      ),
    );
  }
}

class EqualizerBars extends StatefulWidget {
  const EqualizerBars({super.key});

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [10.0, 18.0, 12.0, 24.0, 8.0];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final randomFactor = _random.nextDouble() * 0.4 + 0.6;
              final height = _baseHeights[index] * (0.3 + 0.7 * sin(_controller.value * 2 * pi + index)) * randomFactor;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3.5,
                height: height.clamp(4.0, 24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
