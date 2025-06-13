import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../models/pantry_item.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final SupabaseService _svc = SupabaseService();
  List<PantryItem> _pantryItems = [];
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  DateTime? _selectedExpiryDate;

  @override
  void initState() {
    super.initState();
    _loadPantryItems();
  }

  Future<void> _loadPantryItems() async {
    final items = await _svc.getPantryItems();
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
    await _svc.addPantryItem(item);
    await _loadPantryItems();
    _clearForm();
  }

  Future<void> _updatePantryItem(PantryItem item) async {
    await _svc.updatePantryItem(item);
    await _loadPantryItems();
  }

  Future<void> _deleteItem(String id) async {
    await _svc.deletePantryItem(id);
    await _loadPantryItems();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: \$e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _categoryController.clear();
    _quantityController.text = '1';
    _selectedExpiryDate = null;
  }

  Future<void> _selectExpiryDate(StateSetter setDialogState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setDialogState(() => _selectedExpiryDate = picked);
  }

  void _showAddItemDialog({String? barcode, PantryItem? editItem}) {
    if (editItem != null) {
      _nameController.text = editItem.name;
      _categoryController.text = editItem.category;
      _quantityController.text = editItem.quantity.toString();
      _selectedExpiryDate = editItem.expiryDate;
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editItem != null
              ? 'Edit Pantry Item'
              : barcode != null
                  ? 'Add Scanned Item'
                  : 'Add Pantry Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (barcode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Barcode: \$barcode', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectExpiryDate(setDialogState),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry Date (Optional)', suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(
                      _selectedExpiryDate != null
                          ? DateFormat('MMM dd, yyyy').format(_selectedExpiryDate!)
                          : 'Select expiry date',
                      style: TextStyle(color: _selectedExpiryDate != null ? Colors.black : Colors.grey[600]),
                    ),
                  ),
                ),
                if (_selectedExpiryDate != null)
                  TextButton(
                    onPressed: () => setDialogState(() => _selectedExpiryDate = null),
                    child: const Text('Clear expiry date'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); _clearForm(); }, child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final cat = _categoryController.text.trim();
                final qty = int.tryParse(_quantityController.text) ?? 1;
                if (name.isNotEmpty && cat.isNotEmpty) {
                  if (editItem != null) {
                    final updated = editItem.copyWith(
                      name: name,
                      category: cat,
                      quantity: qty,
                      expiryDate: _selectedExpiryDate,
                    );
                    _updatePantryItem(updated);
                  } else {
                    _addPantryItem(name, cat, qty, _selectedExpiryDate, barcode: barcode);
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

  @override
  Widget build(BuildContext context) {
    final expired = _pantryItems.where((i) => i.isExpired).toList();
    final soon = _pantryItems.where((i) => i.isExpiringSoon && !i.isExpired).toList();
    final fresh = _pantryItems.where((i) => !i.isExpired && !i.isExpiringSoon).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPantryItems,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (expired.isNotEmpty) ...[
              _buildSectionHeader('Expired Items', expired.length, Colors.red),
              ...expired.map(_buildPantryItemCard),
              const SizedBox(height: 16),
            ],
            if (soon.isNotEmpty) ...[
              _buildSectionHeader('Expiring Soon', soon.length, Colors.orange),
              ...soon.map(_buildPantryItemCard),
              const SizedBox(height: 16),
            ],
            if (fresh.isNotEmpty) ...[
              _buildSectionHeader('Fresh Items', fresh.length, Colors.green),
              ...fresh.map(_buildPantryItemCard),
            ],
            if (_pantryItems.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Your pantry is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Add items using the + button or scan barcodes', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
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

  Widget _buildSectionHeader(String title, int count, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [Icon(Icons.circle, color: color, size: 12), const SizedBox(width: 8),
            Text('$title ($count)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );

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
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: borderColor, width: 1)),
      child: ListTile(
        title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w500, decoration: item.isExpired ? TextDecoration.lineThrough : null)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.category),
          if (item.expiryDate != null)
            Text('Expires: ${DateFormat('MMM dd, yyyy').format(item.expiryDate!)}', style: TextStyle(color: item.isExpired ? Colors.red : item.isExpiringSoon ? Colors.orange : Colors.grey[600], fontWeight: FontWeight.w500)),
          if (item.barcode != null) Text('Barcode: ${item.barcode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          InkWell(onTap: () => _showQuantityDialog(item), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)), child: Text('Qty: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)))),
          const SizedBox(width: 8),
          PopupMenuButton(itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Row(children: const [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])), PopupMenuItem(value: 'delete', child: Row(children: const [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]))], onSelected: (v) { if (v == 'edit') _showAddItemDialog(editItem: item); else _deleteItem(item.id!); }),
        ]),
      ),
    );
  }

  void _showQuantityDialog(PantryItem item) {
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Update Quantity'), content: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity', hintText: item.quantity.toString()), autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () { final newQty = int.tryParse(qtyCtrl.text) ?? item.quantity; if (newQty > 0) _updatePantryItem(item.copyWith(quantity: newQty)); else _deleteItem(item.id!); Navigator.pop(context); }, child: const Text('Update'))]));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}
