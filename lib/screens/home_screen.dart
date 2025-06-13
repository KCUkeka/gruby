import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/pantry_item.dart';
import '../models/grocery_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _svc = SupabaseService();
  List<PantryItem> _expiringSoonItems = [];
  List<GroceryItem> _unpurchasedGroceries = [];
  List<PantryItem> _pantryItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final expiringSoon = await _svc.getExpiringSoonItems();
    final groceries = await _svc.getGroceryItems();
    final pantry = await _svc.getPantryItems();
    setState(() {
      _expiringSoonItems = expiringSoon;
      _unpurchasedGroceries = groceries.where((g) => !g.isPurchased).toList();
      _pantryItems = pantry;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Shopping List',
                      '${_unpurchasedGroceries.length} items',
                      Icons.shopping_cart,
                      Colors.blue,
                      onTap: () {
                        // Navigate to GroceryListScreen
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pantry Items',
                      '${_pantryItems.length} items',
                      Icons.kitchen,
                      Colors.orange,
                      onTap: () {
                        // Navigate to PantryScreen
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Expiring Soon Section
              Center(
                child: Text(
                  'Items Expiring Soon',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 12),

              if (_expiringSoonItems.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No items expiring soon. Great job managing your pantry!',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _expiringSoonItems
                      .map((item) => _buildExpiringItemCard(item))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiringItemCard(PantryItem item) {
    final daysUntilExpiry = item.expiryDate!.difference(DateTime.now()).inDays;
    final isExpired = daysUntilExpiry < 0;
    final urgencyColor = isExpired
        ? Colors.red
        : (daysUntilExpiry <= 1 ? Colors.orange : Colors.yellow[700]!);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: urgencyColor,
          child: Icon(
            isExpired ? Icons.warning : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(item.name),
        subtitle: Text(
          isExpired
              ? 'Expired ${-daysUntilExpiry} days ago'
              : daysUntilExpiry == 0
                  ? 'Expires today'
                  : 'Expires in $daysUntilExpiry days',
        ),
        trailing: Text(
          'Qty: ${item.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
