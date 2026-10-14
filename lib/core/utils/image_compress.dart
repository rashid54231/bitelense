import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Image compression utility targeting <= 1280px longest side, ~80 JPEG quality,
/// ensuring photos are well under the 1.5MB - 5MB limits before uploading.
class ImageCompressUtil {
  ImageCompressUtil._();

  static const int maxDimension = 1280;
  static const int defaultQuality = 80;

  /// Compresses a file at [inputPath] and returns the compressed [File].
  /// Returns original file if compression is unsupported or fails.
  static Future<File> compressMealPhoto(String inputPath) async {
    try {
      final inputFile = File(inputPath);
      if (!inputFile.existsSync()) {
        return inputFile;
      }

      final originalSize = await inputFile.length();
      // If already under 800 KB, no heavy compression needed
      if (originalSize < 800 * 1024) {
        return inputFile;
      }

      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        inputFile.absolute.path,
        targetPath,
        quality: defaultQuality,
        minWidth: maxDimension,
        minHeight: maxDimension,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return inputFile;
    } catch (e) {
      debugPrint('Image compression fallback used: $e');
      return File(inputPath);
    }
  }
}
