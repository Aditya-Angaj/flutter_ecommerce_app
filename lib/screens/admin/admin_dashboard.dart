import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import 'manage_products_screen.dart';
import 'manage_orders_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Consumer2<ProductProvider, OrderProvider>(
            builder: (context, productProvider, orderProvider, child) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Total Products',
                    value: '${productProvider.allProducts.length}',
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                  ),
                  _DashboardCard(
                    title: 'Pending Orders',
                    value: '${orderProvider.pendingOrdersCount}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _DashboardCard(
                    title: 'Total Orders',
                    value: '${orderProvider.allOrders.length}',
                    icon: Icons.receipt_long,
                    color: Colors.green,
                  ),
                  _DashboardCard(
                    title: 'Categories',
                    value: '${productProvider.categories.length - 1}', // Exclude "All"
                    icon: Icons.category,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _AdminMenuCard(
            title: 'Manage Products',
            subtitle: 'Add, edit, or remove products',
            icon: Icons.inventory_2,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageProductsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _AdminMenuCard(
            title: 'Manage Orders',
            subtitle: 'View and update order status',
            icon: Icons.shopping_cart,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageOrdersScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}