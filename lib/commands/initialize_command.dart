import 'dart:async';

import 'package:any/any.dart';

import '../repositories/shop_repository.dart';
import '../states/shop_state.dart';
import 'reload_shop_data.dart';

/// Connects to the database and loads the inventory.
/// Also used as the "retry connection" command from the error screen.
class InitializeCommand extends Command {
  const InitializeCommand();

  @override
  FutureOr<void> call(Ref ref) async {
    ref<ShopState>((s) => s.copyWith(isLoading: true, error: null));

    final shopRepository = ref.get<ShopRepository>();

    try {
      await shopRepository.connect();
      ref<ShopState>((s) => s.copyWith(bootstraped: true));
      await reloadShopData(ref);
    } catch (error) {
      ref<ShopState>(
        (s) => s.copyWith(isLoading: false, error: error, bootstraped: false),
      );
    }
  }
}