import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../widgets/song_tile.dart';
import '../widgets/now_playing_bar.dart';
import '../widgets/music_control_sheet.dart';
import '../services/folder_service.dart';
import '../services/audio_service.dart';
import '../models/audio_folder.dart';
import 'package:just_audio/just_audio.dart';
import 'folder_list_page.dart';

class MusicListPage extends StatefulWidget {
  const MusicListPage({super.key});

  @override
  State<MusicListPage> createState() => _MusicListPageState();
}

class _MusicListPageState extends State<MusicListPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioService _audioService = AudioService();

  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  bool _loading = true;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  final FolderService _folderService = FolderService();

  bool _isShuffling = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadSongs();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    // Audio service handles all player listeners
    _audioService.setupListeners();
  }

  Future<void> _requestPermissionAndLoadSongs() async {
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final filtered = songs
        .where((song) => (song.size ?? 0) >= 1048576)
        .toList(); // 1MB

    setState(() {
      _allSongs = filtered;
      _filteredSongs = filtered;
      _loading = false;
    });

    // Load the complete list into the player ONCE.
    await _loadSongsToPlayer(_allSongs);
  }

  Future<void> _loadSongsToPlayer(List<SongModel> songs) async {
    await _audioService.loadSongsToPlayer(songs);
  }

  // UPDATED: Search only filters the UI list and does not touch the player.
  void _filterSongs(String query) {
    List<SongModel> newFilteredSongs;
    if (query.isEmpty) {
      newFilteredSongs = _allSongs;
    } else {
      newFilteredSongs = _allSongs.where((song) {
        final title = song.title.toLowerCase();
        final artist = (song.artist ?? '').toLowerCase();
        final q = query.toLowerCase();
        return title.contains(q) || artist.contains(q);
      }).toList();
    }
    setState(() {
      _filteredSongs = newFilteredSongs;
    });
  }

  // UPDATED: Uses shared audio service
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

  void _toggleShuffle() async {
    setState(() => _isShuffling = !_isShuffling);
    await _audioService.player.setShuffleModeEnabled(_isShuffling);
    _audioService.playerNotifier.value++;
  }

  void _toggleRepeat() async {
    setState(() {
      _loopMode =
          LoopMode.values[(_loopMode.index + 1) % LoopMode.values.length];
    });
    await _audioService.player.setLoopMode(_loopMode);
    _audioService.playerNotifier.value++;
  }

  Future<void> _pause() async {
    await _audioService.pause();
  }

  Future<void> _seek(double value) async {
    await _audioService.seek(Duration(milliseconds: value.toInt()));
  }

  // Method to reset audio sources if needed
  Future<void> _resetAudioSources() async {
    await _audioService.loadSongsToPlayer(_allSongs);
  }

  // Show folder options for a song
  Future<void> _showFolderOptions(SongModel song) async {
    final folders = await _folderService.getFolders();
    final foldersContainingSong = await _folderService.getFoldersContainingSong(
      song.id.toString(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Folder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (folders.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 48,
                      color: _isDarkMode ? Colors.white54 : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No folders yet',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openFolderList();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Folder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final isInFolder = foldersContainingSong.any(
                      (f) => f.id == folder.id,
                    );

                    return ListTile(
                      leading: Icon(
                        isInFolder
                            ? Icons.folder_rounded
                            : Icons.folder_outlined,
                        color: isInFolder ? Colors.deepPurple : Colors.grey,
                      ),
                      title: Text(
                        folder.name,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: isInFolder
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${folder.songCount} songs',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isInFolder ? Icons.remove_rounded : Icons.add_rounded,
                          color: isInFolder ? Colors.red : Colors.deepPurple,
                        ),
                        onPressed: () async {
                          if (isInFolder) {
                            await _folderService.removeSongFromFolder(
                              folder.id,
                              song.id.toString(),
                            );
                          } else {
                            await _folderService.addSongToFolder(
                              folder.id,
                              song.id.toString(),
                            );
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isInFolder
                                    ? 'Removed from "${folder.name}"'
                                    : 'Added to "${folder.name}"',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openFolderList();
                    },
                    icon: const Icon(Icons.folder_rounded),
                    label: const Text('Manage Folders'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openFolderList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderListPage(isDarkMode: _isDarkMode),
      ),
    );
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _openControlSheet() {
    final currentSong = _audioService.getCurrentSong();
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
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
            onShuffle: _toggleShuffle,
            onRepeat: _toggleRepeat,
            isShuffling: _isShuffling,
            loopMode: _loopMode,
            onToggleDarkMode: _toggleDarkMode,
            isDarkMode: _isDarkMode,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [Colors.grey[900]!, Colors.black]
                  : [Colors.white, Colors.grey[50]!],
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.library_music_rounded,
            color: Colors.deepPurple,
            size: 24,
          ),
        ),
        title: _showSearch
            ? Container(
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _isDarkMode ? Colors.white12 : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search songs or artists...',
                    hintStyle: TextStyle(
                      color: _isDarkMode ? Colors.white54 : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                  onChanged: _filterSongs,
                ),
              )
            : Text(
                'My Music',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.folder_rounded, color: Colors.deepPurple),
              onPressed: _openFolderList,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.amber.withAlpha(25)
                  : Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: _isDarkMode ? Colors.amber : Colors.deepPurple,
              ),
              onPressed: _toggleDarkMode,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                setState(() {
                  if (_showSearch) {
                    _showSearch = false;
                    _searchController.clear();
                    _filterSongs('');
                  } else {
                    _showSearch = true;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [Colors.black, Colors.grey[900]!]
                : [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: _loading
            ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : _filteredSongs.isEmpty
            ? Center(
                child: Text(
                  'No Songs Found',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              )
            : SongListView(
                songs: _filteredSongs,
                currentSongId: _audioService.getCurrentSong()?.id,
                isPlaying: _audioService.isPlaying,
                onPlay: (song) => _playSong(song, openSheet: false),
                onPause: _pause,
                onTap: (song) {
                  final currentSong = _audioService.getCurrentSong();
                  if (currentSong?.id != song.id || !_audioService.isPlaying) {
                    _playSong(song);
                  } else {
                    _openControlSheet();
                  }
                },
                onLongPress: _showFolderOptions,
                isDarkMode: _isDarkMode,
              ),
      ),
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
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}

class SongListView extends StatelessWidget {
  final List<SongModel> songs;
  final int? currentSongId;
  final bool isPlaying;
  final void Function(SongModel) onPlay;
  final VoidCallback onPause;
  final void Function(SongModel) onTap;
  final void Function(SongModel)? onLongPress;
  final bool isDarkMode;

  const SongListView({
    super.key,
    required this.songs,
    required this.currentSongId,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.onTap,
    this.onLongPress,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: songs.length,
      itemBuilder: (context, index) => GestureDetector(
        onLongPress: onLongPress != null
            ? () => onLongPress!(songs[index])
            : null,
        child: SongTile(
          song: songs[index],
          isCurrent: songs[index].id == currentSongId,
          isPlaying: songs[index].id == currentSongId && isPlaying,
          onPlay: () => onPlay(songs[index]),
          onPause: onPause,
          onTap: () => onTap(songs[index]),
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }
}
