class FuelPriceModel {
  final double gasolinePrice;
  final double dieselPrice;
  final String region;
  final DateTime lastUpdated;

  const FuelPriceModel({
    required this.gasolinePrice,
    required this.dieselPrice,
    this.region = 'Metro Manila & Luzon Benchmark',
    required this.lastUpdated,
  });

  /// Sensible default benchmark prices based on DOE Philippine weekly averages
  factory FuelPriceModel.defaultBenchmark() {
    return FuelPriceModel(
      gasolinePrice: 62.50,
      dieselPrice: 58.00,
      region: 'Philippine DOE Benchmark',
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gasolinePrice': gasolinePrice,
      'dieselPrice': dieselPrice,
      'region': region,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      gasolinePrice: (json['gasolinePrice'] as num?)?.toDouble() ?? 62.50,
      dieselPrice: (json['dieselPrice'] as num?)?.toDouble() ?? 58.00,
      region: json['region'] as String? ?? 'Philippine DOE Benchmark',
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
