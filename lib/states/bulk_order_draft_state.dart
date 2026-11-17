import '../models/bulk_shipment_line_model.dart';

const Object _keep = Object();

/// Transient UI draft for creating or editing one step of a bulk shipment.
class BulkOrderDraftState {
  const BulkOrderDraftState({
    this.editingBulkId,
    this.sellerLabel = '',
    this.agreedPrice = '',
    this.qualityNotes = '',
    this.deliveryCharge = '',
    this.notes = '',
    this.lines = const [],
    this.error,
  });

  /// Non-null when editing an existing shipment in the wizard.
  final String? editingBulkId;

  final String sellerLabel;
  final String agreedPrice;
  final String qualityNotes;
  final String deliveryCharge;
  final String notes;
  final List<BulkShipmentLine> lines;
  final String? error;

  double? get parsedAgreedPrice => double.tryParse(agreedPrice.trim());
  double? get parsedDeliveryCharge => double.tryParse(deliveryCharge.trim());

  BulkOrderDraftState copyWith({
    String? editingBulkId,
    String? sellerLabel,
    String? agreedPrice,
    String? qualityNotes,
    String? deliveryCharge,
    String? notes,
    List<BulkShipmentLine>? lines,
    Object? error = _keep,
  }) {
    return BulkOrderDraftState(
      editingBulkId: editingBulkId ?? this.editingBulkId,
      sellerLabel: sellerLabel ?? this.sellerLabel,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      qualityNotes: qualityNotes ?? this.qualityNotes,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
      error: identical(error, _keep) ? this.error : error as String?,
    );
  }
}