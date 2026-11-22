import 'dart:typed_data';
import 'image_picker_stub.dart'
    if (dart.library.io) 'image_picker_io.dart'
    if (dart.library.js_interop) 'image_picker_web.dart';

// Picks an image file as bytes on Flutter Web or Windows Desktop
Future<Uint8List?> pickImageBytesFromDevice() => pickPlatformImageBytes();
