import 'package:flutter/material.dart';

import '../models/jellyfin_item.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.item,
    this.trailing,
    required this.onTap,
  });

  final JellyfinItem item;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_note_outlined),
      title: Text(item.displayName),
      subtitle: _buildSubtitle(),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[
      if (item.artist != null && item.artist!.isNotEmpty) item.artist!,
      if (item.album != null && item.album!.isNotEmpty) item.album!,
    ];
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }
}
