import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/shop_cubit.dart';

import '../../models/bulk_shipment_model.dart';
import 'bulk_step_access.dart';

void openBulkTimelineStep(
  BuildContext context, {
  required String shipmentId,
  required BulkShipmentStatus status,
  required int stepIndex,
}) {
  if (stepIndex < 0 || stepIndex >= BulkStepAccess.stepCount) return;
  context.read<ShopCubit>().openBulkShipment(
        shipmentId,
        initialStep: stepIndex,
      );
}