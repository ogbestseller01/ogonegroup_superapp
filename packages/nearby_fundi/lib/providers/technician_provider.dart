// providers/technician_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/technician.dart';
import '../services/technician_heartbeat_service.dart'; // ✅ added

class TechnicianProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final TechnicianHeartbeatService _heartbeatService = TechnicianHeartbeatService();

  List<Technician> _technicians = [];
  Technician? _currentTechnician;
  Technician? _myTechnician;
  bool _isLoading = false;
  String? _error;

  double? _searchLat;
  double? _searchLng;
  String? _searchPlace;

  String? _lastPlace;
  int? _lastServiceId;
  int? _lastCategoryId;
  int _lastRadius = 20;

  // Meta info from API response
  Map<String, dynamic>? _searchMeta;
  Map<String, dynamic>? _filters;
  Map<String, dynamic>? _meta;

  // ─── Getters ───────────────────────────────────────────────────────────
  List<Technician> get technicians => _technicians;
  Technician? get currentTechnician => _currentTechnician;
  Technician? get technician => _myTechnician;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get searchLat => _searchLat;
  double? get searchLng => _searchLng;
  String? get searchPlace => _searchPlace;
  bool get hasSearchOrigin => _searchLat != null && _searchLng != null;
  Map<String, dynamic>? get searchMeta => _searchMeta;
  Map<String, dynamic>? get filters => _filters;
  Map<String, dynamic>? get meta => _meta;

  // ─── Heartbeat controls ──────────────────────────────────────────────
  void startHeartbeat() {
    _heartbeatService.start();
  }

  void stopHeartbeat() {
    _heartbeatService.stop();
  }

  bool get isHeartbeatRunning => _heartbeatService.isRunning;

  // ─── Refresh last search ───────────────────────────────────────────────
  Future<void> refreshLastSearch() async {
    if (_lastPlace != null && _lastPlace!.isNotEmpty) {
      await searchByPlace(
        place: _lastPlace!,
        serviceId: _lastServiceId,
        categoryId: _lastCategoryId,
        radius: _lastRadius,
        locale: '',
      );
    }
  }

  // ─── Search by place name ──────────────────────────────────────────────
  Future<void> searchByPlace({
    required String place,
    int? serviceId,
    int? categoryId,
    int radius = 20,
    required String locale,
    String? search,
  }) async {
    _lastPlace = place;
    _lastServiceId = serviceId;
    _lastCategoryId = categoryId;
    _lastRadius = radius;

    _setLoading(true);

    try {
      final res = await _api.searchTechniciansByPlace(
        place: place,
        serviceId: serviceId,
        categoryId: categoryId,
        radius: radius,
        search: search,
        locale: locale,
      );
      _handlePlaceSearchResponse(res);
    } catch (e) {
      _error = e.toString();
      _technicians = [];
      _searchLat = null;
      _searchLng = null;
      _searchPlace = null;
      _searchMeta = null;
      _filters = null;
      _meta = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Search by GPS coordinates (Map Picker) ───────────────────────────
  Future<void> searchByCoordinates({
    required double lat,
    required double lng,
    int? serviceId,
    int? categoryId,
    int radius = 20,
    String? search,
    String locale = 'en',
    String? placeName,
  }) async {
    _lastPlace = placeName ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    _lastServiceId = serviceId;
    _lastCategoryId = categoryId;
    _lastRadius = radius;

    _setLoading(true);

    try {
      final res = await _api.getNearbyTechnicians(
        lat: lat,
        lng: lng,
        radius: radius,
        serviceId: serviceId,
        categoryId: categoryId,
        search: search,
        locale: locale,
      );

      _searchLat = lat;
      _searchLng = lng;
      _searchPlace = placeName ?? _lastPlace;

      _handleListResponse(res);
    } catch (e) {
      _error = e.toString();
      _technicians = [];
      _searchLat = null;
      _searchLng = null;
      _searchPlace = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Legacy fetchNearby (now calls searchByCoordinates) ────────────────
  Future<void> fetchNearby({
    required double lat,
    required double lng,
    int? serviceId,
    int? categoryId,
    int radius = 20,
    String? search,
    String locale = 'en',
  }) async {
    await searchByCoordinates(
      lat: lat,
      lng: lng,
      serviceId: serviceId,
      categoryId: categoryId,
      radius: radius,
      search: search,
      locale: locale,
    );
  }

  // ─── Clear state ───────────────────────────────────────────────────────
  void clearTechnicians() {
    _technicians = [];
    _searchLat = null;
    _searchLng = null;
    _searchPlace = null;
    _searchMeta = null;
    _filters = null;
    _meta = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Detail ────────────────────────────────────────────────────────────
  Future<void> fetchTechnicianDetail(int id) async {
    _isLoading = true;
    _error = null;
    _currentTechnician = null;
    notifyListeners();

    try {
      final res = await _api.getTechnicianDetail(id);
      if (res.success && res.data != null) {
        _currentTechnician = Technician.fromJson(res.data, isDetail: true);
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── UPDATED: Fetch technician with portfolios (preserves new fields) ──
  Future<void> fetchTechnicianWithPortfolios(int id) async {
    _isLoading = true;
    _error = null;
    _currentTechnician = null;
    notifyListeners();

    try {
      final detailRes = await _api.getTechnicianDetail(id);
      if (!detailRes.success || detailRes.data == null) {
        _error = detailRes.message;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Parse the technician (includes all new fields)
      final tech = Technician.fromJson(detailRes.data, isDetail: false);

      // Fetch portfolios separately
      final portfolioRes = await _api.getTechnicianPortfolio(id);
      List<PortfolioItem> portfolioItems = [];
      if (portfolioRes.success && portfolioRes.data != null) {
        final data = portfolioRes.data as Map<String, dynamic>;
        final portfoliosData = data['portfolios'] as List? ?? [];
        portfolioItems =
            portfoliosData.map((p) => PortfolioItem.fromJson(p)).toList();
      }

      // Rebuild the technician preserving all fields, only replacing portfolios
      _currentTechnician = Technician(
        id: tech.id,
        userId: tech.userId,
        name: tech.name,
        email: tech.email,
        phone: tech.phone,
        profilePhoto: tech.profilePhoto,
        bio: tech.bio,
        experience: tech.experience,
        rating: tech.rating,
        hourlyRate: tech.hourlyRate,
        distanceKm: tech.distanceKm,
        area: tech.area,
        latitude: tech.latitude,
        longitude: tech.longitude,
        isOnline: tech.isOnline,
        verified: tech.verified,
        services: tech.services,
        serviceObjects: tech.serviceObjects,
        portfolios: portfolioItems,
        // ─── NEW FIELDS ──────────────────────────────────────────────
        completedJobsCount: tech.completedJobsCount,
        priceRange: tech.priceRange,
        servicePrices: tech.servicePrices,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── My profile (Fundi side) ───────────────────────────────────────────
  Future<void> fetchMyProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getTechnicianProfile();
      if (res.success && res.data != null) {
        _myTechnician = Technician.fromJson(res.data, isDetail: true);
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateServices(List<int> serviceIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateTechnicianServices(serviceIds);
      if (res.success && res.data != null) {
        _myTechnician = Technician.fromJson(res.data, isDetail: true);
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── UPDATED toggleOnline – now starts/stops heartbeat ────────────────
  Future<void> toggleOnline(bool isOnline) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.toggleTechnicianOnline(isOnline);
      if (res.success && res.data != null) {
        _myTechnician = Technician.fromJson(res.data, isDetail: true);
        _error = null;
        // ─── Auto start/stop heartbeat ──────────────────────────────
        if (isOnline) {
          startHeartbeat();
        } else {
          stopHeartbeat();
        }
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.updateTechnicianLocation(latitude, longitude);
      if (res.success) {
        if (_myTechnician != null) {
          _myTechnician = Technician(
            id: _myTechnician!.id,
            userId: _myTechnician!.userId,
            name: _myTechnician!.name,
            email: _myTechnician!.email,
            phone: _myTechnician!.phone,
            profilePhoto: _myTechnician!.profilePhoto,
            bio: _myTechnician!.bio,
            experience: _myTechnician!.experience,
            rating: _myTechnician!.rating,
            hourlyRate: _myTechnician!.hourlyRate,
            distanceKm: _myTechnician!.distanceKm,
            area: _myTechnician!.area,
            latitude: latitude,
            longitude: longitude,
            isOnline: _myTechnician!.isOnline,
            verified: _myTechnician!.verified,
            services: _myTechnician!.services,
            serviceObjects: _myTechnician!.serviceObjects,
            portfolios: _myTechnician!.portfolios,
            // ─── PRESERVE NEW FIELDS ──────────────────────────────────
            completedJobsCount: _myTechnician!.completedJobsCount,
            priceRange: _myTechnician!.priceRange,
            servicePrices: _myTechnician!.servicePrices,
          );
        }
        _error = null;
      } else {
        _error = res.message;
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ─── Private helpers ───────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  void _handleListResponse(ApiResponse res) {
    if (res.success && res.data != null) {
      List dataList;

      if (res.data is Map) {
        if (res.data['technicians'] != null) {
          dataList = res.data['technicians'] as List;
        } else if (res.data['data'] != null) {
          dataList = res.data['data'] as List;
        } else {
          dataList = [];
        }

        if (res.data['search'] != null && res.data['search'] is Map) {
          final searchMeta = Map<String, dynamic>.from(res.data['search']);
          _searchMeta = searchMeta;
          final lat = searchMeta['latitude'];
          final lng = searchMeta['longitude'];
          if (lat != null && lng != null) {
            _searchLat = lat is num ? lat.toDouble() : double.tryParse('$lat');
            _searchLng = lng is num ? lng.toDouble() : double.tryParse('$lng');
          }
        }
      } else if (res.data is List) {
        dataList = res.data as List;
      } else {
        dataList = [];
      }

      _technicians = dataList
          .where((e) => e != null)
          .map((e) => Technician.fromJson(e, isDetail: false))
          .toList();
      _error = null;
    } else {
      _error = res.message;
      _technicians = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void _handlePlaceSearchResponse(ApiResponse res) {
    if (res.data != null) {
      final data = res.data;
      List rawList = [];
      Map<String, dynamic>? searchMeta;
      Map<String, dynamic>? filters;
      Map<String, dynamic>? meta;

      if (data is Map) {
        if (data['technicians'] != null) {
          rawList = data['technicians'] as List;
        } else if (data['data'] != null) {
          rawList = data['data'] as List;
        }

        if (data['search'] != null && data['search'] is Map) {
          searchMeta = Map<String, dynamic>.from(data['search'] as Map);
        }
        if (data['filters'] != null && data['filters'] is Map) {
          filters = Map<String, dynamic>.from(data['filters'] as Map);
        }
        if (data['meta'] != null && data['meta'] is Map) {
          meta = Map<String, dynamic>.from(data['meta'] as Map);
        }
      } else if (data is List) {
        rawList = data;
      }

      _technicians = rawList
          .where((e) => e != null)
          .map((e) => Technician.fromJson(e, isDetail: false))
          .toList();

      _searchMeta = searchMeta;
      _filters = filters;
      _meta = meta;

      if (searchMeta != null) {
        final lat = searchMeta['latitude'];
        final lng = searchMeta['longitude'];
        _searchLat = lat is num ? lat.toDouble() : double.tryParse('$lat');
        _searchLng = lng is num ? lng.toDouble() : double.tryParse('$lng');
        _searchPlace = searchMeta['place'] as String?;
      } else {
        _searchLat = null;
        _searchLng = null;
        _searchPlace = null;
      }

      if (_technicians.isEmpty) {
        if (meta != null) {
          final suggestions = meta['suggestions'] as List? ?? [];
          final totalNearby = meta['total_technicians_nearby'] ?? 0;
          final hasFilters = meta['has_filters'] ?? false;

          if (hasFilters && totalNearby > 0) {
            _error =
            'No technicians found with the selected filters. Try clearing filters or selecting a different service/category.';
          } else if (totalNearby == 0) {
            _error = res.message ??
                'No technicians found nearby. Try a different location.';
          } else {
            _error =
                res.message ?? 'No technicians found. Try adjusting your search.';
          }

          if (suggestions.isNotEmpty) {
            _error = _error! + '\n\n' + suggestions.join('\n• ');
          }
        } else {
          _error =
              res.message ?? 'No technicians found. Try adjusting your search.';
        }
      } else {
        _error = null;
      }
    } else {
      _error = res.message ?? 'Failed to search technicians.';
      _technicians = [];
      _searchLat = null;
      _searchLng = null;
      _searchPlace = null;
      _searchMeta = null;
      _filters = null;
      _meta = null;
    }
    _isLoading = false;
    notifyListeners();
  }
}