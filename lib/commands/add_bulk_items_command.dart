import 'dart:async';

import 'package:any/any.dart';

import '../models/bulk_purchase_line_model.dart';
import '../models/shop_item_model.dart';
import '../repositories/shop_repository.dart';
import '../states/shop_state.dart';
import 'reload_shop_data.dart';

/// Adds or restocks every line in a mixed bulk shipment, then reloads once.
class AddBulkItemsCommand extends Command {
  const AddBulkItemsCommand(this.lines);

  final List<BulkPurchaseLine> lines;

  @override
  FutureOr<void> call(Ref ref) async {
    if (lines.isEmpty) return;

    final repo = ref.get<ShopRepository>();
    final inventory = {..._indexByName(ref.of<ShopState>().items)};

    for (final line in lines) {
      final key = _nameKey(line.name);
      final existing = inventory[key];

      if (existing != null) {
        await repo.restock(
          existing,
          count: line.quantity,
          unitCost: line.costPrice,
        );
        final next = _afterRestock(existing, line);
        if (line.price != existing.price ||
            line.imagePath != existing.imagePath) {
          await repo.updateItem(next);
        }
        inventory[key] = next;
      } else {
        final id = await repo.addItem(
          name: line.name,
          price: line.price,
          costPrice: line.costPrice,
          quantity: line.quantity,
        );
        inventory[key] = ShopItem(
          id: id,
          name: line.name,
          price: line.price,
          costPrice: line.costPrice,
          quantity: line.quantity,
          imagePath: line.imagePath,
        );
      }
    }

    await reloadShopData(ref);
  }
}

ShopItem _afterRestock(ShopItem existing, BulkPurchaseLine line) {
  final newQty = existing.quantity + line.quantity;
  final newCost = existing.costPrice > 0
      ? (existing.quantity * existing.costPrice + line.quantity * line.costPrice) /
            newQty
      : line.costPrice;
  return existing.copyWith(
    quantity: newQty,
    costPrice: newCost,
    price: line.price,
    imagePath: line.imagePath ?? existing.imagePath,
  );
}

Map<String, ShopItem> _indexByName(List<ShopItem> items) {
  final map = <String, ShopItem>{};
  for (final item in items) {
    map[_nameKey(item.name)] = item;
  }
  return map;
}

String _nameKey(String name) => name.toLowerCase().trim();