import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NowPlayingBar extends StatelessWidget {
  final SongModel? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback? onPlay;
  final VoidCallback onPause;
  final ValueChanged<double> onSeek;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const NowPlayingBar({
    super.key,
    required this.currentSong,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    this.onTap,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (currentSong == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[850]!, Colors.grey[900]!]
                : [Colors.white, Colors.grey[50]!],
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
            BoxShadow(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Enhanced album art
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QueryArtworkWidget(
                  id: currentSong!.id,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade200,
                          Colors.deepPurple.shade400,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  artworkHeight: 60,
                  artworkWidth: 60,
                  artworkFit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentSong!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentSong!.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Enhanced mini slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.deepPurple,
                      inactiveTrackColor: isDarkMode
                          ? Colors.white24
                          : Colors.grey[300],
                      thumbColor: Colors.deepPurple,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inMilliseconds.toDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      value: position.inMilliseconds
                          .clamp(0, duration.inMilliseconds)
                          .toDouble(),
                      onChanged: onSeek,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Enhanced play button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: isPlaying ? onPause : onPlay,
                  child: Center(
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
