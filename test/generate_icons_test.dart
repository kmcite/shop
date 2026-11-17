// Dev-only asset generator: renders the app icon and splash logo to PNG
// goldens, which are then post-processed into transparent foregrounds.
// Run: flutter test --update-goldens test/generate_icons_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _teal = Color(0xFF14B8A6);

Widget _canvas({required double iconSize}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Container(
      width: 1024,
      height: 1024,
      color: _teal,
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void useSquareCanvas(WidgetTester tester) {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('launcher icon', (tester) async {
    useSquareCanvas(tester);
    await tester.pumpWidget(_canvas(iconSize: 560));
    await expectLater(
      find.byType(Container).first,
      matchesGoldenFile('goldens/icon.png'),
    );
  });

  testWidgets('splash logo', (tester) async {
    useSquareCanvas(tester);
    await tester.pumpWidget(_canvas(iconSize: 820));
    await expectLater(
      find.byType(Container).first,
      matchesGoldenFile('goldens/splash_raw.png'),
    );
  });
}
