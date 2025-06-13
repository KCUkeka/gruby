import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grocery_item.dart';
import '../models/pantry_item.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // ─── Grocery Items ───────────────────────────────────────────

  Future<void> addGroceryItem(GroceryItem item) =>
      _client.from('grocery_items').insert(item.toMap());

  Future<List<GroceryItem>> getGroceryItems() async {
    final data = await _client
        .from('grocery_items')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => GroceryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateGroceryItem(GroceryItem item) =>
      _client.from('grocery_items').update(item.toMap()).eq('id', item.id as Object);

  Future<void> deleteGroceryItem(String id) =>
      _client.from('grocery_items').delete().eq('id', id);

  Future<List<String>> getSuggestions(String query) async {
    final data = await _client
        .from('purchase_history')
        .select('name')
        .ilike('name', '$query%')
        .order('purchase_date', ascending: false)
        .limit(5);
    return (data as List).map((e) => e['name'] as String).toList();
  }

  Future<void> addToPurchaseHistory(String name, String category, String? barcode) =>
      _client.from('purchase_history').insert({
        'name': name,
        'category': category,
        'purchase_date': DateTime.now().toIso8601String(),
        'barcode': barcode,
      });

  // ─── Pantry Items ────────────────────────────────────────────

  Future<void> addPantryItem(PantryItem item) =>
      _client.from('pantry_items').insert(item.toMap());

  Future<List<PantryItem>> getPantryItems() async {
    final data = await _client
        .from('pantry_items')
        .select()
        .order('added_at', ascending: false);
    return (data as List)
        .map((e) => PantryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePantryItem(PantryItem item) =>
      _client.from('pantry_items').update(item.toMap()).eq('id', item.id as Object);

  Future<void> deletePantryItem(String id) =>
      _client.from('pantry_items').delete().eq('id', id);

  Future<List<PantryItem>> getExpiringSoonItems() async {
    final now = DateTime.now().toIso8601String();
    final soon = DateTime.now().add(Duration(days: 3)).toIso8601String();
    final data = await _client
        .from('pantry_items')
        .select()
        .gte('expiry_date', now)
        .lte('expiry_date', soon)
        .order('expiry_date', ascending: true);
    return (data as List)
        .map((e) => PantryItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
