import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'models/user_data.dart';

class MusicGeneratorPage extends StatefulWidget {
  const MusicGeneratorPage({super.key});

  @override
  State<MusicGeneratorPage> createState() => _MusicGeneratorPageState();
}

class _MusicGeneratorPageState extends State<MusicGeneratorPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  List<String> _generatedNotes = [];
  Timer? _musicTimer;
  int _currentNoteIndex = 0;

  // Mapowanie nut do plików dźwiękowych
  final Map<String, String> _noteToSoundFile = {
    'A4': 'sounds/a4.wav',
    'A5': 'sounds/a5.wav',
    'B4': 'sounds/b4.wav',
    'B5': 'sounds/b5.wav',
    'C4': 'sounds/c4.wav',
    'C5': 'sounds/c5.wav',
    'D4': 'sounds/d4.wav',
    'D5': 'sounds/d5.wav',
    'E4': 'sounds/e4.wav',
    'E5': 'sounds/e5.wav',
    'F4': 'sounds/f4.wav',
    'F5': 'sounds/f5.wav',
    'G4': 'sounds/g4.wav',
    'G5': 'sounds/g5.wav',
  };


  @override
  void dispose() {
    _audioPlayer.dispose();
    _musicTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateAndPlayMusic(UserData userData) async {
    if (_isPlaying) {
      await _stopMusic();
      return;
    }

    _generatedNotes = _generateMusicNotes(userData);
    _currentNoteIndex = 0;

    setState(() {
      _isPlaying = true;
    });

    // Oblicz odstęp między nutami na podstawie tempa
    // 60,000 ms / BPM = ms na ćwierćnutę
    int noteDuration = (60000 / userData.tempo).round();

    _musicTimer = Timer.periodic(
      Duration(milliseconds: noteDuration),
          (timer) async {
        if (_currentNoteIndex >= _generatedNotes.length) {
          await _stopMusic();
          return;
        }

        String note = _generatedNotes[_currentNoteIndex];
        await _playNote(note);

        setState(() {
          _currentNoteIndex++;
        });
      },
    );
  }

  Future<void> _playNote(String note) async {
    try {
      // Spróbuj domyślnej ścieżki
      String soundFile = _noteToSoundFile[note] ?? 'sounds/c4.wav';

      // Upewnij się, że ścieżka jest poprawna
      if (!soundFile.startsWith('assets/')) {
        soundFile = 'assets/$soundFile';
      }

      await _audioPlayer.play(AssetSource(soundFile.replaceFirst('assets/', '')));
    } catch (e) {
      if (kDebugMode) {
        print('Błąd odtwarzania nuty $note: $e');
      }
      // Fallback: wibracje
      // HapticFeedback.lightImpact();
    }
  }

  List<String> _generateMusicNotes(UserData userData) {
    List<String> scales = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    List<String> notes = [];
    Random random = Random();

    int noteCount = (userData.complexity * 20 + 10).toInt();

    // Dostosuj skalę do nastroju
    List<String> moodScale = [];
    switch (userData.mood) {
      case Mood.happy:
        moodScale = ['C', 'D', 'E', 'G', 'A']; // Major scale
        break;
      case Mood.sad:
        moodScale = ['C', 'D#', 'F', 'G', 'A#']; // Minor scale
        break;
      case Mood.energetic:
        moodScale = ['C', 'D', 'E', 'F#', 'G', 'A', 'B']; // Lydian
        break;
      case Mood.calm:
        moodScale = ['C', 'E', 'F', 'A', 'B']; // Pentatonic
        break;
      default:
        moodScale = scales;
    }

    for (int i = 0; i < noteCount; i++) {
      String noteName = moodScale[random.nextInt(moodScale.length)];

      // Wybierz oktawę
      int octave;
      if (userData.tempo < 80) {
        octave = 3; // Wolne tempo - niższe dźwięki
      } else if (userData.tempo > 160) {
        octave = 5; // Szybkie tempo - wyższe dźwięki
      } else {
        octave = 4; // Średnie tempo
      }

      // Losowe zmiany oktawy dla złożoności
      if (userData.complexity > 0.7 && random.nextDouble() > 0.7) {
        octave += random.nextBool() ? 1 : -1;
        octave = octave.clamp(3, 5); // Ogranicz do oktaw 3-5
      }

      notes.add('$noteName$octave');
    }

    return notes;
  }

  Future<void> _stopMusic() async {
    _musicTimer?.cancel();
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentNoteIndex = 0;
    });
  }


  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(
                _isPlaying ? Icons.music_note : Icons.music_off,
                size: 100,
                color: userData.favoriteColor,
              ),
              const SizedBox(height: 20),

              // Status odtwarzania
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userData.favoriteColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isPlaying ? Icons.play_arrow : Icons.pause,
                      color: userData.favoriteColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isPlaying
                          ? 'Odtwarzanie nuty ${_currentNoteIndex + 1}/${_generatedNotes.length}'
                          : 'Gotowy do generowania',
                      style: TextStyle(
                        color: userData.favoriteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Informacje o muzyce
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person, color: userData.favoriteColor),
                        title: const Text('Imię'),
                        trailing: Text(
                          userData.name.isNotEmpty ? userData.name : 'Nie podano',
                          style: TextStyle(color: userData.favoriteColor),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.mood, color: userData.favoriteColor),
                        title: const Text('Nastrój'),
                        trailing: Text(
                          '${userData.mood.emoji} ${userData.mood.displayName}',
                          style: TextStyle(color: userData.favoriteColor),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.speed, color: userData.favoriteColor),
                        title: const Text('Tempo'),
                        trailing: Text(
                          '${userData.tempo} BPM',
                          style: TextStyle(
                            color: userData.favoriteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.layers, color: userData.favoriteColor),
                        title: const Text('Złożoność'),
                        trailing: Text(
                          '${(userData.complexity * 100).toInt()}%',
                          style: TextStyle(color: userData.favoriteColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Przyciski sterujące
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _generateAndPlayMusic(userData),
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 30,
                    ),
                    label: Text(
                      _isPlaying ? 'ZATRZYMAJ' : 'GENERUJ MUZYKĘ',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                      backgroundColor: userData.favoriteColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Wyświetl wygenerowane nuty
              if (_generatedNotes.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wygenerowana sekwencja nut:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: userData.favoriteColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.builder(
                        itemCount: _generatedNotes.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _currentNoteIndex == index
                                  ? userData.favoriteColor
                                  : userData.favoriteColor.withAlpha(50),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: _currentNoteIndex == index
                                      ? Colors.white
                                      : userData.favoriteColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              _generatedNotes[index],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: userData.favoriteColor,
                              ),
                            ),
                            trailing: Icon(
                              Icons.music_note,
                              color: userData.favoriteColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                  ],
                ),
              ),

          ),
    );
  }
}