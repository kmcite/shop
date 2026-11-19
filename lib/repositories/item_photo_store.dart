import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks an item photo (camera or gallery) and copies it into the app's
/// documents directory so the path stored on the record stays valid.
abstract final class ItemPhotoStore {
  static final ImagePicker _picker = ImagePicker();

  /// Shows a camera/gallery chooser, then returns the stored file path,
  /// or null when the user cancels at any step.
  static Future<String?> pickAndStore(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
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
