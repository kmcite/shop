import 'package:material_ui/material_ui.dart';
import 'package:shop/business/shop_providers.dart';

import 'features/app/shop_application.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();
  runApp(
    ShopProviders(
      navigatorKey: navigatorKey,
      child: ShopApplication(navigatorKey: navigatorKey),
    ),
  );
}