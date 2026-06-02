import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;

  Future<List<ShopProductModel>> getProducts({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final WardrobeCategory? wardrobeCategory,
    final UserLocation? userLocation,
  }) async {
    final String sortColumn;
    final bool isAscending;
    switch (sortOption) {
      case ProductSortOption.priceLowToHigh:
        sortColumn = 'price';
        isAscending = true;
      case ProductSortOption.priceHighToLow:
        sortColumn = 'price';
        isAscending = false;
      case ProductSortOption.latest:
        sortColumn = 'created_at';
        isAscending = false;
    }

    final response = await _supabaseClient.rpc(
      'get_shop_products',
      params: {
        'p_store_id': storeId,
        'p_search_query': (searchQuery == null || searchQuery.isEmpty)
            ? null
            : searchQuery,
        'p_category_ids': (categories == null || categories.isEmpty)
            ? null
            : categories.toList(),
        'p_min_price': minPrice,
        'p_max_price': maxPrice,
        'p_channels': _channelsParam(channels),
        'p_gender': gender?.value,
        'p_wardrobe_category': wardrobeCategory?.value,
        'p_sort_column': sortColumn,
        'p_sort_ascending': isAscending,
      },
    );

    var products = (response as List).map((final item) {
      final map = _withProductImageUrl(Map<String, dynamic>.from(item as Map));
      if (map['store_profiles'] != null) {
        map['store_profiles'] = _withStoreLogoUrl(
          Map<String, dynamic>.from(map['store_profiles'] as Map),
        );
      }
      return ShopProductModel.fromJson(map);
    }).toList();

    if (userLocation != null) {
      final sameDistrict = <ShopProductModel>[];
      final sameCity = <ShopProductModel>[];
      final otherCity = <ShopProductModel>[];

      for (final product in products) {
        if (userLocation.isSameDistrict(product.storeInfo.address)) {
          sameDistrict.add(product);
        } else if (userLocation.isSameCity(product.storeInfo.address)) {
          sameCity.add(product);
        } else {
          otherCity.add(product);
        }
      }

      products = [...sameDistrict, ...sameCity, ...otherCity];
    }

    return products;
  }

  static List<String>? _channelsParam(final Set<StoreChannel>? channels) {
    if (channels == null || channels.isEmpty) return null;
    if (channels.length == StoreChannel.values.length) return null;
    return StoreChannel.codesFromSet(channels);
  }

  Future<ShopProductModel> getProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('''
          *,
          product_variants(*),
          store_profiles!products_store_id_fkey(id, name, address, logo_path, channels)
        ''')
        .eq('id', productId)
        .single();

    final map = _withProductImageUrl(response);
    if (map['store_profiles'] != null) {
      map['store_profiles'] = _withStoreLogoUrl(map['store_profiles']);
    }

    return ShopProductModel.fromJson(map);
  }

  Future<Map<String, dynamic>> getStoreProfile(final String storeId) async {
    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select('id, name, address, logo_path, channels')
        .eq('id', storeId)
        .single();
    return _withStoreLogoUrl(response);
  }

  Map<String, dynamic> _withProductImageUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawPaths = map['image_paths'];
    final imagePaths = rawPaths != null ? List<String>.from(rawPaths) : <String>[];
    map['image_paths'] = imagePaths;
    map['image_urls'] = imagePaths.map(StoreImagesApi.publicUrl).toList();
    return map;
  }

  Map<String, dynamic> _withStoreLogoUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final logoPath = map['logo_path'] as String?;
    if (logoPath != null && logoPath.isNotEmpty) {
      map['logo_url'] = StoreImagesApi.publicUrl(logoPath);
    }
    return map;
  }
}
