import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressHelper {
  /// Compresses and converts an image to PNG format.
  /// Returns a new [File] in PNG format.
  static Future<File?> compressAndConvertToPng(File file) async {
    try {
      print("DEBUG [ImageCompress]: Starting compression for ${file.path}");
      final String dir = (await getTemporaryDirectory()).path;
      final String targetPath = p.join(
        dir,
        "${DateTime.now().millisecondsSinceEpoch}.png",
      );

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.png,
        quality: 80, // Adjust quality as needed
      );

      if (result != null) {
        print("DEBUG [ImageCompress]: Compression successful. New file: ${result.path}");
        print("DEBUG [ImageCompress]: Original size: ${await file.length()} bytes, New size: ${await result.length()} bytes");
        return File(result.path);
      }
      print("DEBUG [ImageCompress]: Compression failed - result is null");
      return null;
    } catch (e) {
      print("DEBUG [ImageCompress]: Error compressing image: $e");
      return null;
    }
  }
}
