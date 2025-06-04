import 'package:grocery_pantry/database/database_helper.dart';
import '../models/pantry_item.dart';

class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Add a new item to the pantry
  Future<void> addPantryItem(PantryItem item) async {
    await _dbHelper.insertPantryItem(item);
  }

  /// Get all pantry items sorted by added date (newest first)
  Future<List<PantryItem>> getAllItems() async {
    return await _dbHelper.getPantryItems();
  }

  /// Update an existing item
  Future<void> updatePantryItem(PantryItem item) async {
    await _dbHelper.updatePantryItem(item);
  }

  /// Delete a pantry item by ID
  Future<void> deletePantryItem(int id) async {
    await _dbHelper.deletePantryItem(id);
  }

  /// Get items that are expired
  Future<List<PantryItem>> getExpiredItems() async {
    final allItems = await getAllItems();
    return allItems.where((item) => item.isExpired).toList();
  }

  /// Get items expiring within 3 days
  Future<List<PantryItem>> getExpiringSoonItems() async {
    final allItems = await getAllItems();
    return allItems.where((item) => item.isExpiringSoon).toList();
  }

  /// Get items by category
  Future<List<PantryItem>> getItemsByCategory(String category) async {
    final allItems = await getAllItems();
    return allItems.where((item) => item.category == category).toList();
  }

  /// Search items by name (case-insensitive)
  Future<List<PantryItem>> searchItems(String query) async {
    final allItems = await getAllItems();
    return allItems
        .where((item) =>
            item.name.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
  }

  /// Get total item count
  Future<int> getItemCount() async {
    final items = await getAllItems();
    return items.length;
  }
}
