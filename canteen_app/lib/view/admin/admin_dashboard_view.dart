import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'restaurant_management_view.dart';
import 'menu_management_view.dart';
import 'category_management_view.dart';
import 'offer_management_view.dart';
import 'about_management_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildManagementCard(
                "Restaurant Management",
                "Manage restaurants and their details",
                Icons.restaurant,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestaurantManagementView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildManagementCard(
                "Menu Management",
                "Manage menu items and prices",
                Icons.menu_book,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MenuManagementView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildManagementCard(
                "Category Management",
                "Manage food categories",
                Icons.category,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryManagementView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildManagementCard(
                "Offer Management",
                "Manage special offers and discounts",
                Icons.local_offer,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfferManagementView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildManagementCard(
                "About Management",
                "Manage about section content",
                Icons.info,
                () {
                  // Navigator.push(
                  // context,
                  // MaterialPageRoute(
                  // builder: (context) => const AboutManagementView(),
                  // ),
                  // );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          size: 40,
          color: TColor.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: TColor.secondaryText,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
