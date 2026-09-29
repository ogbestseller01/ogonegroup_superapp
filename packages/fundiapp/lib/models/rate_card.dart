// lib/models/rate_card.dart

class RateCard {
  final int id;
  final String name;
  final String slug;
  final double price;
  final String formattedPrice;
  final int durationDays;
  final String durationLabel;
  final String? description;
  final String currency;

  RateCard({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.formattedPrice,
    required this.durationDays,
    required this.durationLabel,
    this.description,
    required this.currency,
  });

  factory RateCard.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Properly parse price to double
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove commas and convert
        final cleaned = value.replaceAll(',', '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    return RateCard(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      price: parsePrice(json['price']),
      formattedPrice: json['formatted_price'] ?? '',
      durationDays: json['duration_days'] ?? 0,
      durationLabel: json['duration_label'] ?? '',
      description: json['description'],
      currency: json['currency'] ?? 'TZS',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'price': price,
    'formatted_price': formattedPrice,
    'duration_days': durationDays,
    'duration_label': durationLabel,
    'description': description,
    'currency': currency,
  };
}