import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicControlSheet extends StatelessWidget {
  final SongModel song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final ValueChanged<double> onSeek;
  final AudioPlayer player;
  final ScrollController scrollController;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onShuffle;
  final VoidCallback? onRepeat;
  final bool isShuffling;
  final LoopMode loopMode;
  final VoidCallback? onToggleDarkMode;
  final bool isDarkMode;

  const MusicControlSheet({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    required this.player,
    required this.scrollController,
    this.onNext,
    this.onPrevious,
    this.onShuffle,
    this.onRepeat,
    this.isShuffling = false,
    this.loopMode = LoopMode.off,
    this.onToggleDarkMode,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.black]
              : [Colors.grey[50]!, Colors.white],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced drag handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white38 : Colors.grey[400],
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode ? Colors.white10 : Colors.black,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Enhanced album art with shadow and glow
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: isDarkMode ? Colors.black54 : Colors.black12,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
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
                    child: const Center(
                      child: Image(
                        image: AssetImage('assets/logo.jpg'),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Enhanced song title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: isDarkMode ? Colors.black26 : Colors.white70,
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Enhanced artist name
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  song.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Enhanced progress section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  initialData: position,
                  builder: (context, snapshot) {
                    final pos = snapshot.data ?? Duration.zero;
                    return Column(
                      children: [
                        // Custom styled slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.deepPurple,
                            inactiveTrackColor: isDarkMode
                                ? Colors.white24
                                : Colors.grey[300],
                            thumbColor: Colors.deepPurple,
                            overlayColor: Colors.deepPurple.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            min: 0,
                            max: duration.inMilliseconds.toDouble().clamp(
                              1,
                              double.infinity,
                            ),
                            value: pos.inMilliseconds
                                .clamp(0, duration.inMilliseconds)
                                .toDouble(),
                            onChanged: onSeek,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Enhanced time display
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white10
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDuration(pos),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white10
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Enhanced control buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle button
                    _buildControlButton(
                      icon: Icons.shuffle,
                      isActive: isShuffling,
                      onPressed: onShuffle,
                      tooltip: 'Shuffle',
                    ),
                    // Previous button
                    _buildControlButton(
                      icon: Icons.skip_previous,
                      size: 32,
                      onPressed: onPrevious != null
                          ? () => onPrevious!()
                          : null,
                      tooltip: 'Previous',
                    ),
                    // Play/Pause button (enhanced)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.deepPurple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: isDarkMode ? Colors.black26 : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: isPlaying ? onPause : onPlay,
                          child: Center(
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Next button
                    _buildControlButton(
                      icon: Icons.skip_next,
                      size: 32,
                      onPressed: onNext != null ? () => onNext!() : null,
                      tooltip: 'Next',
                    ),
                    // Repeat button
                    _buildControlButton(
                      icon: loopMode == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      isActive: loopMode != LoopMode.off,
                      onPressed: onRepeat,
                      tooltip: 'Repeat',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    double size = 28,
    bool isActive = false,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.deepPurple.withOpacity(0.2)
            : (isDarkMode ? Colors.white10 : Colors.grey[100]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive
              ? Colors.deepPurple.withOpacity(0.3)
              : (isDarkMode ? Colors.white12 : Colors.grey[300]!),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: size,
              color: isActive
                  ? Colors.deepPurple
                  : (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Image(image: AssetImage('assets/logo.jpg'), fit: BoxFit.fill),
      ),
    );
  }
}
