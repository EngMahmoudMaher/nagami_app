import 'package:flutter/material.dart';
import '../models/audio_folder.dart';

class FolderTile extends StatelessWidget {
  final AudioFolder folder;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isDarkMode;

  const FolderTile({
    super.key,
    required this.folder,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: Colors.deepPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (folder.description != null &&
                          folder.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            folder.description!,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.music_note_rounded,
                              size: 16,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${folder.songCount} song${folder.songCount == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(folder.createdAt),
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
