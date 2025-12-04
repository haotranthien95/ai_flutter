import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Image helper utilities for picking and compressing images.
class ImageHelper {
  ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery.
  ///
  /// Returns the file path if successful, null if cancelled or failed.
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from camera.
  ///
  /// Returns the file path if successful, null if cancelled or failed.
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  /// Pick multiple images from gallery.
  ///
  /// Returns a list of file paths. Empty list if cancelled or failed.
  /// [maxImages] limits the number of images that can be selected (default 5).
  static Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      // Limit to maxImages
      final List<XFile> limitedImages = images.take(maxImages).toList();

      return limitedImages.map((XFile image) => File(image.path)).toList();
    } catch (e) {
      return <File>[];
    }
  }

  /// Compress an image file.
  ///
  /// Reduces file size by compressing the image while maintaining quality.
  /// [targetSizeMB] is the target file size in megabytes (default 1 MB).
  /// [quality] is the compression quality (1-100, default 85).
  static Future<File?> compressImage(
    File imageFile, {
    double targetSizeMB = 1.0,
    int quality = 85,
  }) async {
    try {
      final int targetSizeBytes = (targetSizeMB * 1024 * 1024).toInt();
      final int currentSize = await imageFile.length();

      // If already under target size, return original
      if (currentSize <= targetSizeBytes) {
        return imageFile;
      }

      // Generate output path
      final String outputPath =
          imageFile.path.replaceAll('.jpg', '_compressed.jpg');

      // Compress image
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        outputPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (compressedFile == null) return null;

      return File(compressedFile.path);
    } catch (e) {
      return null;
    }
  }

  /// Compress multiple images.
  ///
  /// Returns a list of compressed image files.
  static Future<List<File>> compressMultipleImages(
    List<File> imageFiles, {
    double targetSizeMB = 1.0,
    int quality = 85,
  }) async {
    final List<File> compressedFiles = <File>[];

    for (final File imageFile in imageFiles) {
      final File? compressed = await compressImage(
        imageFile,
        targetSizeMB: targetSizeMB,
        quality: quality,
      );

      if (compressed != null) {
        compressedFiles.add(compressed);
      }
    }

    return compressedFiles;
  }

  /// Get image file size in megabytes.
  static Future<double> getImageSizeMB(File imageFile) async {
    final int bytes = await imageFile.length();
    return bytes / (1024 * 1024);
  }

  /// Check if image file size is within limit.
  ///
  /// [maxSizeMB] is the maximum allowed size in megabytes (default 5 MB).
  static Future<bool> isImageSizeValid(File imageFile,
      {double maxSizeMB = 5.0}) async {
    final double sizeMB = await getImageSizeMB(imageFile);
    return sizeMB <= maxSizeMB;
  }

  /// Delete an image file.
  ///
  /// Returns true if successful.
  static Future<bool> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete multiple image files.
  ///
  /// Returns the number of successfully deleted files.
  static Future<int> deleteMultipleImages(List<File> imageFiles) async {
    int deletedCount = 0;

    for (final File imageFile in imageFiles) {
      final bool deleted = await deleteImage(imageFile);
      if (deleted) deletedCount++;
    }

    return deletedCount;
  }
}
