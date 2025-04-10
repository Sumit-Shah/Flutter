import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class RestaurantManagementView extends StatefulWidget {
  const RestaurantManagementView({super.key});

  @override
  State<RestaurantManagementView> createState() =>
      _RestaurantManagementViewState();
}

class _RestaurantManagementViewState extends State<RestaurantManagementView> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    try {
      final response = await http.get(
        Uri.parse('${SVKey.baseUrl}restaurants'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            restaurants =
                List<Map<String, dynamic>>.from(responseObj[KKey.payload]);
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
        title: const Text("Restaurant Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditRestaurantDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                return Card(
                  child: ListTile(
                    title: Text(restaurant['name']),
                    subtitle: Text(restaurant['address']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAddEditRestaurantDialog(
                                restaurant: restaurant);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(restaurant['id']);
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

  void _showAddEditRestaurantDialog({Map<String, dynamic>? restaurant}) {
    final nameController = TextEditingController(text: restaurant?['name']);
    final addressController =
        TextEditingController(text: restaurant?['address']);
    final phoneController = TextEditingController(text: restaurant?['phone']);
    final descriptionController =
        TextEditingController(text: restaurant?['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restaurant == null ? 'Add Restaurant' : 'Edit Restaurant'),
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
                hintText: "Address",
                controller: addressController,
              ),
              const SizedBox(height: 10),
              RoundTextfield(
                hintText: "Phone",
                controller: phoneController,
                keyboardType: TextInputType.phone,
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
                'address': addressController.text,
                'phone': phoneController.text,
                'description': descriptionController.text,
              };

              if (restaurant != null) {
                data['id'] = restaurant['id'];
                await _updateRestaurant(data);
              } else {
                await _addRestaurant(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRestaurant(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}restaurants'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchRestaurants();
          mdShowAlert(Globs.appName, "Restaurant added successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateRestaurant(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${SVKey.baseUrl}restaurants/${data['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchRestaurants();
          mdShowAlert(Globs.appName, "Restaurant updated successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int restaurantId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: const Text('Are you sure you want to delete this restaurant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteRestaurant(restaurantId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(int restaurantId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SVKey.baseUrl}restaurants/$restaurantId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchRestaurants();
          mdShowAlert(Globs.appName, "Restaurant deleted successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
