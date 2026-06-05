import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class SynthEngine {
  static final AudioPlayer _chordPlayer = AudioPlayer();
  static final AudioPlayer _tickPlayer = AudioPlayer();

  // Maps chord symbols to their keyboard frequencies (Hz)
  static const Map<String, List<double>> _chordFrequencies = {
    // Majors
    'C': [261.63, 329.63, 392.00],    // C4, E4, G4
    'Db': [277.18, 349.23, 415.30],   // Db4, F4, Ab4
    'D': [293.66, 369.99, 440.00],    // D4, F#4, A4
    'Eb': [311.13, 392.00, 466.16],   // Eb4, G4, Bb4
    'E': [329.63, 415.30, 493.88],    // E4, G#4, B4
    'F': [349.23, 440.00, 523.25],    // F4, A4, C5
    'F#': [369.99, 466.16, 554.37],   // F#4, A#4, C#5
    'G': [392.00, 493.88, 587.33],    // G4, B4, D5
    'Ab': [415.30, 523.25, 622.25],   // Ab4, C5, Eb5
    'A': [440.00, 554.37, 659.25],    // A4, C#5, E5
    'Bb': [466.16, 587.33, 698.46],   // Bb4, D5, F5
    'B': [493.88, 622.25, 739.99],    // B4, Eb5, F#5
    
    // Minors
    'Cm': [261.63, 311.13, 392.00],   // C4, Eb4, G4
    'Dbm': [277.18, 329.63, 415.30],  // Db4, E4, Ab4
    'Dm': [293.66, 349.23, 440.00],   // D4, F4, A4
    'Ebm': [311.13, 329.63, 466.16],  // Eb4, Gb4, Bb4
    'Em': [329.63, 392.00, 493.88],   // E4, G4, B4
    'Fm': [349.23, 415.30, 523.25],   // F4, Ab4, C5
    'F#m': [369.99, 440.00, 554.37],  // F#4, A4, C#5
    'Gm': [392.00, 466.16, 587.33],   // G4, Bb4, D5
    'Abm': [415.30, 493.88, 622.25],  // Ab4, B4, Eb5
    'Am': [220.00, 261.63, 329.63],   // A3, C4, E4
    'Bbm': [233.08, 277.18, 349.23],  // Bb3, Db4, F4
    'Bm': [246.94, 293.66, 369.99],   // B3, D4, F#4

    // 7ths & maj7s
    'C7': [261.63, 329.63, 392.00, 466.16],
    'D7': [293.66, 369.99, 440.00, 513.74],
    'E7': [329.63, 415.30, 493.88, 587.33],
    'F7': [349.23, 440.00, 523.25, 622.25],
    'G7': [392.00, 493.88, 587.33, 698.46],
    'A7': [440.00, 554.37, 659.25, 783.99],
    'B7': [493.88, 622.25, 739.99, 880.00],
    'Cmaj7': [261.63, 329.63, 392.00, 493.88],
    'Dmaj7': [293.66, 369.99, 440.00, 554.37],
    'Fmaj7': [349.23, 440.00, 523.25, 659.25],
    'Gmaj7': [392.00, 493.88, 587.33, 739.99],
    'Amin7': [220.00, 261.63, 329.63, 392.00],

    // Suspended
    'Csus4': [261.63, 349.23, 392.00],
    'Dsus4': [293.66, 440.00, 587.33],
    'Esus4': [329.63, 440.00, 493.88],
     'Gsus4': [392.00, 523.25, 587.33],
    'Asus4': [440.00, 587.33, 659.25],
    'Csus2': [261.63, 293.66, 392.00],
    'Dsus2': [293.66, 440.00, 587.33],
    'Asus2': [440.00, 493.88, 659.25],

    // Diminished
    'Cdim': [261.63, 311.13, 369.99],
    'Ddim': [293.66, 349.23, 415.30],
    'Edim': [329.63, 392.00, 466.16],
    'Fdim': [349.23, 415.30, 493.88],
    'Gdim': [392.00, 466.16, 554.37],
    'Adim': [440.00, 523.25, 622.25],
    'Bdim': [246.94, 293.66, 349.23],
    'Cdim7': [261.63, 311.13, 369.99, 440.00],
    'Ddim7': [293.66, 349.23, 415.30, 493.88],
    'Adim7': [440.00, 523.25, 622.25, 739.99],

    // Half Diminished
    'Cm7b5': [261.63, 311.13, 369.99, 466.16],
    'Dm7b5': [293.66, 349.23, 415.30, 523.25],
    'Em7b5': [329.63, 392.00, 466.16, 587.33],
    'F#m7b5': [369.99, 440.00, 523.25, 659.25],
    'Gm7b5': [392.00, 466.16, 554.37, 698.46],
    'Am7b5': [440.00, 523.25, 622.25, 783.99],
    'Bm7b5': [246.94, 293.66, 349.23, 440.00],
  };

  static final Map<String, List<double>> _rhythmInstruments = {
    'kick': [55.0, 45.0, 30.0], // Rapid pitch glide down
    'snare': [180.0, 330.0],    // High mid frequencies + simulated noise
    'hat': [6000.0, 8000.0],    // High frequencies
  };

  /// Plays a chord procedurally with automatic decay
  static Future<void> playChord(String chordName) async {
    final cleanChord = chordName.trim();
    final freqs = _chordFrequencies[cleanChord] ?? _chordFrequencies['C']!;
    
    final bytes = _generateWavBytes(freqs, durationSec: 0.8, isChord: true, sustain: false);
    try {
      await _chordPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Playing Chord $cleanChord: $freqs Hz');
    }
  }

  /// Starts playing a chord that sustains until stopChord is called
  static Future<void> startChord(String chordName) async {
    final cleanChord = chordName.trim();
    final freqs = _chordFrequencies[cleanChord] ?? _chordFrequencies['C']!;
    
    final bytes = _generateWavBytes(freqs, durationSec: 4.0, isChord: true, sustain: true);
    try {
      await _chordPlayer.stop();
      await _chordPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Starting Chord $cleanChord: $freqs Hz');
    }
  }

  /// Stops the currently playing chord
  static Future<void> stopChord() async {
    try {
      await _chordPlayer.stop();
    } catch (e) {
      print('Stopping Chord');
    }
  }

  /// Sets volume for chords player (0.0 to 1.0)
  static void setChordsVolume(double volume) {
    _chordPlayer.setVolume(volume);
  }

  /// Sets volume for rhythm loop player (0.0 to 1.0)
  static void setRhythmVolume(double volume) {
    _tickPlayer.setVolume(volume);
  }

  /// Plays a metronome tick (high synth beep)
  static Future<void> playTick() async {
    final bytes = _generateWavBytes([1000.0], durationSec: 0.05, isChord: false);
    try {
      await _tickPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Tick beep');
    }
  }

  /// Plays a dynamic rhythmic instrument sound (kick, snare, hat)
  static Future<void> playDrum(String instrument) async {
    final freqs = _rhythmInstruments[instrument] ?? [300.0];
    final bytes = _generateWavBytes(freqs, durationSec: 0.15, isChord: false, isDrum: true, drumType: instrument);
    try {
      await _tickPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Drum sound $instrument');
    }
  }

  /// Generate WAV PCM in-memory bytes
  static Uint8List _generateWavBytes(
    List<double> frequencies, {
    double durationSec = 1.0,
    bool isChord = true,
    bool isDrum = false,
    String drumType = '',
    bool sustain = false,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * durationSec).toInt();
    final dataSize = totalSamples * 2; // 16-bit = 2 bytes per sample
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF Header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    // WAVE Header
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt subchunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk size (16 for PCM)
    header.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    header.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    header.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
    header.setUint16(34, 16, Endian.little); // BitsPerSample (16)
    // data subchunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());

    final random = Random();

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      double sampleVal = 0.0;

      if (isDrum) {
        if (drumType == 'kick') {
          // Dynamic pitch slide starting at 120Hz sliding down to 40Hz
          final frequency = 40.0 + (120.0 - 40.0) * exp(-100.0 * t);
          final envelope = exp(-15.0 * t);
          sampleVal = sin(2 * pi * frequency * t) * envelope;
        } else if (drumType == 'snare') {
          // High mid tone + simulated noise
          final tone = sin(2 * pi * 180.0 * t) * 0.4 + sin(2 * pi * 330.0 * t) * 0.2;
          final noise = (random.nextDouble() * 2 - 1.0) * 0.4;
          final envelope = exp(-20.0 * t);
          sampleVal = (tone + noise) * envelope;
        } else if (drumType == 'hat') {
          // Pure white noise filtered through high frequencies (rapid ticks)
          final noise = (random.nextDouble() * 2 - 1.0) * 0.8;
          final envelope = exp(-60.0 * t);
          sampleVal = noise * envelope;
        }
      } else {
        // Chord synthesis (Polyphonic sinewaves)
        for (final freq in frequencies) {
          sampleVal += sin(2 * pi * freq * t);
        }
        sampleVal = sampleVal / frequencies.length; // Normalize amplitudes

        // Apply volume envelope (exponential decay envelope)
        double envelope = 1.0;
        if (isChord) {
          if (sustain) {
            envelope = exp(-0.3 * t); // Slow decay to keep sustaining
          } else {
            envelope = exp(-2.5 * t); // Smooth decay over 0.8 seconds
          }
        } else {
          envelope = exp(-40.0 * t); // Extremely rapid decay for metronome beeps
        }
        sampleVal *= envelope;
      }

      // Convert double float to 16-bit signed integer PCM (-32768 to 32767)
      final intSample = (sampleVal * 28000).round().clamp(-32768, 32767);
      
      final index = 44 + (i * 2);
      wavBytes[index] = intSample & 0xFF;          // Low byte
      wavBytes[index + 1] = (intSample >> 8) & 0xFF; // High byte
    }

    return wavBytes;
  }
}
