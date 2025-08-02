import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isDarkMode;

  const SongTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    this.onTap,
    this.onRemove,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: QueryArtworkWidget(
          id: song.id,
          type: ArtworkType.AUDIO,
          nullArtworkWidget: Container(
            width: 48,
            height: 48,
            color: isDarkMode ? Colors.white10 : Colors.deepPurple.shade100,
            child: Icon(
              Icons.music_note,
              size: 32,
              color: isDarkMode ? Colors.white54 : Colors.deepPurple,
            ),
          ),
          artworkHeight: 48,
          artworkWidth: 48,
          artworkFit: BoxFit.cover,
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        song.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRemove != null)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
              onPressed: onRemove,
            ),
          IconButton(
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: Colors.deepPurple,
              size: 30,
            ),
            onPressed: isPlaying ? onPause : onPlay,
          ),
        ],
      ),
      onTap: onTap ?? onPlay,
      selected: isCurrent,
      selectedTileColor: isDarkMode
          ? Colors.white.withOpacity(0.08)
          : Colors.deepPurple.withOpacity(0.08),
    );
  }
}
