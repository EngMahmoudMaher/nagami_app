import 'package:flutter/material.dart';
import '../models/audio_folder.dart';
import '../services/folder_service.dart';
import '../widgets/folder_tile.dart';
import '../widgets/create_folder_dialog.dart';
import 'folder_detail_page.dart';

class FolderListPage extends StatefulWidget {
  final bool isDarkMode;

  const FolderListPage({super.key, required this.isDarkMode});

  @override
  State<FolderListPage> createState() => _FolderListPageState();
}

class _FolderListPageState extends State<FolderListPage> {
  final FolderService _folderService = FolderService();
  List<AudioFolder> _folders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _testAndLoadFolders();
  }

  Future<void> _testAndLoadFolders() async {
    // Test SharedPreferences connection first
    final isSharedPrefsConnected = await _folderService.testConnection();
    debugPrint("SharedPreferences connection test: $isSharedPrefsConnected");

    // Test file storage as fallback
    final isFileStorageConnected = await _folderService.testFileStorage();
    debugPrint("File storage connection test: $isFileStorageConnected");

    if (!isSharedPrefsConnected && !isFileStorageConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage connection failed. Please restart the app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!isSharedPrefsConnected && isFileStorageConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using file storage as fallback.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    await _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _loading = true);
    try {
      final folders = await _folderService.getFolders();
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
      }
    }
  }

  Future<void> _createFolder() async {
    debugPrint("Creating folder...");
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CreateFolderDialog(isDarkMode: widget.isDarkMode),
    );

    debugPrint("Dialog result: $result");

    if (result != null) {
      final name = result['name']!;
      final description = result['description']!;

      debugPrint("Folder name: $name, description: $description");

      // Check if folder name already exists
      final exists = await _folderService.isFolderNameExists(name);
      debugPrint("Folder exists: $exists");

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A folder with this name already exists'),
            ),
          );
        }
        return;
      }

      // Create new folder
      final newFolder = AudioFolder(
        id: _folderService.generateFolderId(),
        name: name,
        description: description.isEmpty ? null : description,
        createdAt: DateTime.now(),
        songIds: [],
      );

      debugPrint("New folder: ${newFolder.toJson()}");

      try {
        await _folderService.addFolder(newFolder);
        debugPrint("Folder added successfully");
        await _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder "${name}" created successfully')),
          );
        }
      } catch (e) {
        debugPrint("Error creating folder: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating folder: $e')));
        }
      }
    } else {
      debugPrint("Dialog was cancelled or returned null");
    }
  }

  Future<void> _deleteFolder(AudioFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Delete Folder',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${folder.name}"? This action cannot be undone.',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _folderService.deleteFolder(folder.id);
        await _loadFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Folder "${folder.name}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting folder: $e')));
        }
      }
    }
  }

  void _openFolder(AudioFolder folder) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                FolderDetailPage(folder: folder, isDarkMode: widget.isDarkMode),
          ),
        )
        .then((_) => _loadFolders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'My Folders',
          style: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.deepPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Debug button to restart connection
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.blue),
            onPressed: () async {
              await _folderService.restartConnection();
              await _testAndLoadFolders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connection restarted')),
                );
              }
            },
          ),
          // Debug button to clear data
          IconButton(
            icon: Icon(Icons.bug_report_rounded, color: Colors.orange),
            onPressed: () async {
              await _folderService.clearAllData();
              await _loadFolders();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data cleared for testing')),
                );
              }
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _folders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 80,
                    color: widget.isDarkMode
                        ? Colors.white54
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Folders Yet',
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
                    'Create your first folder to organize your music',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white54
                          : Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createFolder,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Folder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _folders.length,
              itemBuilder: (context, index) => FolderTile(
                folder: _folders[index],
                onTap: () => _openFolder(_folders[index]),
                onDelete: () => _deleteFolder(_folders[index]),
                isDarkMode: widget.isDarkMode,
              ),
            ),
      floatingActionButton: _folders.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createFolder,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
