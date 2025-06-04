import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../database/database_helper.dart';
import '../models/grocery_item.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
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
    final items = await _dbHelper.getGroceryItems();
    setState(() {
      _groceryItems = items;
    });
  }

  Future<void> _addGroceryItem(String name, String category, {String? barcode}) async {
    final item = GroceryItem(
      name: name,
      category: category,
      createdAt: DateTime.now(),
      barcode: barcode,
    );
    
    await _dbHelper.insertGroceryItem(item);
    _loadGroceryItems();
    _nameController.clear();
    _categoryController.clear();
  }

  Future<void> _togglePurchased(GroceryItem item) async {
    final updatedItem = item.copyWith(isPurchased: !item.isPurchased);
    await _dbHelper.updateGroceryItem(updatedItem);
    
    if (updatedItem.isPurchased) {
      await _dbHelper.addToPurchaseHistory(item.name, item.category, item.barcode);
    }
    
    _loadGroceryItems();
  }

  Future<void> _deleteItem(int id) async {
    await _dbHelper.deleteGroceryItem(id);
    _loadGroceryItems();
  }

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );
      
      if (barcodeScanRes != '-1') {
        _showAddItemDialog(barcode: barcodeScanRes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: $e')),
      );
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length > 1) {
      final suggestions = await _dbHelper.getSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  void _showAddItemDialog({String? barcode}) {
    _nameController.clear();
    _categoryController.clear();
    _suggestions = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(barcode != null ? 'Add Scanned Item' : 'Add Grocery Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (barcode != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Barcode: $barcode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Milk, Bread, Apples',
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
                    itemBuilder: (context, index) => ListTile(
                      dense: true,
                      title: Text(_suggestions[index]),
                      onTap: () {
                        _nameController.text = _suggestions[index];
                        setDialogState(() {
                          _suggestions = [];
                        });
                      },
                    ),
                  ),
                ),
              SizedBox(height: 8),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Dairy, Produce, Meat',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _categoryController.text.isNotEmpty) {
                  _addGroceryItem(_nameController.text, _categoryController.text, barcode: barcode);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpurchasedItems = _groceryItems.where((item) => !item.isPurchased).toList();
    final purchasedItems = _groceryItems.where((item) => item.isPurchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroceryItems,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (unpurchasedItems.isNotEmpty) ...[
              Text(
                'To Buy (${unpurchasedItems.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...unpurchasedItems.map((item) => _buildGroceryItemCard(item)),
              SizedBox(height: 16),
            ],
            
            if (purchasedItems.isNotEmpty) ...[
              Text(
                'Purchased (${purchasedItems.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              ...purchasedItems.map((item) => _buildGroceryItemCard(item)),
            ],

            if (_groceryItems.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Your shopping list is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add items using the + button or scan barcodes',
                      style: TextStyle(color: Colors.grey[500]),
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
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroceryItemCard(GroceryItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
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
              Text('Barcode: ${item.barcode}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
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