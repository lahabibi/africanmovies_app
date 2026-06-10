String resolvePlayableVideoUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) return '';

  final parsed = Uri.tryParse(value);
  if (parsed == null || !parsed.hasScheme) {
    return _looksLikeCloudflareUid(value)
        ? _cloudflareManifestUrl(videoUid: value)
        : value;
  }

  if (_isDirectMediaUrl(parsed)) return value;

  final cloudflareUid = _cloudflareStreamUid(parsed);
  if (cloudflareUid == null) return value;

  final manifestHost = _cloudflareManifestHost(parsed);

  return _cloudflareManifestUrl(
    videoUid: cloudflareUid,
    host: manifestHost,
    query: parsed.query,
  );
}

String resolveDashVideoUrl(String rawUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) return '';

  final parsed = Uri.tryParse(value);
  if (parsed == null || !parsed.hasScheme) {
    return _looksLikeCloudflareUid(value)
        ? _cloudflareManifestUrl(videoUid: value, manifestFile: 'video.mpd')
        : value;
  }

  final cloudflareUid = _cloudflareStreamUid(parsed);
  if (cloudflareUid == null) {
    return _isCloudflareManifestUrl(parsed)
        ? _replaceCloudflareManifestFile(parsed, 'video.mpd')
        : value;
  }

  return _cloudflareManifestUrl(
    videoUid: cloudflareUid,
    host: _cloudflareManifestHost(parsed),
    query: parsed.query,
    manifestFile: 'video.mpd',
  );
}

bool _isDirectMediaUrl(Uri uri) {
  final path = uri.path.toLowerCase();

  if (path.contains('/manifest/')) return true;

  return const [
    '.m3u8',
    '.mpd',
    '.mp4',
    '.mov',
    '.m4v',
    '.mkv',
    '.webm',
  ].any(path.endsWith);
}

String? _cloudflareStreamUid(Uri uri) {
  final host = uri.host.toLowerCase();
  if (!_isCloudflareStreamHost(host)) return null;

  final segments = uri.pathSegments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();

  if (segments.isEmpty || segments.contains('manifest')) return null;

  if (segments.first == 'iframe' && segments.length > 1) {
    return segments[1];
  }

  return segments.first;
}

bool _isCloudflareStreamHost(String host) {
  return host == 'videodelivery.net' ||
      host.endsWith('.videodelivery.net') ||
      host.endsWith('.cloudflarestream.com');
}

bool _isCloudflareManifestUrl(Uri uri) {
  return _isCloudflareStreamHost(uri.host.toLowerCase()) &&
      uri.pathSegments.contains('manifest');
}

String _cloudflareManifestHost(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'iframe.videodelivery.net' ? 'videodelivery.net' : host;
}

String _cloudflareManifestUrl({
  required String videoUid,
  String host = 'videodelivery.net',
  String query = '',
  String manifestFile = 'video.m3u8',
}) {
  return Uri(
    scheme: 'https',
    host: host,
    pathSegments: [videoUid, 'manifest', manifestFile],
    query: query.isEmpty ? null : query,
  ).toString();
}

String _replaceCloudflareManifestFile(Uri uri, String manifestFile) {
  final segments = uri.pathSegments.toList();
  if (segments.isEmpty) return uri.toString();

  segments[segments.length - 1] = manifestFile;

  return uri.replace(pathSegments: segments).toString();
}

bool _looksLikeCloudflareUid(String value) {
  return RegExp(r'^[A-Za-z0-9_-]{20,}$').hasMatch(value);
}
