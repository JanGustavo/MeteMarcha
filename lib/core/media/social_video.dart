class SocialVideo {
  const SocialVideo(this.original, this.player, this.provider);
  final Uri original;
  final Uri player;
  final String provider;
  static SocialVideo? parse(String raw) {
    final match = RegExp(r'https?://[^\s<>]+').firstMatch(raw.trim());
    final uri = Uri.tryParse(match?.group(0) ?? raw.trim());
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty)
      return null;
    final host = uri.host.toLowerCase();
    final parts = uri.pathSegments;
    String? id;
    if (host == 'youtu.be') {
      if (parts.isNotEmpty) id = parts.first;
    }
    if ([
      'youtube.com',
      'www.youtube.com',
      'm.youtube.com',
      'youtube-nocookie.com',
      'www.youtube-nocookie.com'
    ].contains(host)) {
      id = uri.queryParameters['v'];
      if (parts.length >= 2 &&
          ['shorts', 'embed', 'live'].contains(parts.first)) id = parts[1];
    }
    if (id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id))
      return SocialVideo(
          Uri.https('www.youtube.com', '/watch', {'v': id}),
          Uri.https('www.youtube.com', '/embed/$id', {
            'playsinline': '1',
            'controls': '1',
            'rel': '0',
            'origin': 'https://api.metemarcha.jangustavo.me'
          }),
          'YouTube');
    if (host == 'tiktok.com' || host.endsWith('.tiktok.com')) {
      final index = parts.indexOf('video');
      if (index >= 0 &&
          parts.length > index + 1 &&
          RegExp(r'^\d{10,30}$').hasMatch(parts[index + 1]))
        return SocialVideo(
            uri,
            Uri.https('www.tiktok.com', '/player/v1/${parts[index + 1]}',
                {'controls': '1', 'autoplay': '0'}),
            'TikTok');
      if (['vm.tiktok.com', 'vt.tiktok.com'].contains(host))
        return SocialVideo(uri, uri, 'TikTok');
    }
    if (['instagram.com', 'www.instagram.com'].contains(host) &&
        parts.length >= 2 &&
        ['p', 'reel', 'reels', 'tv'].contains(parts[0]) &&
        RegExp(r'^[\w-]{3,100}$').hasMatch(parts[1]))
      return SocialVideo(
          uri,
          Uri.https('www.instagram.com', '/${parts[0]}/${parts[1]}/embed/'),
          'Instagram');
    if (['kwai.com', 'www.kwai.com', 'k.kwai.com', 's.kwai.app']
            .contains(host) &&
        parts.isNotEmpty) return SocialVideo(uri, uri, 'Kwai');
    return null;
  }

  bool get isFrame =>
      provider != 'Kwai' &&
      !['vm.tiktok.com', 'vt.tiktok.com'].contains(player.host);
}
