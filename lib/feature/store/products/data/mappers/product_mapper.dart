import 'package:tryzeon/core/data/mappers/size_measurements_mapper.dart';
import 'package:tryzeon/core/domain/entities/size_measurements.dart';

import '../collections/product_collection.dart';
import '../models/product_model.dart';

extension ProductModelMapper on ProductModel {
  ProductCollection toCollection() {
    return ProductCollection()
      ..productId = id ?? ''
      ..storeId = storeId
      ..name = name
      ..types = types.toList()
      ..price = price
      ..imagePath = imagePath
      ..imageUrl = imageUrl
      ..purchaseLink = purchaseLink
      ..tryonCount = tryonCount
      ..purchaseClickCount = purchaseClickCount
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..storeName = storeName
      ..sizes = sizes?.map((final e) {
        return ProductSizeModel(
          id: e.id,
          productId: e.productId,
          name: e.name,
          measurements: e.measurements,
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
        ).toCollection();
      }).toList();
  }
}

extension ProductCollectionMapper on ProductCollection {
  ProductModel toModel() {
    return ProductModel(
      storeId: storeId,
      name: name,
      types: types?.toSet() ?? {},
      price: price ?? 0.0,
      imagePath: imagePath ?? '',
      imageUrl: imageUrl ?? '',
      id: productId,
      purchaseLink: purchaseLink,
      tryonCount: tryonCount,
      purchaseClickCount: purchaseClickCount,
      sizes: sizes?.map((final e) => e.toModel()).toList(),
      storeName: storeName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ProductSizeModelMapper on ProductSizeModel {
  ProductSizeCollection toCollection() {
    return ProductSizeCollection()
      ..id = id
      ..productId = productId
      ..name = name
      ..measurements = measurements.toCollection()
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
  }
}

extension ProductSizeCollectionMapper on ProductSizeCollection {
  ProductSizeModel toModel() {
    return ProductSizeModel(
      id: id,
      productId: productId,
      name: name ?? '',
      measurements: measurements?.toModel() ?? const SizeMeasurements(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
