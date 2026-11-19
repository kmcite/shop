import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/bulk_shipment_line_model.dart';
import '../models/bulk_shipment_model.dart';
import 'states/bulk_order_draft_state.dart';
import 'states/shop_state.dart';

class BulkOrderDraftCubit extends Cubit<BulkOrderDraftState> {
  BulkOrderDraftCubit() : super(const BulkOrderDraftState());

  void reset() => emit(const BulkOrderDraftState());

  void setError(String? message) => emit(state.copyWith(error: message));

  void loadFromShipment(String shipmentId, ShopState shop) {
    BulkShipment? found;
    for (final b in shop.bulkShipments) {
      if (b.id == shipmentId) {
        found = b;
        break;
      }
    }
    if (found == null) {
      emit(const BulkOrderDraftState(error: 'Bulk not found'));
      return;
    }
    final bulk = found;
    emit(
      BulkOrderDraftState(
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

  void setSeller(String value) =>
      emit(state.copyWith(sellerLabel: value, error: null));

  void setAgreedPrice(String value) =>
      emit(state.copyWith(agreedPrice: value, error: null));

  void setQuality(String value) =>
      emit(state.copyWith(qualityNotes: value, error: null));

  void setDelivery(String value) =>
      emit(state.copyWith(deliveryCharge: value, error: null));

  void setLines(List<BulkShipmentLine> lines) =>
      emit(state.copyWith(lines: lines, error: null));

  void upsertExpectedLine({
    required int index,
    required String name,
    required int expectedQty,
  }) {
    final lines = List<BulkShipmentLine>.of(state.lines);
    final trimmed = name.trim();
    if (index >= 0 && index < lines.length) {
      lines[index] =
          lines[index].copyWith(name: trimmed, expectedQty: expectedQty);
    } else if (trimmed.isNotEmpty && expectedQty > 0) {
      lines.add(BulkShipmentLine(name: trimmed, expectedQty: expectedQty));
    }
    emit(state.copyWith(lines: lines));
  }

  void removeLine(int index) {
    final lines = List<BulkShipmentLine>.of(state.lines);
    if (index >= 0 && index < lines.length) {
      lines.removeAt(index);
      emit(state.copyWith(lines: lines));
    }
  }

  void updateCountedLine({
    required int index,
    required String name,
    required int actualQty,
  }) {
    final lines = List<BulkShipmentLine>.of(state.lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = lines[index].copyWith(
        name: name.trim(),
        actualQty: actualQty,
      );
      emit(state.copyWith(lines: lines));
    }
  }

  void addCountedLine({required String name, required int actualQty}) {
    if (name.trim().isEmpty || actualQty < 1) return;
    final lines = List<BulkShipmentLine>.of(state.lines)
      ..add(
        BulkShipmentLine(
          name: name.trim(),
          actualQty: actualQty,
          extraFind: true,
        ),
      );
    emit(state.copyWith(lines: lines));
  }

  void updatePricedLine({
    required int index,
    required double listPrice,
    double? unitCost,
    String? imagePath,
  }) {
    final lines = List<BulkShipmentLine>.of(state.lines);
    if (index >= 0 && index < lines.length) {
      lines[index] = lines[index].copyWith(
        listPrice: listPrice,
        unitCost: unitCost,
        imagePath: imagePath,
      );
      emit(state.copyWith(lines: lines));
    }
  }
}