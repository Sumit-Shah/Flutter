import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common/color_extension.dart';
import '../../common_widget/round_textfield.dart';

class MenuItemsManagementView extends StatefulWidget {
  final Map<String, dynamic> category;
  const MenuItemsManagementView({super.key, required this.category});

  @override
  State<MenuItemsManagementView> createState() =>
      _MenuItemsManagementViewState();
}

class _MenuItemsManagementViewState extends State<MenuItemsManagementView> {
  List<Map<String, dynamic>> menuItems = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      final session = json.decode(Globs.udValueString(Globs.userPayload));
      Map<String, String> authHeader = {'access_token': session['auth_token']};
      final response = await http.post(
        Uri.parse(SVKey.svAdminMenuList),
        headers: authHeader,
        body: {'category_id': widget.category["category_id"].toString()},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            menuItems =
                List<Map<String, dynamic>>.from(responseObj[KKey.payload]);
            isLoading = false;
          });
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to fetch menu items", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to fetch menu items. Please try again.", () {});
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.category['name']} - Menu Items"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditMenuItemDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Header
          Container(
            padding: const EdgeInsets.all(16),
            color: TColor.primary.withOpacity(0.1),
            child: Row(
              children: [
                _buildCategoryImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category['name'] ?? 'Category',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage menu items for this category',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Menu Items List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.restaurant_menu,
                                size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text("No menu items found"),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _showAddEditMenuItemDialog(),
                              child: const Text("Add Menu Item"),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchMenuItems,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: menuItems.length,
                          itemBuilder: (context, index) {
                            final menuItem = menuItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _buildMenuItemImage(menuItem),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menuItem['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Rs. ${menuItem['base_price'] ?? '0'}',
                                            style: TextStyle(
                                              color: TColor.primary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (menuItem['description'] != null &&
                                              menuItem['description']
                                                  .toString()
                                                  .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                menuItem['description'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _showAddEditMenuItemDialog(
                                                  menuItem: menuItem),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _showDeleteConfirmationDialog(
                                                  menuItem['menu_id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryImage() {
    final image = widget.category['image'];
    if (image != null && image.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '${SVKey.mainUrl}/uploads/category/$image',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.category, size: 40),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: TColor.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.category, size: 40),
    );
  }

  Widget _buildMenuItemImage(Map<String, dynamic> menuItem) {
    if (menuItem['image'] == null || menuItem['image'].toString().isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: TColor.textfield,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.fastfood, size: 30),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        '${SVKey.mainUrl}/uploads/menu/${menuItem['image']}',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            color: TColor.textfield,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: TColor.textfield,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.error_outline, size: 30),
          );
        },
      ),
    );
  }

  void _showAddEditMenuItemDialog({Map<String, dynamic>? menuItem}) {
    final nameController = TextEditingController(text: menuItem?['name']);
    final priceController =
        TextEditingController(text: menuItem?['price']?.toString());
    final descriptionController =
        TextEditingController(text: menuItem?['description']);
    _selectedImage = null;

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
              const SizedBox(height: 20),
              RoundTextfield(
                hintText: "Price",
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: TColor.textfield,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: "Description",
                    hintStyle: TextStyle(
                      color: TColor.placeholder,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (menuItem != null &&
                              menuItem['image'] != null &&
                              menuItem['image'].toString().isNotEmpty)
                          ? Image.network(
                              '${SVKey.mainUrl}/uploads/menu/${menuItem['image']}',
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.add_photo_alternate,
                                      size: 50),
                            )
                          : const Icon(Icons.add_photo_alternate, size: 50),
                ),
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
              if (nameController.text.isEmpty) {
                mdShowAlert(
                    Globs.appName, "Please enter menu item name", () {});
                return;
              }
              if (priceController.text.isEmpty) {
                mdShowAlert(Globs.appName, "Please enter price", () {});
                return;
              }

              if (menuItem != null) {
                await _updateMenuItem(
                    menuItem['menu_id'],
                    nameController.text,
                    double.parse(priceController.text),
                    descriptionController.text);
              } else {
                await _addMenuItem(
                    nameController.text,
                    double.parse(priceController.text),
                    descriptionController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenuItem(
      String name, double price, String description) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminMenuAdd),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['category_id'] = widget.category['category_id'].toString();
      request.fields['name'] = name;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseObj = json.decode(responseData);

      Globs.hideHUD();

      if (response.statusCode == 200 && responseObj[KKey.status] == "1") {
        if (mounted) {
          Navigator.pop(context);
          fetchMenuItems();
          mdShowAlert(Globs.appName, "Menu item added successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to add menu item", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateMenuItem(
      int menuId, String name, double price, String description) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminMenuUpdate),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['menu_id'] = menuId.toString();
      request.fields['name'] = name;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseObj = json.decode(responseData);

      Globs.hideHUD();

      if (response.statusCode == 200 && responseObj[KKey.status] == "1") {
        if (mounted) {
          Navigator.pop(context);
          fetchMenuItems();
          mdShowAlert(Globs.appName, "Menu item updated successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to update menu item", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int menuId) {
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
              Navigator.pop(context);
              await _deleteMenuItem(menuId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(int menuId) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final response = await http.post(
        Uri.parse(SVKey.svAdminMenuDelete),
        headers: {
          'access_token': session['auth_token'],
          'Content-Type': 'application/json',
        },
        body: json.encode({'menu_id': menuId}),
      );

      Globs.hideHUD();

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          if (mounted) {
            fetchMenuItems();
            mdShowAlert(Globs.appName, "Menu item deleted successfully", () {});
          }
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to delete menu item", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to delete menu item. Please try again.", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
