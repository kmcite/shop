import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../features/design/metro.dart';

/// Picks an item photo (camera or gallery) and copies it into the app's
/// documents directory so the path stored on the record stays valid.
abstract final class ItemPhotoStore {
  static final ImagePicker _picker = ImagePicker();

  /// Shows a camera/gallery dialog, then returns the stored file path,
  /// or null when the user cancels at any step.
  static Future<String?> pickAndStore(BuildContext context) async {
    final source = await showMetroDialog<ImageSource>(
      context: context,
      title: 'Add photo',
      message: 'Choose a source for this item.',
      actions: [
        MetroDialogAction(
          label: 'Camera',
          onPressed: () => Navigator.pop(context, ImageSource.camera),
        ),
        MetroDialogAction(
          label: 'Gallery',
          accent: true,
          onPressed: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    );
    if (source == null || !context.mounted) return null;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await _photosDir();
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = await File(picked.path).copy(
      '${dir.path}${Platform.pathSeparator}$name',
    );
    return dest.path;
  }

  static Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}item_photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
