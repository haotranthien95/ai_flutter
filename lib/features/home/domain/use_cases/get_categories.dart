import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/core/models/category.dart';

/// Use case for fetching categories
///
/// Encapsulates business logic for retrieving product categories
/// in hierarchical structure (root categories and subcategories).
class GetCategoriesUseCase {
  final ProductRepository _repository;

  GetCategoriesUseCase(this._repository);

  /// Executes the use case to fetch all categories
  ///
  /// Returns hierarchical list of categories:
  /// - Root categories (level 0, parentId == null)
  /// - Subcategories (level 1, parentId points to parent)
  ///
  /// Maximum hierarchy depth: 2 levels (root → subcategory)
  ///
  /// Returns list of all categories sorted by sortOrder
  ///
  /// Throws:
  /// - [NetworkException] on network errors
  /// - [ServerException] on server errors
  Future<List<Category>> execute() async {
    // Fetch all categories from repository
    final categories = await _repository.getCategories();

    // Sort categories by sortOrder
    categories.sort((a, b) {
      // First sort by level (root categories first)
      if (a.level != b.level) {
        return a.level.compareTo(b.level);
      }
      // Then by sortOrder within the same level
      return a.sortOrder.compareTo(b.sortOrder);
    });

    return categories;
  }

  /// Fetches only root categories (level 0)
  ///
  /// Useful for displaying top-level category navigation
  Future<List<Category>> getRootCategories() async {
    final allCategories = await execute();
    return allCategories.where((category) => category.isRoot).toList();
  }

  /// Fetches subcategories for a specific parent category
  ///
  /// Parameters:
  /// - [parentId]: The ID of the parent category
  ///
  /// Returns list of subcategories under the specified parent
  ///
  /// Throws:
  /// - [ArgumentError] if parentId is empty
  Future<List<Category>> getSubcategories(String parentId) async {
    if (parentId.isEmpty) {
      throw ArgumentError('Parent ID cannot be empty');
    }

    final allCategories = await execute();
    return allCategories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  /// Fetches only active categories
  ///
  /// Filters out inactive categories that should not be displayed
  Future<List<Category>> getActiveCategories() async {
    final allCategories = await execute();
    return allCategories.where((category) => category.isActive).toList();
  }
}
