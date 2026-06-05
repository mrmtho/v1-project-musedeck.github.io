import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../utils/synth_engine.dart';

class ChordProgressionEditor extends StatefulWidget {
  const ChordProgressionEditor({super.key});

  @override
  State<ChordProgressionEditor> createState() => _ChordProgressionEditorState();
}

class _ChordProgressionEditorState extends State<ChordProgressionEditor> {
  String? _selectedChordCategory = 'Major';
  int? _hoveredIndex;
  int? _playingIndex;

  final Map<String, List<String>> _chordBank = {
    'Major': ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'],
    'Minor': ['Cm', 'Dbm', 'Dm', 'Ebm', 'Em', 'Fm', 'F#m', 'Gm', 'Abm', 'Am', 'Bbm', 'Bm'],
    '7th': ['C7', 'D7', 'E7', 'F7', 'G7', 'A7', 'B7', 'Cmaj7', 'Dmaj7', 'Fmaj7', 'Gmaj7', 'Amin7'],
    'Suspended': ['Csus4', 'Dsus4', 'Esus4', 'Gsus4', 'Asus4', 'Csus2', 'Dsus2', 'Asus2'],
    'Half Dim': ['Cm7b5', 'Dm7b5', 'Em7b5', 'F#m7b5', 'Gm7b5', 'Am7b5', 'Bm7b5'],
    'Diminished': ['Cdim', 'Ddim', 'Edim', 'Fdim', 'Gdim', 'Adim', 'Bdim', 'Cdim7', 'Ddim7', 'Adim7'],
  };

  Color _getChordColor(String chordName) {
    final clean = chordName.trim();
    if (clean.isEmpty) return const Color(0xFFF5B342);

    // Extract suffix by removing root note (e.g., C, C#, Db)
    String suffix = clean;
    if (clean.length >= 2 && (clean[1] == '#' || clean[1] == 'b')) {
      suffix = clean.substring(2);
    } else if (clean.isNotEmpty) {
      suffix = clean.substring(1);
    }

    final lowerSuffix = suffix.toLowerCase();

    // 1. Half Diminished (#4221b5)
    if (lowerSuffix.contains('m7b5') || lowerSuffix.contains('ø') || lowerSuffix.contains('half')) {
      return const Color(0xFF4221B5);
    }

    // 2. Diminished (#17084a)
    if (lowerSuffix.contains('dim') || lowerSuffix.contains('°')) {
      return const Color(0xFF17084A);
    }

    // 3. Dominants (#364d08)
    // Includes: dom7, dom9, dom11, dom13, suspended chords, 6/9 chords
    if (lowerSuffix.contains('sus') || lowerSuffix.contains('6/9')) {
      return const Color(0xFF364D08);
    }

    final hasDominantNumber = RegExp(r'(7|9|11|13)').hasMatch(lowerSuffix);
    final isMajorVariant = suffix.contains('maj') || suffix.contains('Maj') || suffix.contains('M');
    final isMinorVariant = suffix.contains('min') || suffix.contains('Min') || 
        (suffix.contains('m') && !suffix.contains('maj') && !suffix.contains('Maj') && !suffix.contains('M'));

    if (hasDominantNumber && !isMajorVariant && !isMinorVariant) {
      return const Color(0xFF364D08);
    }

    // 4. Minor (#5340de)
    if (isMinorVariant) {
      return const Color(0xFF5340DE);
    }

    // 5. Major (#f5b342)
    return const Color(0xFFF5B342);
  }

  void _playChord(int index, String chordName) {
    setState(() {
      _playingIndex = index;
    });
    SynthEngine.playChord(chordName);
    // Visual play effect duration
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _playingIndex == index) {
        setState(() {
          _playingIndex = null;
        });
      }
    });
  }

  void _showAddChordDialog(BuildContext context, SongProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Add Chord to Progression',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category selector (tabs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _chordBank.keys.map((category) {
                        final isSelected = _selectedChordCategory == category;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              _selectedChordCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8A2BE2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Chord selection grid
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _chordBank[_selectedChordCategory]?.length ?? 0,
                        itemBuilder: (context, idx) {
                          final chordName = _chordBank[_selectedChordCategory]![idx];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2E3E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final updatedChords = List<String>.from(provider.activeSong!.chords);
                              updatedChords.add(chordName);
                              provider.updateActiveSongChords(updatedChords);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $chordName chord'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: const Color(0xFF8A2BE2),
                                ),
                              );
                            },
                            child: Text(
                              chordName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSwapChordDialog(BuildContext context, SongProvider provider, int targetIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Swap Chord at Index ${targetIndex + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category selector (tabs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _chordBank.keys.map((category) {
                        final isSelected = _selectedChordCategory == category;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              _selectedChordCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8A2BE2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Chord selection grid
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: _chordBank[_selectedChordCategory]?.length ?? 0,
                        itemBuilder: (context, idx) {
                          final chordName = _chordBank[_selectedChordCategory]![idx];
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E2E3E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              final updatedChords = List<String>.from(provider.activeSong!.chords);
                              if (targetIndex >= 0 && targetIndex < updatedChords.length) {
                                final oldChord = updatedChords[targetIndex];
                                updatedChords[targetIndex] = chordName;
                                provider.updateActiveSongChords(updatedChords);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Swapped $oldChord to $chordName'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFF8A2BE2),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              chordName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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

    if (song == null) {
      return const Center(
        child: Text('No song selected', style: TextStyle(color: Colors.white)),
      );
    }

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
                  const Icon(Icons.music_note, color: Color(0xFF8A2BE2)),
                  const SizedBox(width: 8),
                  Text(
                    'Chord Progression (${song.chords.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _showAddChordDialog(context, provider),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Chord', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling chord layout
          SizedBox(
            height: 110,
            child: song.chords.isEmpty
                ? const Center(
                    child: Text(
                      'No chords in progression. Add some to get started!',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: song.chords.length,
                    onReorder: (int oldIndex, int newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final updatedChords = List<String>.from(song.chords);
                      final String item = updatedChords.removeAt(oldIndex);
                      updatedChords.insert(newIndex, item);
                      provider.updateActiveSongChords(updatedChords);
                    },
                    itemBuilder: (context, index) {
                      final chord = song.chords[index];
                      final isHovered = _hoveredIndex == index;
                      final isPlaying = _playingIndex == index;

                      return MouseRegion(
                        key: ValueKey('chord_item_${index}_$chord'),
                        onEnter: (_) => setState(() => _hoveredIndex = index),
                        onExit: (_) => setState(() => _hoveredIndex = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPlaying
                                  ? [
                                      _getChordColor(chord),
                                      Color.lerp(_getChordColor(chord), Colors.white, 0.35)!,
                                    ]
                                  : isHovered
                                      ? [
                                          _getChordColor(chord),
                                          Color.lerp(_getChordColor(chord), Colors.black, 0.3)!,
                                        ]
                                      : [
                                          Color.lerp(_getChordColor(chord), Colors.black, 0.15)!,
                                          Color.lerp(_getChordColor(chord), Colors.black, 0.55)!,
                                        ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPlaying
                                  ? Colors.white
                                  : isHovered
                                      ? Colors.white.withOpacity(0.9)
                                      : _getChordColor(chord).withOpacity(0.7),
                              width: 2.0,
                            ),
                            boxShadow: isPlaying
                                ? [
                                    BoxShadow(
                                      color: _getChordColor(chord).withOpacity(0.8),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: _getChordColor(chord).withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                          ),
                          child: Stack(
                            children: [
                              // Chord contents
                              InkWell(
                                onTap: () => _playChord(index, chord),
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        chord,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          shadows: isPlaying
                                              ? [
                                                  const Shadow(
                                                    color: Colors.black45,
                                                    blurRadius: 4,
                                                    offset: Offset(1, 1),
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Simulated mini waveform for previewing chord
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(4, (i) {
                                          return AnimatedContainer(
                                            duration: Duration(milliseconds: 100 + (i * 100)),
                                            width: 3,
                                            height: isPlaying ? (12.0 + (i * 4) % 16) : 3,
                                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                            decoration: BoxDecoration(
                                              color: isPlaying ? Colors.white : Colors.grey[600],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          );
                                        }),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              // Delete button
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () {
                                    final updatedChords = List<String>.from(song.chords);
                                    updatedChords.removeAt(index);
                                    provider.updateActiveSongChords(updatedChords);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 10,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              // Swap button at top-left
                              Positioned(
                                top: 4,
                                left: 4,
                                child: InkWell(
                                  onTap: () => _showSwapChordDialog(context, provider, index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: const Icon(
                                      Icons.swap_horiz,
                                      size: 10,
                                      color: Colors.white70,
                                    ),
                                  ),
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
    );
  }
}
