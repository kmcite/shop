import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shop/business/bulk_order_draft_cubit.dart';
import 'package:shop/business/shop_cubit.dart';
import 'package:shop/business/states/shop_state.dart';

import '../../models/bulk_shipment_model.dart';
import '../../ui/spacing.dart';
import '../design/metro.dart';
import '../widgets/bulk/bulk_ui.dart';
import '../widgets/bulk_progress_stepper.dart';
import 'bulk_count_screen.dart';
import 'bulk_price_screen.dart';
import 'bulk_receive_screen.dart';
import 'bulk_step_access.dart';
import 'bulk_step_order_screen.dart';
import 'bulk_step_stock_screen.dart';

class BulkShipmentHubScreen extends StatefulWidget {
  const BulkShipmentHubScreen({
    required this.shipmentId,
    this.initialStep,
    super.key,
  });

  final String shipmentId;
  final int? initialStep;

  static Route<void> route(
    BuildContext context,
    String shipmentId, {
    int? initialStep,
  }) {
    return metroRoute(
      context: context,
      builder: (_) => BulkShipmentHubScreen(
        shipmentId: shipmentId,
        initialStep: initialStep,
      ),
    );
  }

  @override
  State<BulkShipmentHubScreen> createState() => _BulkShipmentHubScreenState();
}

class _BulkShipmentHubScreenState extends State<BulkShipmentHubScreen> {
  static const _stepTitles = [
    'order',
    'receive',
    'count',
    'price',
    'stock',
  ];

  late final MetroPanoramaController _panorama;
  late int _page;
  bool _didSyncInitialPage = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialStep?.clamp(0, 4) ?? 0;
    _panorama = MetroPanoramaController();
    _panorama.addListener(_onPanorama);
  }

  @override
  void dispose() {
    _panorama.removeListener(_onPanorama);
    _panorama.dispose();
    super.dispose();
  }

  void _onPanorama() {
    final next = _panorama.index;
    if (next != _page) setState(() => _page = next);
  }

  void _syncInitialPage(BulkShipment bulk) {
    if (_didSyncInitialPage) return;
    _didSyncInitialPage = true;
    final target = (widget.initialStep ?? bulk.editableStepIndex).clamp(0, 4);
    if (target != _page) {
      _page = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _panorama.jumpToSection(target);
      });
    }
  }

  BulkShipment? _bulk(ShopState state) {
    for (final b in state.bulkShipments) {
      if (b.id == widget.shipmentId) return b;
    }
    return null;
  }

  void _goToPage(int index, {bool animate = true}) {
    final clamped = index.clamp(0, 4);
    setState(() => _page = clamped);
    if (animate) {
      _panorama.animateToSection(clamped);
    } else {
      _panorama.jumpToSection(clamped);
    }
  }

  Future<void> _advanceAfterStep() async {
    final updated = _bulk(context.read<ShopCubit>().state);
    if (updated == null) return;
    final next = updated.editableStepIndex.clamp(0, 4);
    _goToPage(next);
  }

  Future<void> _finalize(BuildContext context) async {
    await context.read<ShopCubit>().finalizeBulkShipment(widget.shipmentId);
    if (!context.mounted) return;
    final updated = _bulk(context.read<ShopCubit>().state);
    if (updated?.status != BulkShipmentStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not stock in — complete listing prices and counts first.',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk added to sellable inventory')),
    );
  }

  Widget? _flowBottomBar(BulkShipment bulk) {
    if (_page == 4 && bulk.status == BulkShipmentStatus.priced) {
      return BulkStickyPrimaryButton(
        label: 'add to inventory',
        onPressed: () => _finalize(context),
      );
    }
    if (!BulkStepAccess.isEditable(bulk.status, _page)) {
      return null;
    }

    return switch (_page) {
      1 => BulkStickyPrimaryButton(
          label: 'paid — bulk is at home',
          onPressed: () async {
            FocusScope.of(context).unfocus();
            await context.read<ShopCubit>().saveBulkReceived(
                  widget.shipmentId,
                  context.read<BulkOrderDraftCubit>(),
                );
            if (!mounted) return;
            if (context.read<BulkOrderDraftCubit>().state.error != null) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marked received — open the box when ready'),
              ),
            );
            await _advanceAfterStep();
          },
        ),
      2 => BulkStickyPrimaryButton(
          label: 'save counts',
          onPressed: () async {
            FocusScope.of(context).unfocus();
            await context.read<ShopCubit>().saveBulkCounted(
                  widget.shipmentId,
                  context.read<BulkOrderDraftCubit>(),
                );
            if (!mounted) return;
            if (context.read<BulkOrderDraftCubit>().state.error != null) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Counts saved — set listing prices next'),
              ),
            );
            await _advanceAfterStep();
          },
        ),
      3 => BulkStickyPrimaryButton(
          label: 'save prices',
          onPressed: () async {
            await context.read<ShopCubit>().saveBulkPriced(
                  widget.shipmentId,
                  context.read<BulkOrderDraftCubit>(),
                );
            if (!mounted) return;
            if (context.read<BulkOrderDraftCubit>().state.error != null) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing prices saved')),
            );
            await _advanceAfterStep();
          },
        ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bulk = _bulk(context.watch<ShopCubit>().state);
    if (bulk == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Bulk not found')),
      );
    }

    _syncInitialPage(bulk);

    final metro = MetroTheme.of(context);
    final bottom = _flowBottomBar(bulk);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MetroSpacing.lg,
                MetroSpacing.xs,
                MetroSpacing.xs,
                0,
              ),
              child: Row(
                children: [
                  MetroIconButton(
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    style: const MetroButtonStyle(
                      minimumSize: Size.square(40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      bulk.status.label.toLowerCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: metro.colors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MetroSpacing.lg,
                MetroSpacing.xs,
                MetroSpacing.lg,
                MetroSpacing.sm,
              ),
              child: BulkProgressStepper(
                current: bulk.status,
                shipmentId: bulk.id,
                selectedStepIndex: _page,
                onStepSelected: (i) => _goToPage(i),
              ),
            ),
            Expanded(
              child: MetroPanoramaView(
                title: bulk.sellerLabel,
                controller: _panorama,
                initialSection: _page,
                sectionPeek: MetroSpacing.xl,
                onSectionChanged: (i) => setState(() => _page = i),
                titleStyle: ShopMetroTypography.panoramaTitle(metro.colors.foreground)
                    .copyWith(fontSize: 56),
                sections: [
                  for (var i = 0; i < _stepTitles.length; i++)
                    MetroPanoramaSection(
                      title: _stepTitles[i],
                      wrapInScroll: false,
                      titleStyle: ShopMetroTypography.sectionHeader(
                        metro.colors.mutedForeground,
                      ).copyWith(fontSize: 28),
                      child: switch (i) {
                        0 => BulkStepOrderScreen(
                            shipmentId: widget.shipmentId,
                            embedded: true,
                          ),
                        1 => BulkReceiveScreen(
                            shipmentId: widget.shipmentId,
                            readOnly:
                                BulkStepAccess.isReadOnly(bulk.status, 1),
                            embedded: true,
                            onStepCompleted: _advanceAfterStep,
                          ),
                        2 => BulkCountScreen(
                            shipmentId: widget.shipmentId,
                            readOnly:
                                BulkStepAccess.isReadOnly(bulk.status, 2),
                            embedded: true,
                            onStepCompleted: _advanceAfterStep,
                          ),
                        3 => BulkPriceScreen(
                            shipmentId: widget.shipmentId,
                            readOnly:
                                BulkStepAccess.isReadOnly(bulk.status, 3),
                            embedded: true,
                            onStepCompleted: _advanceAfterStep,
                          ),
                        _ => BulkStepStockScreen(
                            shipmentId: widget.shipmentId,
                            readOnly:
                                BulkStepAccess.isReadOnly(bulk.status, 4),
                            embedded: true,
                          ),
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: bottom,
              ),
            ),
    );
  }
}
