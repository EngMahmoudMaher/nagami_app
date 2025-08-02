import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  List<SongModel> _currentPlaylist = [];
  int _currentPlaylistIndex = 0;
  bool _audioSourcesLoaded = false;
  final ValueNotifier<int> _playerNotifier = ValueNotifier<int>(0);

  // Getters
  AudioPlayer get player => _player;
  ValueNotifier<int> get playerNotifier => _playerNotifier;
  List<SongModel> get currentPlaylist => _currentPlaylist;
  int get currentPlaylistIndex => _currentPlaylistIndex;
  bool get audioSourcesLoaded => _audioSourcesLoaded;

  // Setup player listeners
  void setupListeners() {
    _player.positionStream.listen((pos) {
      _playerNotifier.value++;
    });

    _player.durationStream.listen((dur) {
      _playerNotifier.value++;
    });

    _player.playerStateStream.listen((state) {
      _playerNotifier.value++;
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _currentPlaylist.length) {
        _currentPlaylistIndex = index;
        _playerNotifier.value++;
      }
    });
  }

  // Load songs into player
  Future<void> loadSongsToPlayer(List<SongModel> songs) async {
    if (songs.isEmpty) return;

    try {
      debugPrint("Loading ${songs.length} songs to shared player");

      final audioSources = songs
          .map((song) => AudioSource.uri(Uri.parse(song.uri!)))
          .toList();

      final concatenatingSource = ConcatenatingAudioSource(
        children: audioSources,
      );

      await _player.setAudioSource(
        concatenatingSource,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      _currentPlaylist = songs;
      _audioSourcesLoaded = true;
      _currentPlaylistIndex = 0;
      debugPrint("Successfully loaded ${songs.length} songs to shared player");
    } catch (e) {
      debugPrint("Error loading audio sources: $e");
      _audioSourcesLoaded = false;
    }
  }

  // Play a specific song
  Future<void> playSong(SongModel song) async {
    final index = _currentPlaylist.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      debugPrint("Song not found in current playlist, loading new playlist");
      await loadSongsToPlayer([song]);
      await _player.play();
      return;
    }

    if (!_audioSourcesLoaded) {
      debugPrint("Audio sources not loaded, loading now");
      await loadSongsToPlayer(_currentPlaylist);
    }

    try {
      if (_player.currentIndex != index) {
        debugPrint("Seeking to index: $index");
        await _player.seek(Duration.zero, index: index);
      }
      await _player.play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  // Play next song
  Future<void> playNext() async {
    await _player.seekToNext();
    await _player.play();
  }

  // Play previous song
  Future<void> playPrevious() async {
    await _player.seekToPrevious();
    await _player.play();
  }

  // Pause
  Future<void> pause() async {
    await _player.pause();
  }

  // Seek
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // Get current song
  SongModel? getCurrentSong() {
    if (_currentPlaylistIndex >= 0 &&
        _currentPlaylistIndex < _currentPlaylist.length) {
      return _currentPlaylist[_currentPlaylistIndex];
    }
    return null;
  }

  // Check if a song is currently playing
  bool isSongPlaying(SongModel song) {
    final currentSong = getCurrentSong();
    return currentSong?.id == song.id && _player.playing;
  }

  // Check if a song is the current song (playing or paused)
  bool isCurrentSong(SongModel song) {
    final currentSong = getCurrentSong();
    return currentSong?.id == song.id;
  }

  // Get current position
  Duration get position => _player.position;

  // Get current duration
  Duration get duration => _player.duration ?? Duration.zero;

  // Get playing state
  bool get isPlaying => _player.playing;

  // Get player state
  PlayerState get playerState => _player.playerState;

  // Dispose (call this when app is closing)
  void dispose() {
    _player.dispose();
    _playerNotifier.dispose();
  }
}
