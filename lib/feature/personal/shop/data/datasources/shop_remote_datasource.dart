import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/models/product_row_mapper.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = AppConstants.tableProducts;
  static const _storeProfileTable = AppConstants.tableStoreProfiles;

  Future<List<ShopProductModel>> listProducts({
    final String? storeId,
    final String? searchQuery,
    final ShopSort sort = const ShopSort.latest(),
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final Set<String>? materials,
    final Set<ProductElasticity>? elasticities,
    final Set<ProductFit>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<ClothingStyle>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
  }) async {
    final (:column, :ascending) = sortParams(sort);
    final (userLat, userLng) = switch (sort) {
      ShopSortProximity(:final latitude, :final longitude) => (latitude, longitude),
      _ => (null, null),
    };

    final response = await _supabaseClient.rpc<List<dynamic>>(
      'list_shop_products',
      params: buildListProductsParams(
        storeId: storeId,
        searchQuery: searchQuery,
        sortColumn: column,
        sortAscending: ascending,
        userLatitude: userLat,
        userLongitude: userLng,
        minPrice: minPrice,
        maxPrice: maxPrice,
        categories: categories,
        channels: channels,
        gender: gender,
        materials: materials,
        elasticities: elasticities,
        fits: fits,
        thicknesses: thicknesses,
        styles: styles,
        seasons: seasons,
        limit: limit,
        offset: offset,
      ),
    );

    return response.map((final item) {
      final map = productRowWithImageUrls(
        Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
      );
      return ShopProductModel.fromJson(map);
    }).toList();
  }

  static ({String column, bool ascending}) sortParams(final ShopSort sort) {
    return switch (sort) {
      ShopSortLatest() => (column: 'created_at', ascending: false),
      ShopSortPriceLowToHigh() => (column: 'price', ascending: true),
      ShopSortPriceHighToLow() => (column: 'price', ascending: false),
      ShopSortProximity() => (column: 'proximity', ascending: true),
    };
  }

  static Map<String, dynamic> buildListProductsParams({
    final String? storeId,
    final String? searchQuery,
    required final String sortColumn,
    required final bool sortAscending,
    final double? userLatitude,
    final double? userLongitude,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final Set<String>? materials,
    final Set<ProductElasticity>? elasticities,
    final Set<ProductFit>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<ClothingStyle>? styles,
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
      'p_search_query': (searchQuery == null || searchQuery.isEmpty) ? null : searchQuery,
      'p_category_ids': nonEmpty(categories),
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_channels': _channelsParam(channels),
      'p_gender': gender?.value,
      'p_materials': nonEmpty(materials),
      'p_elasticities': nonEmpty(elasticities?.map((final e) => e.value)),
      'p_fits': nonEmpty(fits?.map((final e) => e.value)),
      'p_thicknesses': nonEmpty(thicknesses?.map((final e) => e.value)),
      'p_styles': nonEmpty(styles?.map((final e) => e.value)),
      'p_seasons': nonEmpty(seasons?.map((final e) => e.value)),
      'p_sort_column': sortColumn,
      'p_sort_ascending': sortAscending,
      'p_user_lat': userLatitude,
      'p_user_lng': userLongitude,
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
          product_sizes(*),
          store_profiles!products_store_id_fkey(id, name, slug, address, logo_path, channels)
        ''')
        .eq('id', productId)
        .single();

    final map = productRowWithImageUrls(Map<String, dynamic>.from(response));
    return ShopProductModel.fromJson(map);
  }

  /// Both the uuid and the slug form back the same `/store/...` deep link, so
  /// existing uuid links keep working.
  Future<Map<String, dynamic>> getStoreProfile(final String storeIdOrSlug) async {
    final column = _uuidPattern.hasMatch(storeIdOrSlug) ? 'id' : 'slug';
    final response = await _supabaseClient
        .from(_storeProfileTable)
        .select('id, name, slug, address, logo_path, channels')
        .eq(column, storeIdOrSlug)
        .single();
    return withStoreLogoUrl(response);
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
}
