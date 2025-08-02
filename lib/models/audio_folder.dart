class AudioFolder {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final List<String> songIds; // List of song IDs in this folder

  AudioFolder({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.songIds,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'songIds': songIds,
    };
  }

  // Create from JSON
  factory AudioFolder.fromJson(Map<String, dynamic> json) {
    return AudioFolder(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      songIds: List<String>.from(json['songIds']),
    );
  }

  // Create a copy with updated properties
  AudioFolder copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? songIds,
  }) {
    return AudioFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      songIds: songIds ?? this.songIds,
    );
  }

  // Add a song to the folder
  AudioFolder addSong(String songId) {
    if (!songIds.contains(songId)) {
      return copyWith(songIds: [...songIds, songId]);
    }
    return this;
  }

  // Remove a song from the folder
  AudioFolder removeSong(String songId) {
    return copyWith(songIds: songIds.where((id) => id != songId).toList());
  }

  // Check if folder contains a song
  bool containsSong(String songId) {
    return songIds.contains(songId);
  }

  // Get the number of songs in the folder
  int get songCount => songIds.length;
}
