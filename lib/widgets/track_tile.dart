import 'package:flutter/material.dart';

import '../models/track.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.trailing,
    required this.onTap,
  });

  final Track track;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_note_outlined),
      title: Text(track.title),
      subtitle: _buildSubtitle(),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[
      if (track.artist != null && track.artist!.isNotEmpty) track.artist!,
      if (track.album != null && track.album!.isNotEmpty) track.album!,
    ];
    if (parts.isEmpty) return null;
    return Text(parts.join(' • '));
  }
}
