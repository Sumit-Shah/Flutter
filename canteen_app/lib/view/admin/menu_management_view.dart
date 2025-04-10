import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      // Fetch menu items
      final menuResponse = await http.get(
        Uri.parse('${SVKey.baseUrl}menu_items'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch categories
      final categoryResponse = await http.get(
        Uri.parse('${SVKey.baseUrl}categories'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch restaurants
      final restaurantResponse = await http.get(
        Uri.parse('${SVKey.baseUrl}restaurants'),
        headers: {'Content-Type': 'application/json'},
      );

      if (menuResponse.statusCode == 200 &&
          categoryResponse.statusCode == 200 &&
          restaurantResponse.statusCode == 200) {
        final menuObj = json.decode(menuResponse.body);
        final categoryObj = json.decode(categoryResponse.body);
        final restaurantObj = json.decode(restaurantResponse.body);

        if (menuObj[KKey.status] == "1" &&
            categoryObj[KKey.status] == "1" &&
            restaurantObj[KKey.status] == "1") {
          setState(() {
            menuItems = List<Map<String, dynamic>>.from(menuObj[KKey.payload]);
            categories =
                List<Map<String, dynamic>>.from(categoryObj[KKey.payload]);
            restaurants =
                List<Map<String, dynamic>>.from(restaurantObj[KKey.payload]);
            isLoading = false;
          });
        }
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditMenuItemDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = menuItems[index];
                return Card(
                  child: ListTile(
                    title: Text(menuItem['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price: \$${menuItem['price']}'),
                        Text(
                            'Category: ${_getCategoryName(menuItem['category_id'])}'),
                        Text(
                            'Restaurant: ${_getRestaurantName(menuItem['restaurant_id'])}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAddEditMenuItemDialog(menuItem: menuItem);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(menuItem['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _getCategoryName(int categoryId) {
    final category = categories.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {'name': 'Unknown'},
    );
    return category['name'];
  }

  String _getRestaurantName(int restaurantId) {
    final restaurant = restaurants.firstWhere(
      (r) => r['id'] == restaurantId,
      orElse: () => {'name': 'Unknown'},
    );
    return restaurant['name'];
  }

  void _showAddEditMenuItemDialog({Map<String, dynamic>? menuItem}) {
    final nameController = TextEditingController(text: menuItem?['name']);
    final priceController =
        TextEditingController(text: menuItem?['price']?.toString());
    final descriptionController =
        TextEditingController(text: menuItem?['description']);
    int? selectedCategoryId = menuItem?['category_id'];
    int? selectedRestaurantId = menuItem?['restaurant_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(menuItem == null ? 'Add Menu Item' : 'Edit Menu Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundTextfield(
                hintText: "Name",
                controller: nameController,
              ),
              const SizedBox(height: 10),
              RoundTextfield(
                hintText: "Price",
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategoryId = value;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedRestaurantId,
                decoration: InputDecoration(
                  labelText: 'Restaurant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: restaurants.map((restaurant) {
                  return DropdownMenuItem<int>(
                    value: restaurant['id'],
                    child: Text(restaurant['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRestaurantId = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                maxLines: 3,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final data = {
                'name': nameController.text,
                'price': double.parse(priceController.text),
                'description': descriptionController.text,
                'category_id': selectedCategoryId,
                'restaurant_id': selectedRestaurantId,
              };

              if (menuItem != null) {
                data['id'] = menuItem['id'];
                await _updateMenuItem(data);
              } else {
                await _addMenuItem(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}menu_items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Menu item added successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${SVKey.baseUrl}menu_items/${data['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Menu item updated successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int menuItemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: const Text('Are you sure you want to delete this menu item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteMenuItem(menuItemId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(int menuItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SVKey.baseUrl}menu_items/$menuItemId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Menu item deleted successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
