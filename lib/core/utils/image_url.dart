/// Supabase Storage can resize and re-encode an image as it serves it, and it
/// negotiates WebP with the client. The originals in this project average
/// ~880 kB and run up to 14 MB, so asking for a sized copy is the difference
/// between a list screen pulling 8 MB and pulling half a megabyte.
///
/// Anything that is not a Supabase public object URL - an asset, a Google
/// avatar, a link already rendered - is handed back untouched.
String sizedImageUrl(String? url, {int width = 400, int quality = 60}) {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) return '';

  const objectPath = '/storage/v1/object/public/';
  if (!raw.contains(objectPath)) return raw;

  final rendered =
      raw.replaceFirst(objectPath, '/storage/v1/render/image/public/');
  final separator = rendered.contains('?') ? '&' : '?';
  return '$rendered${separator}width=$width&quality=$quality';
}

/// Full-bleed images on a detail screen, where the photo is the content.
String fullImageUrl(String? url) => sizedImageUrl(url, width: 1000, quality: 70);
