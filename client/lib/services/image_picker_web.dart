import 'dart:typed_data';

Future<Uint8List?> pickPlatformImageBytes() async {
  // On web, caller falls back to capturing the live garment preview canvas as PNG bytes
  return null;
}
