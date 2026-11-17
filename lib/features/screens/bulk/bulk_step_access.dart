import '../../../models/bulk_shipment_model.dart';

/// Which bulk timeline steps can be opened, and whether they are view-only.
abstract final class BulkStepAccess {
  static int get stepCount => BulkShipmentStatus.values.length;

  static int editableStepIndex(BulkShipmentStatus status) {
    return status.editableStepIndex;
  }

  static bool isLocked(BulkShipmentStatus status, int stepIndex) {
    if (stepIndex < 0 || stepIndex >= stepCount) return true;
    if (!status.isActive) return false;
    return stepIndex > editableStepIndex(status);
  }

  static bool isReadOnly(BulkShipmentStatus status, int stepIndex) {
    if (stepIndex < 0 || stepIndex >= stepCount) return true;
    if (!status.isActive) return true;
    if (status == BulkShipmentStatus.priced && stepIndex == 4) return true;
    if (status == BulkShipmentStatus.completed && stepIndex == 4) return true;
    return stepIndex < editableStepIndex(status);
  }

  static bool canNavigate(BulkShipmentStatus status, int stepIndex) {
    return !isLocked(status, stepIndex);
  }
}