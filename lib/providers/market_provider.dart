import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/market_api_service.dart';
import '../models/market_data.dart';

class MarketState {
  final List<MarketItem> items;
  final bool isLoading;
  final bool hasError;
  final DateTime? lastUpdated;

  const MarketState({
    this.items = const [],
    this.isLoading = false,
    this.hasError = false,
    this.lastUpdated,
  });

  MarketState copyWith({
    List<MarketItem>? items,
    bool? isLoading,
    bool? hasError,
    DateTime? lastUpdated,
  }) => MarketState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasError: hasError ?? this.hasError,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  List<MarketItem> get doviz    => items.where((i) => ['USD','EUR'].contains(i.code)).toList();
  List<MarketItem> get madenler => items.where((i) => ['XAU','XAG'].contains(i.code)).toList();
  List<MarketItem> get kripto   => items.where((i) => ['BTC','ETH'].contains(i.code)).toList();
}

class MarketNotifier extends Notifier<MarketState> {
  Timer? _timer;

  @override
  MarketState build() => const MarketState();

  Future<void> init() async {
    await refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final data = await MarketApiService.fetchAll();
      if (data.isNotEmpty) {
        state = state.copyWith(
          items: data,
          lastUpdated: DateTime.now(),
          hasError: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(hasError: state.items.isEmpty, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(hasError: state.items.isEmpty, isLoading: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
  }
}

final marketProvider = NotifierProvider<MarketNotifier, MarketState>(MarketNotifier.new);
