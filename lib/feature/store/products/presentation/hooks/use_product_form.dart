import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_category_measurements.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/image_item.dart';

class ProductFormData {
  ProductFormData({
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.purchaseLinkController,
    required this.selectedGender,
    required this.selectedMaterial,
    required this.selectedFit,
    required this.images,
    required this.selectedCategoryIds,
    required this.selectedElasticity,
    required this.selectedThickness,
    required this.selectedStyles,
    required this.selectedSeasons,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController purchaseLinkController;
  final ValueNotifier<ProductGender?> selectedGender;
  final ValueNotifier<String?> selectedMaterial;
  final ValueNotifier<ProductFit?> selectedFit;
  final ValueNotifier<List<ImageItem>> images;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductThickness?> selectedThickness;
  final ValueNotifier<Set<ClothingStyle>?> selectedStyles;
  final ValueNotifier<Set<ProductSeason>?> selectedSeasons;

  bool validate(final BuildContext context) {
    return formKey.currentState?.validate() ?? false;
  }

  /// Extract only new images (files pending upload)
  List<File> get newImageFiles =>
      images.value.whereType<NewImageItem>().map((final e) => e.file).toList();

  /// The garment dimensions the size editor should show (and the submit flow
  /// should collect) for the currently selected categories.
  ///
  /// Falls back to every dimension when the selection gives no signal — no
  /// category picked yet, or [allCategories] not loaded.
  List<GarmentMeasurementType> visibleMeasurementTypes(
    final List<ProductCategory> allCategories,
  ) {
    final selected = allCategories.where(
      (final c) => selectedCategoryIds.value.contains(c.id),
    );
    return relevantMeasurementTypesFor(selected.map((final c) => c.wardrobeCategory));
  }

  ProductDraft toDraft() {
    return ProductDraft(
      name: nameController.text,
      categoryIds: selectedCategoryIds.value,
      price: double.parse(priceController.text),
      gender: selectedGender.value!,
      purchaseLink: purchaseLinkController.text.isNotEmpty
          ? purchaseLinkController.text
          : null,
      material: selectedMaterial.value,
      elasticity: selectedElasticity.value,
      fit: selectedFit.value,
      thickness: selectedThickness.value,
      styles: selectedStyles.value,
      seasons: selectedSeasons.value,
    );
  }

  /// Pre-fills empty fields from an analysis result.
  void applyAnalysis(final ProductAnalysisResult r) {
    if (nameController.text.trim().isEmpty && (r.name?.isNotEmpty ?? false)) {
      nameController.text = r.name!;
    }
    if (selectedCategoryIds.value.isEmpty && r.categoryIds.isNotEmpty) {
      selectedCategoryIds.value = r.categoryIds.toSet();
    }
    if (selectedGender.value == null && r.gender != null) {
      selectedGender.value = r.gender;
    }
    if (selectedThickness.value == null && r.thickness != null) {
      selectedThickness.value = r.thickness;
    }
    if (selectedElasticity.value == null && r.elasticity != null) {
      selectedElasticity.value = r.elasticity;
    }
    if ((selectedStyles.value?.isEmpty ?? true) && r.styles.isNotEmpty) {
      selectedStyles.value = r.styles.toSet();
    }
    if ((selectedSeasons.value?.isEmpty ?? true) && r.seasons.isNotEmpty) {
      selectedSeasons.value = r.seasons.toSet();
    }
    if ((selectedMaterial.value?.isEmpty ?? true) && (r.material?.isNotEmpty ?? false)) {
      selectedMaterial.value = r.material;
    }
    if (selectedFit.value == null && r.fit != null) {
      selectedFit.value = r.fit;
    }
  }
}

ProductFormData useProductForm({final Product? initialProduct}) {
  final formKey = useMemoized(GlobalKey<FormState>.new);
  final nameController = useTextEditingController(text: initialProduct?.name);
  final priceController = useTextEditingController(
    text: initialProduct?.price.toInt().toString(),
  );
  final purchaseLinkController = useTextEditingController(
    text: initialProduct?.purchaseLink,
  );
  // Null until the store owner picks one (required, validated on submit). Edit
  // flow seeds the existing product's gender, which is always set.
  final selectedGender = useValueNotifier<ProductGender?>(initialProduct?.gender);
  final selectedMaterial = useValueNotifier<String?>(initialProduct?.material);
  final selectedFit = useValueNotifier<ProductFit?>(initialProduct?.fit);

  final initialImages = useMemoized(() {
    if (initialProduct == null) return <ImageItem>[];
    final paths = initialProduct.imagePaths;
    final urls = initialProduct.imageUrls;
    return List.generate(
      paths.length,
      (final i) => ImageItem.existing(path: paths[i], url: urls[i]),
    );
  });

  final images = useState<List<ImageItem>>(initialImages);

  final selectedCategoryIds = useValueNotifier<Set<String>>(
    initialProduct?.categoryIds.toSet() ?? {},
  );
  final selectedElasticity = useValueNotifier<ProductElasticity?>(
    initialProduct?.elasticity,
  );
  final selectedThickness = useValueNotifier<ProductThickness?>(
    initialProduct?.thickness,
  );
  final selectedStyles = useValueNotifier<Set<ClothingStyle>?>(initialProduct?.styles);
  final selectedSeasons = useValueNotifier<Set<ProductSeason>?>(initialProduct?.seasons);

  return ProductFormData(
    formKey: formKey,
    nameController: nameController,
    priceController: priceController,
    purchaseLinkController: purchaseLinkController,
    selectedGender: selectedGender,
    selectedMaterial: selectedMaterial,
    selectedFit: selectedFit,
    images: images,
    selectedCategoryIds: selectedCategoryIds,
    selectedElasticity: selectedElasticity,
    selectedThickness: selectedThickness,
    selectedStyles: selectedStyles,
    selectedSeasons: selectedSeasons,
  );
}
