import 'dart:async';
import 'dart:math';
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

    setState(() {
      _isPlaying = true;
    });

    int noteIndex = 0;
    const noteDuration = 500; // ms

    _musicTimer = Timer.periodic(
      Duration(milliseconds: noteDuration),
          (timer) async {
        if (noteIndex >= _generatedNotes.length) {
          await _stopMusic();
          return;
        }

        await _playNote(_generatedNotes[noteIndex]);
        noteIndex++;

        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Future<void> _playNote(String note) async {
    // Tutaj symulujemy odtwarzanie przez wibracje i UI
    await _audioPlayer.play(AssetSource('sounds/${note.toLowerCase()}.wav'));
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
        moodScale = ['C', 'D', 'E', 'G', 'A'];
        break;
      case Mood.sad:
        moodScale = ['C', 'D#', 'F', 'G', 'A#'];
        break;
      case Mood.energetic:
        moodScale = ['C', 'D', 'E', 'F#', 'G', 'A', 'B'];
        break;
      case Mood.calm:
        moodScale = ['C', 'E', 'F', 'A', 'B'];
        break;
      default:
        moodScale = scales;
    }

    for (int i = 0; i < noteCount; i++) {
      String note = moodScale[random.nextInt(moodScale.length)];

      // Dodaj oktawę
      int octave = 4;
      if (userData.tempo > 150) octave++;
      if (userData.complexity > 0.7) {
        octave += random.nextInt(2);
      }

      notes.add('$note$octave');
    }

    return notes;
  }

  Future<void> _stopMusic() async {
    _musicTimer?.cancel();
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return Padding(
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
          const SizedBox(height: 30),
          Text(
            'Generuj muzykę w oparciu o:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Wyświetl informacje o generowanej muzyce
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Imię'),
                    trailing: Text(userData.name.isNotEmpty ? userData.name : 'Nie podano'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.mood),
                    title: const Text('Nastrój'),
                    trailing: Text('${userData.mood.emoji} ${userData.mood.displayName}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: const Text('Tempo'),
                    trailing: Text('${userData.tempo} BPM'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Przycisk generowania
          ElevatedButton.icon(
            onPressed: () => _generateAndPlayMusic(userData),
            icon: Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              size: 30,
            ),
            label: Text(
              _isPlaying ? 'Zatrzymaj muzykę' : 'Wygeneruj muzykę',
              style: const TextStyle(fontSize: 20),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: userData.favoriteColor,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 40),

          // Wyświetl wygenerowane nuty
          if (_generatedNotes.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wygenerowana sekwencja nut:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _generatedNotes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: userData.favoriteColor.withValues(),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: userData.favoriteColor),
                          ),
                          child: Center(
                            child: Text(
                              _generatedNotes[index],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: userData.favoriteColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}