import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/song_provider.dart';
import '../utils/synth_engine.dart';

class RhythmicMemoRecorder extends StatefulWidget {
  const RhythmicMemoRecorder({super.key});

  @override
  State<RhythmicMemoRecorder> createState() => _RhythmicMemoRecorderState();
}

class _RhythmicMemoRecorderState extends State<RhythmicMemoRecorder> with SingleTickerProviderStateMixin {
  bool _isPlayingLoop = false;
  bool _isRecording = false;
  String _selectedRhythm = 'Boom Bap';
  int _currentBpm = 120;
  int _beatPulse = 0; // Metronome tick visual (1, 2, 3, 4)
  Timer? _rhythmTimer;
  DateTime? _lastTapTime;
  final List<double> _waveData = List.filled(30, 2.0);
  Timer? _waveTimer;
  double _recordingTimeSec = 0.0;
  Timer? _recordTimeTimer;
  final TextEditingController _memoTitleController = TextEditingController();

  // Actual recording controllers
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _vocalPlayer = AudioPlayer();

  // Mixer volumes state
  double _vocalVolume = 1.0;   // Default vocals to 100% max
  double _chordsVolume = 0.25; // Default chords backing to 25% (normalized less 6 dB)
  double _rhythmVolume = 0.25; // Default rhythm metronome to 25% (normalized less 6 dB)

  // Playback state of saved memos
  String? _playingMemoId;
  double _memoPlaybackProgress = 0.0;
  Timer? _playbackTimer;
  bool _isLoopingPlayback = false;
  bool _isPlaybackPaused = false;
  String? _activeMemoId;

  Duration? _totalDuration;
  int _lastChordStepPlayed = -1;
  int _lastBeatStepPlayed = -1;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _playerStateSubscription;

  // Custom markers per memo ID: map of memoId to list of relative progress values (0.0 to 1.0)
  final Map<String, List<double>> _memoMarkers = {};

  List<double> _getWaveformAmplitudes(String memoId) {
    final random = Random(memoId.hashCode);
    return List.generate(40, (index) {
      double factor = 1.0;
      if (index < 8) factor = index / 8.0;
      if (index > 32) factor = (40 - index) / 8.0;
      return (0.15 + random.nextDouble() * 0.85) * 28.0 * factor + 2.0;
    });
  }

  final List<String> _rhythms = ['Boom Bap', 'Trap Beat', 'Four-on-the-floor', 'Acoustic Swing', 'Silent Click'];

  @override
  void initState() {
    super.initState();
    _memoTitleController.text = 'Vocal sketch';

    _positionSubscription = _vocalPlayer.onPositionChanged.listen((position) {
      if (_playingMemoId == null) return;
      if (!mounted) return;
      
      final song = Provider.of<SongProvider>(context, listen: false).activeSong;
      if (song == null) return;
      
      final memo = song.voiceMemos.firstWhere((m) => m.id == _playingMemoId, orElse: () => song.voiceMemos.first);
      final rhythmPattern = memo.rhythmPattern;
      final memoBpm = memo.bpm;
      final beatIntervalMs = (60000 / memoBpm).round();

      // Proactively fetch duration if not yet resolved
      if (_totalDuration == null || _totalDuration!.inMilliseconds == 0) {
        _vocalPlayer.getDuration().then((dur) {
          if (dur != null && dur.inMilliseconds > 0 && mounted) {
            setState(() {
              _totalDuration = dur;
            });
          }
        });
      }

      setState(() {
        if (_totalDuration != null && _totalDuration!.inMilliseconds > 0) {
          _memoPlaybackProgress = position.inMilliseconds / _totalDuration!.inMilliseconds;
        }

        print('Waveform Sync - Position: ${position.inMilliseconds}ms, Duration: ${_totalDuration?.inMilliseconds}ms, Progress: ${(_memoPlaybackProgress * 100).toStringAsFixed(1)}%');

        if (rhythmPattern != 'Vocal Only') {
          // Play chord
          final currentChordStep = position.inMilliseconds ~/ 800;
          if (currentChordStep > _lastChordStepPlayed) {
            _lastChordStepPlayed = currentChordStep;
            if (song.chords.isNotEmpty) {
              final chordIndex = currentChordStep % song.chords.length;
              SynthEngine.playChord(song.chords[chordIndex]);
            }
          }

          // Play beat
          final currentBeat = position.inMilliseconds ~/ beatIntervalMs;
          if (currentBeat > _lastBeatStepPlayed) {
            _lastBeatStepPlayed = currentBeat;
            _playPlaybackBeatSound(rhythmPattern, (currentBeat % 4) + 1);
          }
        }
      });
    });

    _durationSubscription = _vocalPlayer.onDurationChanged.listen((duration) {
      if (_playingMemoId != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _playerStateSubscription = _vocalPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (_isLoopingPlayback && _playingMemoId != null) {
          _playMemo(_playingMemoId!);
        } else {
          setState(() {
            _playingMemoId = null;
            _memoPlaybackProgress = 0.0;
            _isPlaybackPaused = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _rhythmTimer?.cancel();
    _waveTimer?.cancel();
    _recordTimeTimer?.cancel();
    _playbackTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _memoTitleController.dispose();
    _audioRecorder.dispose();
    _vocalPlayer.dispose();
    super.dispose();
  }

  void _tapTempo() {
    final now = DateTime.now();
    if (_lastTapTime != null) {
      final difference = now.difference(_lastTapTime!).inMilliseconds;
      if (difference < 2000 && difference > 200) {
        final bpm = (60000 / difference).round();
        setState(() {
          _currentBpm = bpm.clamp(40, 240);
        });
        if (_isPlayingLoop || _isRecording) {
          _restartMetronome();
        }
      }
    }
    _lastTapTime = now;
  }

  void _toggleLoop() {
    if (_isPlayingLoop) {
      _rhythmTimer?.cancel();
      setState(() {
        _isPlayingLoop = false;
        _beatPulse = 0;
      });
    } else {
      setState(() {
        _isPlayingLoop = true;
      });
      _startMetronome();
    }
  }

  void _playActiveBeatSound() {
    switch (_selectedRhythm) {
      case 'Silent Click':
        SynthEngine.playTick();
        break;
      case 'Four-on-the-floor':
        SynthEngine.playDrum('kick');
        if (_beatPulse == 2 || _beatPulse == 4) {
          SynthEngine.playDrum('snare');
        } else {
          SynthEngine.playDrum('hat');
        }
        break;
      case 'Boom Bap':
        if (_beatPulse == 1) {
          SynthEngine.playDrum('kick');
        } else if (_beatPulse == 2) {
          SynthEngine.playDrum('snare');
          SynthEngine.playDrum('hat');
        } else if (_beatPulse == 3) {
          // Double kick feeling
          SynthEngine.playDrum('kick');
        } else if (_beatPulse == 4) {
          SynthEngine.playDrum('snare');
        }
        break;
      case 'Trap Beat':
        if (_beatPulse == 1) {
          SynthEngine.playDrum('kick');
          SynthEngine.playDrum('hat');
        } else if (_beatPulse == 2) {
          SynthEngine.playDrum('snare');
        } else if (_beatPulse == 3) {
          SynthEngine.playDrum('kick');
        } else if (_beatPulse == 4) {
          SynthEngine.playDrum('snare');
          SynthEngine.playDrum('hat');
        }
        break;
      case 'Acoustic Swing':
        if (_beatPulse == 1) {
          SynthEngine.playDrum('kick');
        } else if (_beatPulse == 2) {
          SynthEngine.playDrum('hat');
        } else if (_beatPulse == 3) {
          SynthEngine.playDrum('kick');
          SynthEngine.playDrum('hat');
        } else if (_beatPulse == 4) {
          SynthEngine.playDrum('hat');
        }
        break;
      default:
        SynthEngine.playTick();
    }
  }

  void _startMetronome() {
    _rhythmTimer?.cancel();
    final intervalMs = (60000 / _currentBpm).round();
    _rhythmTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      setState(() {
        _beatPulse = (_beatPulse % 4) + 1;
      });
      _playActiveBeatSound();
    });
  }

  void _restartMetronome() {
    if (_isPlayingLoop || _isRecording) {
      _startMetronome();
    }
  }

  Future<void> _startRecording() async {
    // Request permission first
    if (!await _audioRecorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for vocal sketches')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingTimeSec = 0.0;
      if (!_isPlayingLoop) {
        _isPlayingLoop = true;
        _startMetronome();
      }
    });

    try {
      String recordPath = '';
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        recordPath = '${tempDir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: recordPath);
    } catch (e) {
      print('Error starting microphone recording: $e');
    }

    // Animate waveform
    final random = Random();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        for (int i = 0; i < _waveData.length - 1; i++) {
          _waveData[i] = _waveData[i + 1];
        }
        _waveData[_waveData.length - 1] = 2.0 + random.nextDouble() * 28.0;
      });
    });

    // Track recording duration
    _recordTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTimeSec += 1.0;
      });
    });
  }

  Future<void> _stopRecording(SongProvider provider) async {
    _waveTimer?.cancel();
    _recordTimeTimer?.cancel();
    _rhythmTimer?.cancel(); // Stop metronome loop

    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      print('Error stopping microphone recording: $e');
    }

    final savedPath = path ?? '';

    final baseTitle = _memoTitleController.text.trim().isNotEmpty
        ? _memoTitleController.text.trim()
        : 'Vocal sketch';

    // File 1: Vocal Only (Microphone recording path, no chord backing, no drums)
    provider.addVoiceMemo(
      '$baseTitle (Vocal Only)',
      _currentBpm,
      'Vocal Only',
      savedPath,
    );

    // File 2: Chords Backing Only (Microphone path + chords progression synth)
    provider.addVoiceMemo(
      '$baseTitle (Chords Only)',
      _currentBpm,
      'Silent Click',
      savedPath,
    );

    // File 3: Full Groove Mix (Microphone path + chords progression + rhythm drum beat)
    provider.addVoiceMemo(
      '$baseTitle (Full Groove Mix: $_selectedRhythm)',
      _currentBpm,
      _selectedRhythm,
      savedPath,
    );

    setState(() {
      _isRecording = false;
      _isPlayingLoop = false; // Turn off rhythm playback
      _beatPulse = 0;         // Reset pulse visuals
      _recordingTimeSec = 0.0;
      _memoTitleController.text = 'Vocal sketch';
      // Reset waveform
      for (int i = 0; i < _waveData.length; i++) {
        _waveData[i] = 2.0;
      }
    });
  }

  void _playPlaybackBeatSound(String pattern, int beatPulse) {
    switch (pattern) {
      case 'Silent Click':
      case 'Vocal Only':
        break;
      case 'Four-on-the-floor':
        SynthEngine.playDrum('kick');
        if (beatPulse == 2 || beatPulse == 4) {
          SynthEngine.playDrum('snare');
        } else {
          SynthEngine.playDrum('hat');
        }
        break;
      case 'Boom Bap':
        if (beatPulse == 1) {
          SynthEngine.playDrum('kick');
        } else if (beatPulse == 2) {
          SynthEngine.playDrum('snare');
          SynthEngine.playDrum('hat');
        } else if (beatPulse == 3) {
          SynthEngine.playDrum('kick');
        } else if (beatPulse == 4) {
          SynthEngine.playDrum('snare');
        }
        break;
      case 'Trap Beat':
        if (beatPulse == 1) {
          SynthEngine.playDrum('kick');
          SynthEngine.playDrum('hat');
        } else if (beatPulse == 2) {
          SynthEngine.playDrum('snare');
        } else if (beatPulse == 3) {
          SynthEngine.playDrum('kick');
        } else if (beatPulse == 4) {
          SynthEngine.playDrum('snare');
          SynthEngine.playDrum('hat');
        }
        break;
      case 'Acoustic Swing':
        if (beatPulse == 1) {
          SynthEngine.playDrum('kick');
        } else if (beatPulse == 2) {
          SynthEngine.playDrum('hat');
        } else if (beatPulse == 3) {
          SynthEngine.playDrum('kick');
          SynthEngine.playDrum('hat');
        } else if (beatPulse == 4) {
          SynthEngine.playDrum('hat');
        }
        break;
    }
  }

  void _playMemo(String memoId) {
    _vocalPlayer.stop();

    setState(() {
      _playingMemoId = memoId;
      _activeMemoId = memoId;
      _isPlaybackPaused = false;
      _memoPlaybackProgress = 0.0;
      _totalDuration = null;
      _lastChordStepPlayed = -1;
      _lastBeatStepPlayed = -1;
    });

    final song = Provider.of<SongProvider>(context, listen: false).activeSong;
    if (song == null) return;

    final memo = song.voiceMemos.firstWhere((m) => m.id == memoId);
    final rhythmPattern = memo.rhythmPattern;

    _vocalPlayer.setVolume(_vocalVolume);
    if (rhythmPattern == 'Vocal Only') {
      SynthEngine.setChordsVolume(0.0);
      SynthEngine.setRhythmVolume(0.0);
    } else if (rhythmPattern == 'Silent Click') {
      SynthEngine.setChordsVolume(_chordsVolume);
      SynthEngine.setRhythmVolume(0.0);
    } else {
      SynthEngine.setChordsVolume(_chordsVolume);
      SynthEngine.setRhythmVolume(_rhythmVolume);
    }

    if (memo.filePath.isNotEmpty) {
      try {
        if (memo.filePath.startsWith('http') || memo.filePath.startsWith('blob:') || memo.filePath.startsWith('asset:')) {
          _vocalPlayer.play(UrlSource(memo.filePath)).then((_) async {
            final dur = await _vocalPlayer.getDuration();
            if (dur != null && dur.inMilliseconds > 0) {
              setState(() {
                _totalDuration = dur;
              });
              print('Fetched duration on play start: ${dur.inMilliseconds}ms');
            }
          });
        } else {
          _vocalPlayer.play(DeviceFileSource(memo.filePath)).then((_) async {
            final dur = await _vocalPlayer.getDuration();
            if (dur != null && dur.inMilliseconds > 0) {
              setState(() {
                _totalDuration = dur;
              });
              print('Fetched duration on play start: ${dur.inMilliseconds}ms');
            }
          });
        }
      } catch (e) {
        print('Error starting vocal playback: $e');
      }
    }
  }

  void _pauseMemo() {
    if (_playingMemoId != null) {
      _vocalPlayer.pause();
      setState(() {
        _isPlaybackPaused = true;
      });
    }
  }

  void _resumeMemo() {
    if (_playingMemoId != null && _isPlaybackPaused) {
      _vocalPlayer.resume();
      setState(() {
        _isPlaybackPaused = false;
      });
    }
  }

  void _stopMemo() {
    _vocalPlayer.stop();
    setState(() {
      _playingMemoId = null;
      _memoPlaybackProgress = 0.0;
      _isPlaybackPaused = false;
    });
  }

  void _handleScrub(double localX, double width) {
    if (_activeMemoId == null) return;
    final fraction = (localX / width).clamp(0.0, 1.0);
    setState(() {
      _memoPlaybackProgress = fraction;
    });
    
    if (_totalDuration != null && _totalDuration!.inMilliseconds > 0) {
      final targetMs = (fraction * _totalDuration!.inMilliseconds).round();
      _vocalPlayer.seek(Duration(milliseconds: targetMs));
      _lastChordStepPlayed = targetMs ~/ 800 - 1;
      
      final song = Provider.of<SongProvider>(context, listen: false).activeSong;
      if (song != null) {
        final memo = song.voiceMemos.firstWhere((m) => m.id == _activeMemoId);
        final beatIntervalMs = (60000 / memo.bpm).round();
        _lastBeatStepPlayed = targetMs ~/ beatIntervalMs - 1;
      }
    }
  }

  void _addMarker() {
    if (_activeMemoId == null) return;
    setState(() {
      final list = _memoMarkers[_activeMemoId!] ?? [];
      if (!list.any((val) => (val - _memoPlaybackProgress).abs() < 0.03)) {
        list.add(_memoPlaybackProgress);
        list.sort();
        _memoMarkers[_activeMemoId!] = list;
      }
    });
  }

  void _jumpToMarker(double fraction) {
    if (_activeMemoId == null) return;
    setState(() {
      _memoPlaybackProgress = fraction;
    });
    if (_totalDuration != null && _totalDuration!.inMilliseconds > 0) {
      final targetMs = (fraction * _totalDuration!.inMilliseconds).round();
      _vocalPlayer.seek(Duration(milliseconds: targetMs));
      _lastChordStepPlayed = targetMs ~/ 800 - 1;
      
      final song = Provider.of<SongProvider>(context, listen: false).activeSong;
      if (song != null) {
        final memo = song.voiceMemos.firstWhere((m) => m.id == _activeMemoId);
        final beatIntervalMs = (60000 / memo.bpm).round();
        _lastBeatStepPlayed = targetMs ~/ beatIntervalMs - 1;
      }
    }
  }

  Widget _buildMixerSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: onChanged == null ? Colors.grey[700] : Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                activeColor: activeColor,
                inactiveColor: const Color(0xFF13131A),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              onChanged == null ? 'MUTE' : '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: onChanged == null ? Colors.grey[700] : activeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SongProvider>(context);
    final song = provider.activeSong;

    if (song == null) return const SizedBox();

    final formattedRecordTime =
        '${(_recordingTimeSec / 60).floor().toString().padLeft(2, '0')}:${(_recordingTimeSec % 60).floor().toString().padLeft(2, '0')}';

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
            children: [
              const Icon(Icons.mic, color: Color(0xFF00FFCC)),
              const SizedBox(width: 8),
              const Text(
                'Rhythmic Voice Memos',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BPM controls and Loop selector
          Row(
            children: [
              // BPM Slider
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BPM: $_currentBpm', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        InkWell(
                          onTap: _tapTempo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFCC).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Tap Tempo',
                              style: TextStyle(color: Color(0xFF00FFCC), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _currentBpm.toDouble(),
                      min: 40,
                      max: 240,
                      activeColor: const Color(0xFF00FFCC),
                      inactiveColor: const Color(0xFF2E2E3E),
                      onChanged: (val) {
                        setState(() {
                          _currentBpm = val.round();
                        });
                        _restartMetronome();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Rhythm Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rhythm Style', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E2E3E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1E1E2E),
                        value: _selectedRhythm,
                        items: _rhythms.map((rhythm) {
                          return DropdownMenuItem<String>(
                            value: rhythm,
                            child: Text(rhythm, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRhythm = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // Pulsing Metronome indicator & Record Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                // Loop Play button
                InkWell(
                  onTap: _toggleLoop,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isPlayingLoop ? const Color(0xFF00FFCC).withOpacity(0.2) : const Color(0xFF2E2E3E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isPlayingLoop ? const Color(0xFF00FFCC) : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      _isPlayingLoop ? Icons.pause : Icons.play_arrow,
                      color: _isPlayingLoop ? const Color(0xFF00FFCC) : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Beats indicators
                Row(
                  children: List.generate(4, (index) {
                    final beatNum = index + 1;
                    final isActive = _beatPulse == beatNum;
                    return Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00FFCC)
                            : const Color(0xFF2D2D3D),
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00FFCC).withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
                const Spacer(),
                // Metronome text status
                Text(
                  _isPlayingLoop ? 'Rhythm Running' : 'Click Paused',
                  style: TextStyle(
                    color: _isPlayingLoop ? const Color(0xFF00FFCC) : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Recording trigger space
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _memoTitleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Memo title (e.g., Bridge Harmony)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF252535),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // REC Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFFFF5252).withOpacity(0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  if (_isRecording) {
                    _stopRecording(provider);
                  } else {
                    _startRecording();
                  }
                },
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                  size: 16,
                  color: Colors.red,
                ),
                label: Text(
                  _isRecording ? 'STOP ($formattedRecordTime)' : 'REC MIC + RHYTHM',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Visual Waveform during recording
          if (_isRecording) ...[
            const SizedBox(height: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _waveData.map((val) {
                  return Container(
                    width: 3,
                    height: val,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            )
          ],
          const SizedBox(height: 20),
          // Persistent Mixer Console
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MIXER CONSOLE',
                      style: TextStyle(color: Color(0xFF00FFCC), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_backup_restore, color: Colors.grey, size: 14),
                      tooltip: 'Reset Mix Defaults',
                      onPressed: () {
                        setState(() {
                          _vocalVolume = 1.0;
                          _chordsVolume = 0.25;
                          _rhythmVolume = 0.25;
                        });
                        _vocalPlayer.setVolume(_vocalVolume);
                        if (_playingMemoId != null) {
                          final playingMemo = song.voiceMemos.firstWhere((m) => m.id == _playingMemoId);
                          final pattern = playingMemo.rhythmPattern;
                          if (pattern == 'Vocal Only') {
                            SynthEngine.setChordsVolume(0.0);
                            SynthEngine.setRhythmVolume(0.0);
                          } else if (pattern == 'Silent Click') {
                            SynthEngine.setChordsVolume(0.25);
                            SynthEngine.setRhythmVolume(0.0);
                          } else {
                            SynthEngine.setChordsVolume(0.25);
                            SynthEngine.setRhythmVolume(0.25);
                          }
                        } else {
                          SynthEngine.setChordsVolume(0.25);
                          SynthEngine.setRhythmVolume(0.25);
                        }
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // Transport Panel
                if (_activeMemoId != null) ...[
                  Builder(builder: (context) {
                    final activeMemo = song.voiceMemos.firstWhere(
                      (m) => m.id == _activeMemoId,
                      orElse: () => song.voiceMemos.first,
                    );
                    final isPlaying = _playingMemoId == _activeMemoId && !_isPlaybackPaused;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Active Transport: ${activeMemo.title}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Playback Transport Buttons
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (_playingMemoId == _activeMemoId) {
                                  if (_isPlaybackPaused) {
                                    _resumeMemo();
                                  } else {
                                    _pauseMemo();
                                  }
                                } else {
                                  _playMemo(_activeMemoId!);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E1E2E),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 16,
                                  color: const Color(0xFF00FFCC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _stopMemo,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E1E2E),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Loop Toggle
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isLoopingPlayback = !_isLoopingPlayback;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isLoopingPlayback ? const Color(0xFF00FFCC).withOpacity(0.15) : const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isLoopingPlayback ? const Color(0xFF00FFCC) : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      size: 12,
                                      color: _isLoopingPlayback ? const Color(0xFF00FFCC) : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Loop',
                                      style: TextStyle(
                                        color: _isLoopingPlayback ? const Color(0xFF00FFCC) : Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Marker Button
                            InkWell(
                              onTap: _addMarker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF00FFCC).withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.add_location,
                                      size: 12,
                                      color: Color(0xFF00FFCC),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Add Marker',
                                      style: TextStyle(
                                        color: Color(0xFF00FFCC),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_memoPlaybackProgress * 100).round()}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Main Waveform Visualization (with scrubbing & marker overlay)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final markers = _memoMarkers[activeMemo.id] ?? [];
                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                _handleScrub(details.localPosition.dx, constraints.maxWidth);
                              },
                              onTapDown: (details) {
                                _handleScrub(details.localPosition.dx, constraints.maxWidth);
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(40, (index) {
                                        final waveAmps = _getWaveformAmplitudes(activeMemo.id);
                                        final heightVal = waveAmps[index];
                                        final isPlayed = _memoPlaybackProgress >= (index / 40.0);
                                        return Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 1),
                                            height: heightVal,
                                            decoration: BoxDecoration(
                                              color: isPlayed ? const Color(0xFF00FFCC) : const Color(0xFF2E2E3E),
                                              borderRadius: BorderRadius.circular(1.5),
                                              boxShadow: isPlayed && isPlaying
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF00FFCC).withOpacity(0.3),
                                                        blurRadius: 2,
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Marker line overlays
                                  ...markers.map((markerFraction) {
                                    final posX = markerFraction * constraints.maxWidth;
                                    return Positioned(
                                      left: posX - 4,
                                      top: 0,
                                      bottom: 0,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.arrow_drop_down, size: 10, color: Colors.amber),
                                          Container(
                                            width: 1.5,
                                            height: 16,
                                            color: Colors.amber.withOpacity(0.8),
                                          ),
                                          Icon(Icons.arrow_drop_up, size: 10, color: Colors.amber),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }
                        ),
                        
                        // Marker Chips jumping row
                        if (_memoMarkers[activeMemo.id]?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 24,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _memoMarkers[activeMemo.id]!.asMap().entries.map((entry) {
                                final idx = entry.key + 1;
                                final val = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: const Color(0xFF1E1E2E),
                                    side: const BorderSide(color: Colors.amber, width: 0.5),
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                    avatar: const Icon(Icons.location_on, size: 10, color: Colors.amber),
                                    label: Text(
                                      'M$idx (${(val * 100).round()}%)',
                                      style: const TextStyle(color: Colors.amber, fontSize: 9),
                                    ),
                                    onPressed: () => _jumpToMarker(val),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 8),
                      ],
                    );
                  }),
                ],

                _buildMixerSlider(
                  label: 'Vocal Mic',
                  value: _vocalVolume,
                  activeColor: const Color(0xFF00FFCC),
                  onChanged: (val) {
                    setState(() {
                      _vocalVolume = val;
                    });
                    _vocalPlayer.setVolume(val);
                  },
                ),
                _buildMixerSlider(
                  label: 'Chords Synth',
                  value: _chordsVolume,
                  activeColor: const Color(0xFFD03BFF),
                  onChanged: (val) {
                    setState(() {
                      _chordsVolume = val;
                    });
                    if (_playingMemoId == null || 
                        song.voiceMemos.firstWhere((m) => m.id == _playingMemoId).rhythmPattern != 'Vocal Only') {
                      SynthEngine.setChordsVolume(val);
                    }
                  },
                ),
                _buildMixerSlider(
                  label: 'Rhythm Groove',
                  value: _rhythmVolume,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    setState(() {
                      _rhythmVolume = val;
                    });
                    if (_playingMemoId == null || 
                        (song.voiceMemos.firstWhere((m) => m.id == _playingMemoId).rhythmPattern != 'Vocal Only' &&
                         song.voiceMemos.firstWhere((m) => m.id == _playingMemoId).rhythmPattern != 'Silent Click')) {
                      SynthEngine.setRhythmVolume(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recorded memos list
          const Text(
            'Recorded Sketch Library',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          song.voiceMemos.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No voice sketches recorded yet. Tap REC to record over the beat.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                )
              : Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: song.voiceMemos.map((memo) {
                      final isPlayingThis = _playingMemoId == memo.id;
                      final formattedDate = DateFormat('MMM dd, hh:mm a').format(memo.dateCreated);
                       return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252535).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_activeMemoId == memo.id) {
                                      if (_playingMemoId == memo.id) {
                                        if (_isPlaybackPaused) {
                                          _resumeMemo();
                                        } else {
                                          _pauseMemo();
                                        }
                                      } else {
                                        _playMemo(memo.id);
                                      }
                                    } else {
                                      _playMemo(memo.id);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isPlayingThis ? const Color(0xFF00FFCC) : const Color(0xFF1E1E2E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPlayingThis && !_isPlaybackPaused ? Icons.pause : Icons.play_arrow,
                                      size: 14,
                                      color: isPlayingThis ? Colors.black : const Color(0xFF00FFCC),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memo.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${memo.bpm} BPM • ${memo.rhythmPattern} • $formattedDate',
                                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                      const SizedBox(height: 6),
                                      // Mini audio waveform signature view
                                      SizedBox(
                                        height: 12,
                                        child: Row(
                                          children: List.generate(24, (wIndex) {
                                            final miniAmps = _getWaveformAmplitudes(memo.id);
                                            final val = (miniAmps[wIndex % 40] / 30.0) * 10.0 + 2.0;
                                            return Container(
                                              width: 2,
                                              height: val,
                                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                              decoration: BoxDecoration(
                                                color: isPlayingThis
                                                    ? const Color(0xFF00FFCC).withOpacity(0.8)
                                                    : Colors.white24,
                                                borderRadius: BorderRadius.circular(1),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Trash button to clean up memo
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 16),
                                  onPressed: () {
                                    if (_activeMemoId == memo.id) {
                                      _stopMemo();
                                      setState(() {
                                        _activeMemoId = null;
                                      });
                                    }
                                    provider.deleteVoiceMemo(memo.id);
                                  },
                                ),
                              ],
                            ),
                            // Sliders are now controlled globally via the main persistent Mixer Console.
                            if (isPlayingThis) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: _memoPlaybackProgress,
                                  backgroundColor: const Color(0xFF1E1E2E),
                                  color: const Color(0xFF00FFCC),
                                  minHeight: 3,
                                ),
                              ),
                              // Sliders are now controlled globally via the main persistent Mixer Console.
                            ]
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
