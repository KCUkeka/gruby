import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/pantry_item.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PantryItem> _pantryItems = [];
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  Future<void> _loadPantryItems() async {
    final items = await _dbHelper.getPantryItems();
    setState(() {
      _pantryItems = items;
    });
  }

  Future<void> _addPantryItem(String name, String category, int quantity, DateTime? expiryDate, {String? barcode}) async {
    final item = PantryItem(
      name: name,
      category: category,
      quantity: quantity,
      expiryDate: expiryDate,
      addedAt: DateTime.now(),
      barcode: barcode,
    );
    
    await _dbHelper.insertPantryItem(item);
    _loadPantryItems();
    _clearForm();
  }

  Future<void> _updatePantryItem(PantryItem item) async {
    await _dbHelper.updatePantryItem(item);
    _loadPantryItems();
  }

  Future<void> _deleteItem(int id) async {
    await _dbHelper.deletePantryItem(id);
    _loadPantryItems();
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

  void _clearForm() {
    _nameController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _selectedExpiryDate = null;
  }

  Future<void> _selectExpiryDate(StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setDialogState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _showAddItemDialog({String? barcode, PantryItem? editItem}) {
    if (editItem != null) {
      _nameController.text = editItem.name;
      _categoryController.text = editItem.category;
      _quantityController.text = editItem.quantity.toString();
      _selectedExpiryDate = editItem.expiryDate;
    } else {
      _clearForm();
      _quantityController.text = '1';
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editItem != null ? 'Edit Pantry Item' : 
                     barcode != null ? 'Add Scanned Item' : 'Add Pantry Item'),
          content: SingleChildScrollView(
            child: Column(
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
                    hintText: 'e.g., Canned Tomatoes, Rice, Pasta',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Canned Goods, Grains, Spices',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectExpiryDate(setDialogState),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (Optional)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedExpiryDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!)
                          : 'Select expiry date',
                      style: TextStyle(
                        color: _selectedExpiryDate != null ? null : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                if (_selectedExpiryDate != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: TextButton(
                      onPressed: () => setDialogState(() {
                        _selectedExpiryDate = null;
                      }),
                      child: Text('Clear expiry date'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && 
                    _categoryController.text.isNotEmpty &&
                    _quantityController.text.isNotEmpty) {
                  final quantity = int.tryParse(_quantityController.text) ?? 1;
                  
                  if (editItem != null) {
                    final updatedItem = editItem.copyWith(
                      name: _nameController.text,
                      category: _categoryController.text,
                      quantity: quantity,
                      expiryDate: _selectedExpiryDate,
                    );
                    _updatePantryItem(updatedItem);
                  } else {
                    _addPantryItem(
                      _nameController.text,
                      _categoryController.text,
                      quantity,
                      _selectedExpiryDate,
                      barcode: barcode,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(editItem != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(PantryItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Quantity'),
        content: TextField(
          controller: quantityController,
          decoration: InputDecoration(
            labelText: 'Quantity',
            hintText: item.quantity.toString(),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(quantityController.text) ?? item.quantity;
              if (newQuantity > 0) {
                final updatedItem = item.copyWith(quantity: newQuantity);
                _updatePantryItem(updatedItem);
              } else {
                _deleteItem(item.id!);
              }
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiredItems = _pantryItems.where((item) => item.isExpired).toList();
    final expiringSoonItems = _pantryItems.where((item) => item.isExpiringSoon && !item.isExpired).toList();
    final freshItems = _pantryItems.where((item) => !item.isExpired && !item.isExpiringSoon).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pantry'),
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
        onRefresh: _loadPantryItems,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            if (expiredItems.isNotEmpty) ...[
              _buildSectionHeader('Expired Items', expiredItems.length, Colors.red),
              ...expiredItems.map((item) => _buildPantryItemCard(item)),
              SizedBox(height: 16),
            ],
            
            if (expiringSoonItems.isNotEmpty) ...[
              _buildSectionHeader('Expiring Soon', expiringSoonItems.length, Colors.orange),
              ...expiringSoonItems.map((item) => _buildPantryItemCard(item)),
              SizedBox(height: 16),
            ],
            
            if (freshItems.isNotEmpty) ...[
              _buildSectionHeader('Fresh Items', freshItems.length, Colors.green),
              ...freshItems.map((item) => _buildPantryItemCard(item)),
            ],

            if (_pantryItems.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Your pantry is empty',
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

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 12),
          SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryItemCard(PantryItem item) {
    Color cardColor = Colors.white;
    Color borderColor = Colors.transparent;
    
    if (item.isExpired) {
      cardColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
    } else if (item.isExpiringSoon) {
      cardColor = Colors.orange[50]!;
      borderColor = Colors.orange[200]!;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ListTile(
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: item.isExpired ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.category),
            if (item.expiryDate != null)
              Text(
                'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}',
                style: TextStyle(
                  color: item.isExpired ? Colors.red : 
                         item.isExpiringSoon ? Colors.orange : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (item.barcode != null)
              Text('Barcode: ${item.barcode}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _showQuantityDialog(item),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddItemDialog(editItem: item);
                } else if (value == 'delete') {
                  _deleteItem(item.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}