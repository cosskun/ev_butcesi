import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  static final ImagePicker _picker = ImagePicker();

  /// Take receipt photo with camera
  static Future<String?> captureReceiptPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (photo == null) return null;
      return await _saveImageLocally(photo);
    } catch (e) {
      return null;
    }
  }

  /// Pick receipt photo from gallery
  static Future<String?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) return null;
      return await _saveImageLocally(image);
    } catch (e) {
      return null;
    }
  }

  /// Copy image to app's persistent documents directory or return web path
  static Future<String> _saveImageLocally(XFile imageFile) async {
    if (kIsWeb) {
      return imageFile.path;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final ext = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path)
        : '.jpg';
    final fileName = 'receipt_${const Uuid().v4()}$ext';
    final savedFile = await File(imageFile.path).copy(
      p.join(receiptsDir.path, fileName),
    );

    return savedFile.path;
  }
}
