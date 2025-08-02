import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../services/folder_service.dart';
import '../models/audio_folder.dart';

class SongSelectionDialog extends StatefulWidget {
  final AudioFolder folder;
  final bool isDarkMode;

  const SongSelectionDialog({
    super.key,
    required this.folder,
    required this.isDarkMode,
  });

  @override
  State<SongSelectionDialog> createState() => _SongSelectionDialogState();
}

class _SongSelectionDialogState extends State<SongSelectionDialog> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final FolderService _folderService = FolderService();

  List<SongModel> _allSongs = [];
  List<SongModel> _filteredSongs = [];
  List<String> _selectedSongIds = [];
  bool _loading = true;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);

    try {
      // Get all songs
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final filtered = songs
          .where((song) => (song.size ?? 0) >= 1048576)
          .toList();

      // Get songs already in the folder
      final folderSongIds = await _folderService.getSongsInFolder(
        widget.folder.id,
      );

      setState(() {
        _allSongs = filtered;
        _filteredSongs = filtered
            .where((song) => !folderSongIds.contains(song.id.toString()))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading songs: $e')));
      }
    }
  }

  void _filterSongs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = _allSongs
            .where((song) => !widget.folder.containsSong(song.id.toString()))
            .toList();
      });
    } else {
      setState(() {
        _filteredSongs = _allSongs.where((song) {
          final title = song.title.toLowerCase();
          final artist = (song.artist ?? '').toLowerCase();
          final q = query.toLowerCase();
          return (title.contains(q) || artist.contains(q)) &&
              !widget.folder.containsSong(song.id.toString());
        }).toList();
      });
    }
  }

  void _toggleSongSelection(SongModel song) {
    setState(() {
      final songId = song.id.toString();
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  Future<void> _addSelectedSongs() async {
    if (_selectedSongIds.isEmpty) return;

    try {
      for (final songId in _selectedSongIds) {
        await _folderService.addSongToFolder(widget.folder.id, songId);
      }

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate songs were added
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedSongIds.length} song${_selectedSongIds.length == 1 ? '' : 's'} to "${widget.folder.name}"',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding songs: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_to_photos_rounded,
                  color: Colors.deepPurple,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Songs to "${widget.folder.name}"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
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
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // Search bar
            if (_showSearch) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search songs or artists...',
                  hintStyle: TextStyle(
                    color: widget.isDarkMode
                        ? Colors.white54
                        : Colors.grey[600],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.isDarkMode
                        ? Colors.white54
                        : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: widget.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[50],
                ),
                onChanged: _filterSongs,
              ),
            ],

            const SizedBox(height: 16),

            // Song count and select all
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_filteredSongs.length} songs available',
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_allSongs.length} total songs on device',
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white54
                            : Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_filteredSongs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedSongIds.length == _filteredSongs.length) {
                          // Deselect all
                          _selectedSongIds.clear();
                        } else {
                          // Select all
                          _selectedSongIds = _filteredSongs
                              .map((song) => song.id.toString())
                              .toList();
                        }
                      });
                    },
                    child: Text(
                      _selectedSongIds.length == _filteredSongs.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (_selectedSongIds.isNotEmpty)
                  Text(
                    '${_selectedSongIds.length} selected',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Songs list
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : _filteredSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 64,
                            color: widget.isDarkMode
                                ? Colors.white54
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Songs Available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All songs are already in this folder',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        final isSelected = _selectedSongIds.contains(
                          song.id.toString(),
                        );

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Container(
                                width: 48,
                                height: 48,
                                color: widget.isDarkMode
                                    ? Colors.white10
                                    : Colors.deepPurple.shade100,
                                child: Icon(
                                  Icons.music_note,
                                  size: 24,
                                  color: widget.isDarkMode
                                      ? Colors.white54
                                      : Colors.deepPurple,
                                ),
                              ),
                              artworkHeight: 48,
                              artworkWidth: 48,
                              artworkFit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? 'Unknown Artist',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white54
                                  : Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSongSelection(song),
                            activeColor: Colors.deepPurple,
                          ),
                          onTap: () => _toggleSongSelection(song),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedSongIds.isEmpty
                        ? null
                        : _addSelectedSongs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Add ${_selectedSongIds.isEmpty ? '' : '(${_selectedSongIds.length})'}',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
