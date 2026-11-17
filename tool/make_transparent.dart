// Dev-only: converts the teal-background goldens into transparent PNGs
// for the adaptive icon foreground and the native splash logo.
// The storefront glyph is white; teal is (20,184,166). Per-pixel alpha is
// derived from the min channel, which approximates white coverage.
// Run: dart run tool/make_transparent.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  _convert('test/goldens/icon.png', 'assets/icon_foreground.png');
  _convert('test/goldens/splash_raw.png', 'assets/splash.png');
}

void _convert(String src, String dst) {
  final image = img.decodePng(File(src).readAsBytesSync());
  if (image == null) throw StateError('Could not decode $src');

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final minChannel = [p.r.toInt(), p.g.toInt(), p.b.toInt()].reduce(
        (a, b) => a < b ? a : b,
      );
      // Teal min channel is 20, white is 255.
      final alpha = ((minChannel - 20) / 235 * 255).round().clamp(0, 255);
      image.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), alpha);
    }
  }

  File(dst).parent.createSync(recursive: true);
  File(dst).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $dst');
}
