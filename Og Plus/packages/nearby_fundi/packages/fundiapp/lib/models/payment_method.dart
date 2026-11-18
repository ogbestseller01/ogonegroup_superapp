import 'dart:ui';

/// Payment Method Model
class PaymentMethod {
  final int id;
  final String name;
  final String slug;
  final String phoneNumber;
  final String? accountName;
  final String? logo;
  final bool isActive;
  final int displayOrder;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.slug,
    required this.phoneNumber,
    this.accountName,
    this.logo,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Properly parse is_active from API response
    bool isActive = true;
    final isActiveValue = json['is_active'];
    if (isActiveValue != null) {
      if (isActiveValue is bool) {
        isActive = isActiveValue;
      } else if (isActiveValue is int) {
        isActive = isActiveValue == 1;
      } else if (isActiveValue is String) {
        isActive = isActiveValue == '1' || isActiveValue.toLowerCase() == 'true';
      }
    }

    return PaymentMethod(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ??
          json['formatted_phone']?.toString() ?? '',
      accountName: json['account_name']?.toString(),
      logo: json['logo']?.toString(),
      isActive: isActive,
      displayOrder: json['display_order'] ?? 0,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  String get formattedPhone {
    final phone = phoneNumber.replaceAll(RegExp(r'\s'), '');
    if (phone.isEmpty) return '';
    if (phone.length > 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
    } else if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  String get displayName => '$name ($formattedPhone)';
  String get displayNameShort => name;

  String get iconAsset {
    final slugLower = slug.toLowerCase();
    if (slugLower.contains('mpesa') || slugLower.contains('m-pesa')) {
      return 'assets/icons/mpesa.png';
    } else if (slugLower.contains('airtel')) {
      return 'assets/icons/airtel.png';
    } else if (slugLower.contains('mix') || slugLower.contains('yas')) {
      return 'assets/icons/mixx_by_yas.png';
    }
    return 'assets/icons/mpesa.png';
  }

  Color get brandColor {
    final slugLower = slug.toLowerCase();
    if (slugLower.contains('mpesa') || slugLower.contains('m-pesa')) {
      return const Color(0xFF4CAF50);
    } else if (slugLower.contains('airtel')) {
      return const Color(0xFFD32F2F);
    } else if (slugLower.contains('mix') || slugLower.contains('yas')) {
      return const Color(0xFFFF9800);
    }
    return const Color(0xFF2196F3);
  }

  Color get brandBackgroundColor => brandColor.withOpacity(0.1);

  bool get isActiveMethod => isActive;

  @override
  String toString() => 'PaymentMethod(id: $id, name: $name, isActive: $isActive)';
}