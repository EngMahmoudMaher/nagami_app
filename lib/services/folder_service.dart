import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audio_folder.dart';

class FolderService {
  static const String _foldersKey = 'audio_folders';
  SharedPreferences? _prefs;
  bool _initializing = false;

  // Initialize SharedPreferences with retry mechanism
  Future<void> _initPrefs() async {
    if (_prefs != null) return;
    if (_initializing) return;

    _initializing = true;
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          "Attempting to initialize SharedPreferences (attempt ${retryCount + 1})",
        );
        _prefs = await SharedPreferences.getInstance();
        debugPrint("SharedPreferences initialized successfully");
        _initializing = false;
        return;
      } catch (e) {
        retryCount++;
        debugPrint(
          "Error initializing SharedPreferences (attempt $retryCount): $e",
        );

        if (retryCount >= maxRetries) {
          _initializing = false;
          throw Exception(
            "Failed to initialize SharedPreferences after $maxRetries attempts: $e",
          );
        }

        // Wait a bit before retrying
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  // Get all folders
  Future<List<AudioFolder>> getFolders() async {
    try {
      await _initPrefs();
      final foldersJson = _prefs!.getStringList(_foldersKey) ?? [];

      debugPrint(
        "Loading ${foldersJson.length} folders from SharedPreferences",
      );

      final folders = foldersJson
          .map((json) => AudioFolder.fromJson(jsonDecode(json)))
          .toList();

      debugPrint("Loaded ${folders.length} folders from SharedPreferences");
      return folders;
    } catch (e) {
      debugPrint(
        "Error loading from SharedPreferences: $e, trying file fallback",
      );
      return await _loadFromFile();
    }
  }

  // Save all folders
  Future<void> saveFolders(List<AudioFolder> folders) async {
    try {
      await _initPrefs();
      debugPrint("Saving ${folders.length} folders to SharedPreferences");

      final foldersJson = folders
          .map((folder) => jsonEncode(folder.toJson()))
          .toList();

      await _prefs!.setStringList(_foldersKey, foldersJson);
      debugPrint("Folders saved to SharedPreferences successfully");
    } catch (e) {
      debugPrint("Error saving to SharedPreferences: $e, using file fallback");
      await _saveToFile(folders);
    }
  }

  // Add a new folder
  Future<void> addFolder(AudioFolder folder) async {
    debugPrint("Adding folder: ${folder.toJson()}");
    final folders = await getFolders();
    debugPrint("Current folders count: ${folders.length}");
    folders.add(folder);
    await saveFolders(folders);
    debugPrint("Folder added successfully");
  }

  // Update an existing folder
  Future<void> updateFolder(AudioFolder updatedFolder) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == updatedFolder.id);

    if (index != -1) {
      folders[index] = updatedFolder;
      await saveFolders(folders);
    }
  }

  // Delete a folder
  Future<void> deleteFolder(String folderId) async {
    final folders = await getFolders();
    folders.removeWhere((f) => f.id == folderId);
    await saveFolders(folders);
  }

  // Add a song to a folder
  Future<void> addSongToFolder(String folderId, String songId) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == folderId);

    if (index != -1) {
      folders[index] = folders[index].addSong(songId);
      await saveFolders(folders);
    }
  }

  // Remove a song from a folder
  Future<void> removeSongFromFolder(String folderId, String songId) async {
    final folders = await getFolders();
    final index = folders.indexWhere((f) => f.id == folderId);

    if (index != -1) {
      folders[index] = folders[index].removeSong(songId);
      await saveFolders(folders);
    }
  }

  // Get songs in a folder
  Future<List<String>> getSongsInFolder(String folderId) async {
    final folders = await getFolders();
    final folder = folders.firstWhere(
      (f) => f.id == folderId,
      orElse: () =>
          AudioFolder(id: '', name: '', createdAt: DateTime.now(), songIds: []),
    );

    return folder.songIds;
  }

  // Get folders containing a specific song
  Future<List<AudioFolder>> getFoldersContainingSong(String songId) async {
    final folders = await getFolders();
    return folders.where((folder) => folder.containsSong(songId)).toList();
  }

  // Generate a unique folder ID
  String generateFolderId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Check if a folder name already exists
  Future<bool> isFolderNameExists(String name) async {
    final folders = await getFolders();
    return folders.any(
      (folder) => folder.name.toLowerCase() == name.toLowerCase(),
    );
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      // Clear SharedPreferences
      await _initPrefs();
      await _prefs!.remove(_foldersKey);
      debugPrint("SharedPreferences data cleared");
    } catch (e) {
      debugPrint("Error clearing SharedPreferences: $e");
    }

    try {
      // Clear file storage
      final file = await _getFoldersFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint("File storage data cleared");
      }
    } catch (e) {
      debugPrint("Error clearing file storage: $e");
    }
  }

  // Test SharedPreferences connection
  Future<bool> testConnection() async {
    try {
      await _initPrefs();
      await _prefs!.setString('test_key', 'test_value');
      final testValue = _prefs!.getString('test_key');
      await _prefs!.remove('test_key');
      debugPrint("SharedPreferences test successful: $testValue");
      return testValue == 'test_value';
    } catch (e) {
      debugPrint("SharedPreferences test failed: $e");
      return false;
    }
  }

  // Test file storage connection
  Future<bool> testFileStorage() async {
    try {
      final file = await _getFoldersFile();
      await file.writeAsString('test');
      final content = await file.readAsString();
      await file.delete();
      debugPrint("File storage test successful");
      return content == 'test';
    } catch (e) {
      debugPrint("File storage test failed: $e");
      return false;
    }
  }

  // Force restart SharedPreferences connection
  Future<void> restartConnection() async {
    _prefs = null;
    _initializing = false;
    debugPrint("SharedPreferences connection reset");
  }

  // Fallback file-based storage
  Future<File> _getFoldersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/audio_folders.json');
  }

  Future<void> _saveToFile(List<AudioFolder> folders) async {
    try {
      final file = await _getFoldersFile();
      final jsonData = folders.map((folder) => folder.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonData));
      debugPrint("Folders saved to file successfully");
    } catch (e) {
      debugPrint("Error saving to file: $e");
    }
  }

  Future<List<AudioFolder>> _loadFromFile() async {
    try {
      final file = await _getFoldersFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as List;
      return jsonData.map((json) => AudioFolder.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error loading from file: $e");
      return [];
    }
  }
}
