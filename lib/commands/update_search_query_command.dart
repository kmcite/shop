import 'dart:async';

import 'package:any/any.dart';

import '../states/shop_state.dart';

/// Updates the inventory search text (pure UI state, no repository call).
class UpdateSearchQueryCommand extends Command {
  const UpdateSearchQueryCommand(this.query);

  final String query;

  @override
  FutureOr<void> call(Ref ref) {
    ref<ShopState>((s) => s.copyWith(searchQuery: query));
  }
}