// 行情列表数据
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/types/stock.dart';

class QuoteNotifier extends StateNotifier<AsyncValue<List<Share>>> {
  QuoteNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      // 初始加载数据
      await StoreQuote.load();
      state = AsyncValue.data(StoreQuote.shares);
      // 定时刷新数据
      // ignore: prefer_typing_uninitialized_variables
      var timer = Stream.periodic(const Duration(seconds: 1));
      timer.listen((_) async {
        await StoreQuote.refresh();
        state = AsyncValue.data(StoreQuote.shares);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 行情列表数据Provider
final quoteProvider =
    StateNotifierProvider<QuoteNotifier, AsyncValue<List<Share>>>(
      (ref) => QuoteNotifier(),
    );
