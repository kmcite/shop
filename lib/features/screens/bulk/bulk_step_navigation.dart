import 'package:flutter/material.dart';

import '../../../models/bulk_shipment_model.dart';
import 'bulk_count_screen.dart';
import 'bulk_price_screen.dart';
import 'bulk_receive_screen.dart';
import 'bulk_step_access.dart';
import 'bulk_step_order_screen.dart';
import 'bulk_step_stock_screen.dart';

void openBulkTimelineStep(
  BuildContext context, {
  required String shipmentId,
  required BulkShipmentStatus status,
  required int stepIndex,
}) {
  if (!BulkStepAccess.canNavigate(status, stepIndex)) return;
  final readOnly = BulkStepAccess.isReadOnly(status, stepIndex);

  final route = switch (stepIndex) {
    0 => BulkStepOrderScreen.route(shipmentId),
    1 => BulkReceiveScreen.route(shipmentId, readOnly: readOnly),
    2 => BulkCountScreen.route(shipmentId, readOnly: readOnly),
    3 => BulkPriceScreen.route(shipmentId, readOnly: readOnly),
    4 => BulkStepStockScreen.route(shipmentId, readOnly: readOnly),
    _ => null,
  };
  if (route != null) {
    Navigator.of(context).push(route);
  }
}