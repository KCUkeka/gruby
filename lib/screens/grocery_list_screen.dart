import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../models/grocery_item.dart';
import '../services/supabase_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final SupabaseService _svc = SupabaseService();
  List<GroceryItem> _groceryItems = [];
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadGroceryItems();
  }

  Future<void> _loadGroceryItems() async {
    final items = await _svc.getGroceryItems();
    setState(() {
      _groceryItems = items;
    });
  }

  Future<void> _addGroceryItem(
    String name,
    String category, {
    String? barcode,
  }) async {
    final item = GroceryItem(
      name: name,
      category: category,
      createdAt: DateTime.now(),
      barcode: barcode,
    );
    await _svc.addGroceryItem(item);
    await _svc.addToPurchaseHistory(name, category, barcode);
    _nameController.clear();
    _categoryController.clear();
    await _loadGroceryItems();
  }

  Future<void> _togglePurchased(GroceryItem item) async {
    final updated = item.copyWith(isPurchased: !item.isPurchased);
    await _svc.updateGroceryItem(updated);
    if (updated.isPurchased) {
      await _svc.addToPurchaseHistory(item.name, item.category, item.barcode);
    }
    await _loadGroceryItems();
  }

  Future<void> _deleteItem(String id) async {
    await _svc.deleteGroceryItem(id);
    await _loadGroceryItems();
  }

  Future<void> _scanBarcode() async {
    try {
      final barcodeRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );
      if (barcodeRes != '-1') _showAddItemDialog(barcode: barcodeRes);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to scan barcode: \$e')));
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length > 1) {
      final suggestions = await _svc.getSuggestions(query);
      setState(() => _suggestions = suggestions);
    } else {
      setState(() => _suggestions = []);
    }
  }

  void _showAddItemDialog({String? barcode}) {
    _nameController.clear();
    _categoryController.clear();
    _suggestions = [];
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    barcode != null ? 'Add Scanned Item' : 'Add Grocery Item',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (barcode != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Barcode: \$barcode',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                        ),
                        onChanged: (value) async {
                          await _getSuggestions(value);
                          setDialogState(() {});
                        },
                      ),
                      if (_suggestions.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            itemCount: _suggestions.length,
                            itemBuilder:
                                (context, index) => ListTile(
                                  dense: true,
                                  title: Text(_suggestions[index]),
                                  onTap: () {
                                    _nameController.text = _suggestions[index];
                                    setDialogState(() => _suggestions = []);
                                  },
                                ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final cat = _categoryController.text.trim();
                        if (name.isNotEmpty && cat.isNotEmpty) {
                          _addGroceryItem(name, cat, barcode: barcode);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpurchased = _groceryItems.where((i) => !i.isPurchased).toList();
    final purchased = _groceryItems.where((i) => i.isPurchased).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroceryItems,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (unpurchased.isNotEmpty) ...[
              Text(
                'To Buy (${unpurchased.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...unpurchased.map(_buildGroceryItemCard),
              const SizedBox(height: 16),
            ],
            if (purchased.isNotEmpty) ...[
              Text(
                'Purchased (\${purchased.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ...purchased.map(_buildGroceryItemCard),
            ],
            if (_groceryItems.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your shopping list is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add items using the + button or scan barcodes',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroceryItemCard(GroceryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (_) => _togglePurchased(item),
          activeColor: Colors.green,
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category),
            if (item.barcode != null)
              Text(
                'Barcode: \${item.barcode}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteItem(item.id!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
