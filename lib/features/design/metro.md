# Shop Metro

UI is powered by [`metro_ui`](https://pub.dev/packages/metro_ui) plus shop-only chrome in this folder.

```dart
import 'package:shop/features/design/metro.dart';
// or
import 'package:metro_ui/metro_ui.dart';
```

- Theme: `MetroTheme` is applied in `ShopApplication` (`MetroColors.cyan` accent).
- Package widgets: buttons, fields, toggles, progress, lists, dialogs, tiles, etc.
- Shop-only: `MetroBottomApplicationBar`, `MetroRefresh`, `MetroPanoramaView`,
  `MetroPanel` / `MetroHeader` / `MetroTag` / `MetroBadge` / `MetroEmptyState` /
  `MetroListRow` / `MetroToggleTile` / `ShopMetroTypography`.
