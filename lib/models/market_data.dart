class MarketItem {
  final String code;
  final String nameTR;
  final double rateInTRY;
  final DateTime fetchedAt;

  const MarketItem({
    required this.code,
    required this.nameTR,
    required this.rateInTRY,
    required this.fetchedAt,
  });
}
