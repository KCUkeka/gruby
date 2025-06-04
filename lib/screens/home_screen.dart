import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/pantry_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<PantryItem> _expiringSoonItems = [];
  int _totalGroceryItems = 0;
  int _totalPantryItems = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final expiringSoon = await _dbHelper.getExpiringSoonItems();
    final groceryItems = await _dbHelper.getGroceryItems();
    final pantryItems = await _dbHelper.getPantryItems();

    setState(() {
      _expiringSoonItems = expiringSoon;
      _totalGroceryItems = groceryItems.where((item) => !item.isPurchased).length;
      _totalPantryItems = pantryItems.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery & Pantry Tracker'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
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
              SizedBox(height: 20),
              
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Shopping List',
                      '$_totalGroceryItems items',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pantry Items',
                      '$_totalPantryItems items',
                      Icons.kitchen,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Expiring Soon Section
              Center(
                child: Text(
                  'Items Expiring Soon',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 12),
              
              if (_expiringSoonItems.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
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
                  children: _expiringSoonItems.map((item) => _buildExpiringItemCard(item)).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
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
    );
  }

  Widget _buildExpiringItemCard(PantryItem item) {
    final daysUntilExpiry = item.expiryDate!.difference(DateTime.now()).inDays;
    final isExpired = daysUntilExpiry < 0;
    final urgencyColor = isExpired ? Colors.red : (daysUntilExpiry <= 1 ? Colors.orange : Colors.yellow[700]!);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
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
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, int count, Color color, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
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
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    ),
  );
}

}