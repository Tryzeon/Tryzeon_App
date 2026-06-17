import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
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
    final String? material,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<String>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
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
      'list_shop_products',
      params: buildListProductsParams(
        storeId: storeId,
        searchQuery: searchQuery,
        sortColumn: sortColumn,
        sortAscending: isAscending,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: categories,
        channels: channels,
        gender: gender,
        material: material,
        elasticities: elasticities,
        fits: fits,
        thicknesses: thicknesses,
        styles: styles,
        seasons: seasons,
        limit: limit,
        offset: offset,
      ),
    );

    return (response as List).map((final item) {
      final map = _withProductImageUrl(Map<String, dynamic>.from(item as Map));
      if (map['store_profiles'] != null) {
        map['store_profiles'] = _withStoreLogoUrl(
          Map<String, dynamic>.from(map['store_profiles'] as Map),
        );
      }
      return ShopProductModel.fromJson(map);
    }).toList();
  }

  static Map<String, dynamic> buildListProductsParams({
    final String? storeId,
    final String? searchQuery,
    required final String sortColumn,
    required final bool sortAscending,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final String? material,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<String>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
  }) {
    List<String>? nonEmpty(final Iterable<String>? values) {
      if (values == null || values.isEmpty) return null;
      return values.toList();
    }

    return {
      'p_store_id': storeId,
      'p_search_query': (searchQuery == null || searchQuery.isEmpty)
          ? null
          : searchQuery,
      'p_category_ids': nonEmpty(categories),
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_channels': _channelsParam(channels),
      'p_gender': gender?.value,
      'p_material': (material == null || material.isEmpty) ? null : material,
      'p_elasticities': nonEmpty(elasticities?.map((final e) => e.value)),
      'p_fits': nonEmpty(fits),
      'p_thicknesses': nonEmpty(thicknesses?.map((final e) => e.value)),
      'p_styles': nonEmpty(styles),
      'p_seasons': nonEmpty(seasons?.map((final e) => e.value)),
      'p_sort_column': sortColumn,
      'p_sort_ascending': sortAscending,
      'p_limit': limit,
      'p_offset': offset,
    };
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
