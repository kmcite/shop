import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import '../states/shop_state.dart';

/// Reads the latest inventory and sales from the repository into [ShopState].
Future<void> reloadShopData(Ref ref) async {
  final shopRepository = ref.get<ShopRepository>();
  final items = await shopRepository.getItems();
  final sales = await shopRepository.getSales();
  final bulks = await shopRepository.getBulkShipments();

  ref<ShopState>(
    (s) => s.copyWith(
      items: items,
      bulkShipments: bulks,
      sales: sales,
      isLoading: false,
      error: null,
    ),
  );
}
