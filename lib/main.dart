import 'package:flutter/material.dart';
import 'package:shop/business/shop_providers.dart';

import 'features/app/app_router.dart';
import 'features/app/shop_application.dart';

void main() {
  final router = AppRouter();
  runApp(
    ShopScope(
      router: router,
      child: ShopApplication(router: router),
    ),
  );
}
