import 'package:flutter/material.dart';

class Mood {
  final String? id; // Firestore document ID (null for default moods)
  final String name; // e.g., 'happy', 'sad', 'custom_mood'
  final String label; // Display label e.g., 'Happy', 'Sad'
  final String colorHex; // Color as hex string
  final bool isDefault; // Whether it's a default mood
  final String? userId; // Owner of custom mood

  Mood({
    this.id,
    required this.name,
    required this.label,
    required this.colorHex,
    this.isDefault = false,
    this.userId,
  });

  // Default moods
  static final List<Mood> defaultMoods = [
    Mood(
      name: 'happy',
      label: 'Happy',
      colorHex: 'FFFDD835',
      isDefault: true,
    ),
    Mood(
      name: 'sad',
      label: 'Sad',
      colorHex: 'FF42A5F5',
      isDefault: true,
    ),
    Mood(
      name: 'angry',
      label: 'Angry',
      colorHex: 'FFEF5350',
      isDefault: true,
    ),
    Mood(
      name: 'excited',
      label: 'Excited',
      colorHex: 'FFAB47BC',
      isDefault: true,
    ),
    Mood(
      name: 'calm',
      label: 'Calm',
      colorHex: 'FF66BB6A',
      isDefault: true,
    ),
  ];

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'label': label,
      'colorHex': colorHex,
      'isDefault': isDefault,
      if (userId != null) 'userId': userId,
    };
  }

  // Create from Firestore document
  factory Mood.fromFirestore(String id, Map<String, dynamic> data) {
    return Mood(
      id: id,
      name: data['name'] ?? '',
      label: data['label'] ?? '',
      colorHex: data['colorHex'] ?? 'FF9E9E9E',
      isDefault: data['isDefault'] ?? false,
      userId: data['userId'],
    );
  }

  // Get Color from hex
  Color get color {
    String hex = colorHex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Copy with method
  Mood copyWith({
    String? id,
    String? name,
    String? label,
    String? colorHex,
    bool? isDefault,
    String? userId,
  }) {
    return Mood(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      userId: userId ?? this.userId,
    );
  }
}
