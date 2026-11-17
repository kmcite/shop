import 'dart:async';

import 'package:any/any.dart';

import '../models/bulk_purchase_line_model.dart';
import '../models/bulk_shipment_line_model.dart';
import '../models/bulk_shipment_model.dart';
import '../repositories/shop_repository.dart';
import '../states/bulk_order_draft_state.dart';
import '../states/shop_state.dart';
import 'add_bulk_items_command.dart';
import 'bulk_order_draft_commands.dart';
import 'reload_shop_data.dart';

/// Creates a new bulk in `ordered` status from the order draft.
class SaveNewBulkOrderCommand extends Command {
  const SaveNewBulkOrderCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    final draft = ref.of<BulkOrderDraftState>();
    final seller = draft.sellerLabel.trim();
    final price = draft.parsedAgreedPrice;
    final quality = draft.qualityNotes.trim();

    if (seller.isEmpty) {
      await SetBulkDraftErrorCommand('Who is the seller?').call(ref);
      return;
    }
    if (price == null || price <= 0) {
      await SetBulkDraftErrorCommand('Enter the agreed bulk price.').call(ref);
      return;
    }
    if (quality.isEmpty) {
      await SetBulkDraftErrorCommand('Describe the promised quality.').call(ref);
      return;
    }
    if (draft.lines.isEmpty) {
      await SetBulkDraftErrorCommand(
        'Add at least one expected item type.',
      ).call(ref);
      return;
    }

    final repo = ref.get<ShopRepository>();
    await repo.saveBulkShipment(
      BulkShipment(
        id: '',
        sellerLabel: seller,
        agreedPrice: price,
        qualityNotes: quality,
        status: BulkShipmentStatus.ordered,
        lines: draft.lines,
        createdAt: DateTime.now(),
      ),
    );
    await reloadShopData(ref);
    await ResetBulkOrderDraftCommand().call(ref);
  }
}

class SaveBulkReceivedCommand extends Command {
  const SaveBulkReceivedCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final draft = ref.of<BulkOrderDraftState>();
    final delivery = draft.parsedDeliveryCharge ?? 0;
    if (delivery < 0) {
      await SetBulkDraftErrorCommand('Delivery charge cannot be negative.')
          .call(ref);
      return;
    }

    final repo = ref.get<ShopRepository>();
    final bulk = await repo.getBulkShipment(shipmentId);
    if (bulk == null) {
      await SetBulkDraftErrorCommand('Bulk not found.').call(ref);
      return;
    }
    if (bulk.status != BulkShipmentStatus.ordered) {
      await SetBulkDraftErrorCommand(
        'This bulk is not waiting to be received.',
      ).call(ref);
      return;
    }

    await repo.saveBulkShipment(
      bulk.copyWith(
        deliveryCharge: delivery,
        status: BulkShipmentStatus.received,
        receivedAt: DateTime.now(),
      ),
    );
    await reloadShopData(ref);
  }
}

class SaveBulkCountedCommand extends Command {
  const SaveBulkCountedCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final draft = ref.of<BulkOrderDraftState>();
    final lines = draft.lines;
    if (lines.isEmpty) {
      await SetBulkDraftErrorCommand('Count at least one item type.').call(ref);
      return;
    }
    for (final line in lines) {
      if (line.name.trim().isEmpty || (line.actualQty ?? 0) < 1) {
        await SetBulkDraftErrorCommand(
          'Every row needs a name and quantity of at least 1.',
        ).call(ref);
        return;
      }
    }

    final repo = ref.get<ShopRepository>();
    final bulk = await repo.getBulkShipment(shipmentId);
    if (bulk == null) {
      await SetBulkDraftErrorCommand('Bulk not found.').call(ref);
      return;
    }
    if (bulk.status != BulkShipmentStatus.received) {
      await SetBulkDraftErrorCommand('Open and count this bulk first.').call(ref);
      return;
    }

    await repo.saveBulkShipment(
      bulk.copyWith(
        lines: lines,
        status: BulkShipmentStatus.counted,
        countedAt: DateTime.now(),
      ),
    );
    await reloadShopData(ref);
  }
}

class SaveBulkPricedCommand extends Command {
  const SaveBulkPricedCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final draft = ref.of<BulkOrderDraftState>();
    final bulk = await ref.get<ShopRepository>().getBulkShipment(shipmentId);
    if (bulk == null) {
      await SetBulkDraftErrorCommand('Bulk not found.').call(ref);
      return;
    }
    if (bulk.status != BulkShipmentStatus.counted) {
      await SetBulkDraftErrorCommand(
        'Finish counting before setting listing prices.',
      ).call(ref);
      return;
    }

    final defaultCost = bulk.defaultUnitCost;
    final updated = <BulkShipmentLine>[];

    for (final line in draft.lines) {
      final price = line.listPrice;
      if (price == null || price <= 0) {
        await SetBulkDraftErrorCommand(
          'Set a listing price for every item type.',
        ).call(ref);
        return;
      }
      updated.add(line.copyWith(unitCost: line.unitCost ?? defaultCost));
    }

    await ref.get<ShopRepository>().saveBulkShipment(
          bulk.copyWith(
            lines: updated,
            status: BulkShipmentStatus.priced,
            pricedAt: DateTime.now(),
          ),
        );
    await reloadShopData(ref);
  }
}

/// Moves priced bulk lines into shop inventory and marks the bulk complete.
class FinalizeBulkShipmentCommand extends Command {
  const FinalizeBulkShipmentCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final repo = ref.get<ShopRepository>();
    final bulk = await repo.getBulkShipment(shipmentId);
    if (bulk == null || bulk.status != BulkShipmentStatus.priced) return;

    final purchaseLines = <BulkPurchaseLine>[];
    for (final line in bulk.lines) {
      final qty = line.actualQty ?? 0;
      final price = line.listPrice ?? 0;
      final cost = line.unitCost ?? bulk.defaultUnitCost;
      if (qty < 1 || price <= 0) continue;
      purchaseLines.add(
        BulkPurchaseLine(
          name: line.name,
          price: price,
          costPrice: cost,
          quantity: qty,
          imagePath: line.imagePath,
        ),
      );
    }
    if (purchaseLines.isEmpty) return;

    await AddBulkItemsCommand(purchaseLines).call(ref);
    await repo.saveBulkShipment(
      bulk.copyWith(
        status: BulkShipmentStatus.completed,
        completedAt: DateTime.now(),
      ),
    );
    await reloadShopData(ref);
  }
}

class PrepareBulkCountDraftCommand extends Command {
  const PrepareBulkCountDraftCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    final bulk = await ref.get<ShopRepository>().getBulkShipment(shipmentId);
    if (bulk == null) return;
    final lines = bulk.lines
        .map(
          (l) => l.copyWith(
            actualQty: l.actualQty ?? l.expectedQty ?? 1,
            extraFind: l.extraFind,
          ),
        )
        .toList();
    await LoadBulkIntoDraftCommand(shipmentId).call(ref);
    await SetBulkDraftLinesCommand(lines).call(ref);
  }
}

class PrepareBulkPriceDraftCommand extends Command {
  const PrepareBulkPriceDraftCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) async {
    await LoadBulkIntoDraftCommand(shipmentId).call(ref);
    BulkShipment? bulk;
    for (final b in ref.of<ShopState>().bulkShipments) {
      if (b.id == shipmentId) {
        bulk = b;
        break;
      }
    }
    if (bulk == null) return;
    final defaultCost = bulk.defaultUnitCost;
    final lines = ref
        .of<BulkOrderDraftState>()
        .lines
        .map((l) => l.copyWith(unitCost: l.unitCost ?? defaultCost))
        .toList();
    await SetBulkDraftLinesCommand(lines).call(ref);
  }
}