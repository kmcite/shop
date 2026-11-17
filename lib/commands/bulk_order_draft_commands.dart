import 'dart:async';

import 'package:any/any.dart';

import '../models/bulk_shipment_line_model.dart';
import '../models/bulk_shipment_model.dart';
import '../states/bulk_order_draft_state.dart';
import '../states/shop_state.dart';

class ResetBulkOrderDraftCommand extends Command {
  const ResetBulkOrderDraftCommand();

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((_) => const BulkOrderDraftState());
  }
}

class LoadBulkIntoDraftCommand extends Command {
  const LoadBulkIntoDraftCommand(this.shipmentId);

  final String shipmentId;

  @override
  FutureOr<void> call(Ref ref) {
    BulkShipment? found;
    for (final b in ref.of<ShopState>().bulkShipments) {
      if (b.id == shipmentId) {
        found = b;
        break;
      }
    }
    if (found == null) {
      ref<BulkOrderDraftState>(
        (_) => const BulkOrderDraftState(error: 'Bulk not found'),
      );
    } else {
      final bulk = found;
      ref<BulkOrderDraftState>(
        (_) => BulkOrderDraftState(
          editingBulkId: bulk.id,
          sellerLabel: bulk.sellerLabel,
          agreedPrice: bulk.agreedPrice > 0 ? '${bulk.agreedPrice}' : '',
          qualityNotes: bulk.qualityNotes,
          deliveryCharge:
              bulk.deliveryCharge > 0 ? '${bulk.deliveryCharge}' : '',
          notes: bulk.notes ?? '',
          lines: List.of(bulk.lines),
        ),
      );
    }
  }
}

class SetBulkDraftSellerCommand extends Command {
  const SetBulkDraftSellerCommand(this.value);

  final String value;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((s) => s.copyWith(sellerLabel: value, error: null));
  }
}

class SetBulkDraftAgreedPriceCommand extends Command {
  const SetBulkDraftAgreedPriceCommand(this.value);

  final String value;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((s) => s.copyWith(agreedPrice: value, error: null));
  }
}

class SetBulkDraftQualityCommand extends Command {
  const SetBulkDraftQualityCommand(this.value);

  final String value;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((s) => s.copyWith(qualityNotes: value, error: null));
  }
}

class SetBulkDraftDeliveryCommand extends Command {
  const SetBulkDraftDeliveryCommand(this.value);

  final String value;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>(
      (s) => s.copyWith(deliveryCharge: value, error: null),
    );
  }
}

class SetBulkDraftErrorCommand extends Command {
  const SetBulkDraftErrorCommand(this.message);

  final String? message;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((s) => s.copyWith(error: message));
  }
}

class SetBulkDraftLinesCommand extends Command {
  const SetBulkDraftLinesCommand(this.lines);

  final List<BulkShipmentLine> lines;

  @override
  FutureOr<void> call(Ref ref) {
    ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines, error: null));
  }
}

class UpsertBulkDraftExpectedLineCommand extends Command {
  const UpsertBulkDraftExpectedLineCommand({
    required this.index,
    required this.name,
    required this.expectedQty,
  });

  final int index;
  final String name;
  final int expectedQty;

  @override
  FutureOr<void> call(Ref ref) {
    final draft = ref.of<BulkOrderDraftState>();
    final lines = List<BulkShipmentLine>.of(draft.lines);
    final trimmed = name.trim();
    if (index >= 0 && index < lines.length) {
      lines[index] = lines[index].copyWith(name: trimmed, expectedQty: expectedQty);
    } else if (trimmed.isNotEmpty && expectedQty > 0) {
      lines.add(
        BulkShipmentLine(name: trimmed, expectedQty: expectedQty),
      );
    }
    ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines));
  }
}

class RemoveBulkDraftLineCommand extends Command {
  const RemoveBulkDraftLineCommand(this.index);

  final int index;

  @override
  FutureOr<void> call(Ref ref) {
    final lines = List<BulkShipmentLine>.of(ref.of<BulkOrderDraftState>().lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines));
    }
  }
}

class UpdateBulkDraftCountedLineCommand extends Command {
  const UpdateBulkDraftCountedLineCommand({
    required this.index,
    required this.name,
    required this.actualQty,
  });

  final int index;
  final String name;
  final int actualQty;

  @override
  FutureOr<void> call(Ref ref) {
    final lines = List<BulkShipmentLine>.of(ref.of<BulkOrderDraftState>().lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = lines[index].copyWith(
        name: name.trim(),
        actualQty: actualQty,
      );
      ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines));
    }
  }
}

class AddBulkDraftCountedLineCommand extends Command {
  const AddBulkDraftCountedLineCommand({
    required this.name,
    required this.actualQty,
  });

  final String name;
  final int actualQty;

  @override
  FutureOr<void> call(Ref ref) {
    if (name.trim().isNotEmpty && actualQty >= 1) {
      final lines = List<BulkShipmentLine>.of(ref.of<BulkOrderDraftState>().lines)
        ..add(
          BulkShipmentLine(
            name: name.trim(),
            actualQty: actualQty,
            extraFind: true,
          ),
        );
      ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines));
    }
  }
}

class UpdateBulkDraftPricedLineCommand extends Command {
  const UpdateBulkDraftPricedLineCommand({
    required this.index,
    required this.listPrice,
    this.unitCost,
    this.imagePath,
  });

  final int index;
  final double listPrice;
  final double? unitCost;
  final String? imagePath;

  @override
  FutureOr<void> call(Ref ref) {
    final lines = List<BulkShipmentLine>.of(ref.of<BulkOrderDraftState>().lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = lines[index].copyWith(
        listPrice: listPrice,
        unitCost: unitCost,
        imagePath: imagePath,
      );
      ref<BulkOrderDraftState>((s) => s.copyWith(lines: lines));
    }
  }
}