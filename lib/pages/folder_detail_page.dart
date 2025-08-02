import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/audio_folder.dart';
import '../services/folder_service.dart';
import '../services/audio_service.dart';
import '../widgets/song_tile.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/music_control_sheet.dart';
import '../widgets/song_selection_dialog.dart';
import 'package:just_audio/just_audio.dart';

class FolderDetailPage extends StatefulWidget {
  final AudioFolder folder;
  final bool isDarkMode;

  const FolderDetailPage({
    super.key,
    required this.folder,
    required this.isDarkMode,
  });

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  final FolderService _folderService = FolderService();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioService _audioService = AudioService();

  List<SongModel> _allSongs = [];
  List<SongModel> _folderSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFolderSongs();
  }

  Future<void> _loadFolderSongs() async {
    setState(() => _loading = true);

    try {
      // Load all songs first
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final filtered = songs.where((song) => (song.size) >= 1048576).toList();

      setState(() {
        _allSongs = filtered;
      });

      // Get songs in this folder
      final songIds = await _folderService.getSongsInFolder(widget.folder.id);
      final folderSongs = filtered
          .where((song) => songIds.contains(song.id.toString()))
          .toList();

      setState(() {
        _folderSongs = folderSongs;
        _loading = false;
      });

      // Load songs into player if there are any
      if (_folderSongs.isNotEmpty) {
        await _loadSongsToPlayer(_folderSongs);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading folder songs: $e')),
        );
      }
    }
  }

  Future<void> _loadSongsToPlayer(List<SongModel> songs) async {
    await _audioService.loadSongsToPlayer(songs);
  }

  Future<void> _playSong(SongModel song, {bool openSheet = true}) async {
    debugPrint("Playing song: ${song.title}");

    if (openSheet) {
      _openControlSheet();
    }

    await _audioService.playSong(song);
  }

  void _playNext() async {
    await _audioService.playNext();
  }

  void _playPrevious() async {
    await _audioService.playPrevious();
  }

  Future<void> _pause() async {
    await _audioService.pause();
  }

  Future<void> _seek(double value) async {
    await _audioService.seek(Duration(milliseconds: value.toInt()));
  }

  void _openControlSheet() {
    final currentSong = _audioService.getCurrentSong();
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ValueListenableBuilder<int>(
          valueListenable: _audioService.playerNotifier,
          builder: (context, _, __) => MusicControlSheet(
            song: currentSong,
            isPlaying: _audioService.isPlaying,
            position: _audioService.position,
            duration: _audioService.duration,
            onPlay: () => _playSong(currentSong, openSheet: false),
            onPause: _pause,
            onSeek: _seek,
            player: _audioService.player,
            scrollController: scrollController,
            onNext: _playNext,
            onPrevious: _playPrevious,
            onShuffle: () {},
            onRepeat: () {},
            isShuffling: false,
            loopMode: LoopMode.off,
            onToggleDarkMode: () {},
            isDarkMode: widget.isDarkMode,
          ),
        ),
      ),
    );
  }

  Future<void> _removeSongFromFolder(SongModel song) async {
    try {
      await _folderService.removeSongFromFolder(
        widget.folder.id,
        song.id.toString(),
      );
      await _loadFolderSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "${song.title}" from folder')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing song: $e')));
      }
    }
  }

  Future<void> _addSongsToFolder() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SongSelectionDialog(
        folder: widget.folder,
        isDarkMode: widget.isDarkMode,
      ),
    );

    if (result == true) {
      // Songs were added, reload the folder
      await _loadFolderSongs();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folder.name,
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (widget.folder.description != null)
              Text(
                widget.folder.description!,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            Text(
              '${_folderSongs.length} songs',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.deepPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_folderSongs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.playlist_play_rounded, color: Colors.deepPurple),
              onPressed: () {
                if (_folderSongs.isNotEmpty) {
                  _playSong(_folderSongs.first);
                }
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _folderSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: widget.isDarkMode
                        ? Colors.white54
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Songs in Folder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add songs to this folder to start listening',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white54
                          : Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addSongsToFolder,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Songs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to main music list
                      Navigator.of(context).pushNamed('/');
                    },
                    icon: const Icon(Icons.library_music_rounded),
                    label: const Text('Browse All Songs'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: _folderSongs.length,
              itemBuilder: (context, index) => SongTile(
                song: _folderSongs[index],
                isCurrent: _audioService.isCurrentSong(_folderSongs[index]),
                isPlaying: _audioService.isSongPlaying(_folderSongs[index]),
                onPlay: () => _playSong(_folderSongs[index], openSheet: false),
                onPause: _pause,
                onTap: () {
                  final song = _folderSongs[index];
                  final currentSong = _audioService.getCurrentSong();
                  if (currentSong?.id != song.id || !_audioService.isPlaying) {
                    _playSong(song);
                  } else {
                    _openControlSheet();
                  }
                },
                isDarkMode: widget.isDarkMode,
                onRemove: () => _removeSongFromFolder(_folderSongs[index]),
              ),
            ),
      floatingActionButton: _folderSongs.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addSongsToFolder,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _audioService.playerNotifier,
        builder: (context, _, __) => NowPlayingBar(
          currentSong: _audioService.getCurrentSong(),
          isPlaying: _audioService.isPlaying,
          position: _audioService.position,
          duration: _audioService.duration,
          onPlay: _audioService.getCurrentSong() != null
              ? () =>
                    _playSong(_audioService.getCurrentSong()!, openSheet: false)
              : null,
          onPause: _pause,
          onSeek: _seek,
          onTap: _openControlSheet,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }
}
