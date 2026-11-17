import '../models/sell_cart_line_model.dart';

/// In-progress sale: one or more items before checkout.
class SellCartState {
  const SellCartState({this.lines = const []});

  final List<SellCartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get itemTypeCount => lines.length;

  int get unitCount => lines.fold<int>(0, (sum, l) => sum + l.quantity);

  SellCartState copyWith({List<SellCartLine>? lines}) {
    return SellCartState(lines: lines ?? this.lines);
  }
}