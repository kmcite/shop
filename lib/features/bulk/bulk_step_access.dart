import '../../models/bulk_shipment_model.dart';

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
    if (isLocked(status, stepIndex)) return true;
    return stepIndex < editableStepIndex(status);
  }

  /// Lock / past-step banner copy. `null` when the screen uses its own intro.
  static String? stepBannerMessage(
    BulkShipmentStatus status,
    int stepIndex,
  ) {
    if (stepIndex < 0 || stepIndex >= stepCount) return null;

    if (!status.isActive) {
      if (status == BulkShipmentStatus.completed && stepIndex == 4) {
        return 'This bulk was added to inventory.';
      }
      return 'This step is complete — view only.';
    }

    if (isLocked(status, stepIndex)) {
      return 'This step is not active yet — finish the earlier steps first.';
    }

    if (stepIndex < editableStepIndex(status)) {
      if (stepIndex == 0 && status == BulkShipmentStatus.ordered) {
        return null;
      }
      return 'This step is complete — view only.';
    }

    return null;
  }

  /// Shown on the current editable step when there is no banner.
  static String? stepIntroMessage(BulkShipmentStatus status, int stepIndex) {
    if (!isEditable(status, stepIndex)) return null;
    return switch ((status, stepIndex)) {
      (BulkShipmentStatus.ordered, 0) =>
        'Order recorded — use Receive when the lot arrives.',
      (BulkShipmentStatus.priced, 4) =>
        'Listing prices are set — use Add to inventory below.',
      _ => null,
    };
  }

  /// Whether the step is the one the user should fill in next.
  static bool isEditable(BulkShipmentStatus status, int stepIndex) {
    if (!status.isActive) return false;
    return stepIndex == editableStepIndex(status);
  }

  /// Step dots from cards still skip locked steps; the in-flow panorama can
  /// swipe to every step.
  static bool canNavigate(BulkShipmentStatus status, int stepIndex) {
    return !isLocked(status, stepIndex);
  }
}