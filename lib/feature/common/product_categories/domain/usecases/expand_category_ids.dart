import '../entities/product_category.dart';

/// Expands a set of selected category ids to include every descendant id
/// (at any depth) within the category tree.
///
/// Products are tagged on leaf categories, while the UI lets users pick a
/// parent (e.g. a wardrobe-aligned garment type). Expanding the selection
/// before querying lets the `category_ids && ...` overlap filter match
/// products tagged on any descendant leaf. The selected ids themselves are
/// always retained (some products may be tagged directly on a parent).
class ExpandCategoryIds {
  Set<String> call(
    final List<ProductCategory> allCategories,
    final Set<String> selectedIds,
  ) {
    if (selectedIds.isEmpty) return selectedIds;

    final childrenByParent = <String, List<String>>{};
    for (final category in allCategories) {
      final parentId = category.parentId;
      if (parentId != null) {
        childrenByParent.putIfAbsent(parentId, () => []).add(category.id);
      }
    }

    final expanded = <String>{};
    final stack = <String>[...selectedIds];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (!expanded.add(id)) continue; // already visited; also breaks cycles
      final children = childrenByParent[id];
      if (children != null) stack.addAll(children);
    }
    return expanded;
  }
}
