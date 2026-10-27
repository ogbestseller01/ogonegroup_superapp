import 'package:flutter/foundation.dart';
import '../models/banner.dart';
import '../services/api_service.dart';

class BannerProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<BannerItem> _banners = [];
  bool _loading = false;
  String? _error;

  List<BannerItem> get banners => _banners;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasBanners => _banners.isNotEmpty;

  Future<void> fetchBanners({String? type}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getBanners(type: type);

      if (res.success && res.data is List) {
        _banners = (res.data as List)
            .whereType<Map>()
            .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e)))
            .where((b) => b.image.isNotEmpty)
            .toList();
      } else {
        _banners = [];
        _error = res.message;
      }
    } catch (e) {
      _banners = [];
      _error = 'Failed to load banners';
      if (kDebugMode) print('BannerProvider error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}