import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/service_call.dart';
import 'package:canteen_app/view/admin/admin_order_tracking_view.dart';
import 'package:flutter/material.dart';
import 'category_management_view.dart';
import 'about_management_view.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: ServiceCall.logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Management Sections",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            context,
            "Category Management",
            Icons.category,
            const CategoryManagementView(),
          ),
          const SizedBox(height: 15),
          _buildSectionCard(
            context,
            "Order Management",
            Icons.receipt_long,
            const AdminOrderTrackingView(),
          ),
          const SizedBox(height: 15),
          _buildSectionCard(
            context,
            "About Management",
            Icons.info,
            const AboutManagementView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget destination,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, size: 32, color: TColor.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => destination)),
      ),
    );
  }
}
