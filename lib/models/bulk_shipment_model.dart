import 'package:shared_database/shared_database.dart';

import 'bulk_shipment_line_model.dart';

/// Lifecycle of a wholesale lot bought from an online seller.
enum BulkShipmentStatus {
  /// Agreed with seller; not yet at home.
  ordered,

  /// Paid (lot + delivery); package at home, unopened.
  received,

  /// Opened; actual counts recorded per type.
  counted,

  /// List prices set; ready to move into sellable inventory.
  priced,

  /// Lines were added to [shop_items].
  completed;

  String get wire => name;

  static BulkShipmentStatus parse(String? raw) {
    return BulkShipmentStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => BulkShipmentStatus.ordered,
    );
  }

  String get label => switch (this) {
        BulkShipmentStatus.ordered => 'On order',
        BulkShipmentStatus.received => 'At home',
        BulkShipmentStatus.counted => 'Counted',
        BulkShipmentStatus.priced => 'Priced',
        BulkShipmentStatus.completed => 'In inventory',
      };

  int get stepIndex => index;

  /// Workflow step the user should work on (order is fixed once [ordered]).
  int get editableStepIndex => switch (this) {
        BulkShipmentStatus.ordered => 1,
        BulkShipmentStatus.received => 2,
        BulkShipmentStatus.counted => 3,
        BulkShipmentStatus.priced => 4,
        BulkShipmentStatus.completed => 4,
      };

  bool get isActive => this != BulkShipmentStatus.completed;
}

class BulkShipment {
  const BulkShipment({
    required this.id,
    required this.sellerLabel,
    required this.agreedPrice,
    required this.qualityNotes,
    required this.status,
    required this.lines,
    required this.createdAt,
    this.deliveryCharge = 0,
    this.receivedAt,
    this.countedAt,
    this.pricedAt,
    this.completedAt,
    this.notes,
  });

  final String id;
  final String sellerLabel;

  /// What you pay the seller for the whole lot.
  final double agreedPrice;

  /// Seller's promised quality / condition (free text).
  final String qualityNotes;

  final BulkShipmentStatus status;
  final List<BulkShipmentLine> lines;

  final double deliveryCharge;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final DateTime? countedAt;
  final DateTime? pricedAt;
  final DateTime? completedAt;
  final String? notes;

  double get totalPaid => agreedPrice + deliveryCharge;

  int get expectedUnitCount =>
      lines.fold<int>(0, (n, l) => n + (l.expectedQty ?? 0));

  int get actualUnitCount =>
      lines.fold<int>(0, (n, l) => n + (l.actualQty ?? 0));

  /// Default per-unit cost when lines do not override [BulkShipmentLine.unitCost].
  double get defaultUnitCost {
    final units = actualUnitCount;
    if (units < 1) return 0;
    return totalPaid / units;
  }

  BulkShipmentStatus get nextAction => switch (status) {
        BulkShipmentStatus.ordered => BulkShipmentStatus.received,
        BulkShipmentStatus.received => BulkShipmentStatus.counted,
        BulkShipmentStatus.counted => BulkShipmentStatus.priced,
        BulkShipmentStatus.priced => BulkShipmentStatus.completed,
        BulkShipmentStatus.completed => BulkShipmentStatus.completed,
      };

  int get editableStepIndex => status.editableStepIndex;

  String get nextActionLabel => switch (status) {
        BulkShipmentStatus.ordered => 'Mark received & pay',
        BulkShipmentStatus.received => 'Open & count items',
        BulkShipmentStatus.counted => 'Set listing prices',
        BulkShipmentStatus.priced => 'Add to inventory',
        BulkShipmentStatus.completed => 'Done',
      };

  static BulkShipment fromRecord(SharedRecord record) {
    final data = record.data;
    final rawLines = data['lines'];
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((e) => BulkShipmentLine.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BulkShipmentLine>[];

    return BulkShipment(
      id: record.id,
      sellerLabel: data['sellerLabel'] as String? ?? 'Seller',
      agreedPrice: (data['agreedPrice'] as num?)?.toDouble() ?? 0,
      qualityNotes: data['qualityNotes'] as String? ?? '',
      deliveryCharge: (data['deliveryCharge'] as num?)?.toDouble() ?? 0,
      status: BulkShipmentStatus.parse(data['status'] as String?),
      lines: lines,
      createdAt: _parseTime(data['createdAt']) ?? DateTime.now(),
      receivedAt: _parseTime(data['receivedAt']),
      countedAt: _parseTime(data['countedAt']),
      pricedAt: _parseTime(data['pricedAt']),
      completedAt: _parseTime(data['completedAt']),
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toData() => {
        'sellerLabel': sellerLabel.trim(),
        'agreedPrice': agreedPrice,
        'qualityNotes': qualityNotes.trim(),
        'deliveryCharge': deliveryCharge,
        'status': status.wire,
        'lines': lines.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
        if (countedAt != null) 'countedAt': countedAt!.toIso8601String(),
        if (pricedAt != null) 'pricedAt': pricedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      };

  BulkShipment copyWith({
    String? sellerLabel,
    double? agreedPrice,
    String? qualityNotes,
    BulkShipmentStatus? status,
    List<BulkShipmentLine>? lines,
    double? deliveryCharge,
    DateTime? receivedAt,
    DateTime? countedAt,
    DateTime? pricedAt,
    DateTime? completedAt,
    String? notes,
  }) {
    return BulkShipment(
      id: id,
      sellerLabel: sellerLabel ?? this.sellerLabel,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      qualityNotes: qualityNotes ?? this.qualityNotes,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      createdAt: createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      countedAt: countedAt ?? this.countedAt,
      pricedAt: pricedAt ?? this.pricedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}

DateTime? _parseTime(Object? raw) {
  if (raw is! String) return null;
  return DateTime.tryParse(raw);
}