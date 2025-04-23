import 'dart:async';
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
  bool hasError = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final int _maxImageSize = 5 * 1024 * 1024; // 5MB max image size

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
  }

  Future<void> fetchMenuItems() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final response = await http
          .post(
            Uri.parse(SVKey.svAdminMenuItemsList),
            headers: {
              'access_token': session['auth_token'] ?? '',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'category_id': widget.category['category_id'].toString(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('Response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['payload'] != null) {
          setState(() {
            menuItems = List<Map<String, dynamic>>.from(data['payload']);
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch menu items');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      image.path.split('.').last.toLowerCase();

      setState(() {
        _selectedImage = file;
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
                : hasError
                    ? _buildErrorView()
                    : menuItems.isEmpty
                        ? _buildEmptyView()
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
                                              if (menuItem['description'] !=
                                                      null &&
                                                  menuItem['description']
                                                      .toString()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
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
                                                      menuItem[
                                                              'menu_item_id'] ??
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

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 50, color: Colors.red),
        const SizedBox(height: 10),
        const Text("Failed to load menu items"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: fetchMenuItems,
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
        const SizedBox(height: 10),
        const Text("No menu items found"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _showAddEditMenuItemDialog(),
          child: const Text("Add Menu Item"),
        ),
      ],
    );
  }

  Widget _buildCategoryImage() {
    final imageUrl = _getImageUrl(widget.category['image'], isCategory: true);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: TColor.textfield,
      ),
      child: imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.category, size: 30),
              ),
            )
          : const Icon(Icons.category, size: 30),
    );
  }

  String _getImageUrl(String? imagePath, {bool isCategory = false}) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl =
        SVKey.imageUrl.endsWith('/') ? SVKey.imageUrl : '${SVKey.imageUrl}/';
    final fullUrl = '$baseUrl$imagePath';
    print('Image URL: $fullUrl');
    return fullUrl;
  }

  Widget _buildMenuItemImage(Map<String, dynamic> menuItem) {
    final imageUrl = _getImageUrl(menuItem['image']);
    if (imageUrl.isEmpty) {
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
        imageUrl,
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
        TextEditingController(text: menuItem?['base_price']?.toString());
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
                hintText: "Base Price",
                controller: priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              RoundTextfield(
                hintText: "Description",
                controller: descriptionController,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : (menuItem != null &&
                              menuItem['image'] != null &&
                              menuItem['image'].toString().isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _getImageUrl(menuItem['image']),
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 50),
                              ),
                            )
                          : const Icon(Icons.add_photo_alternate, size: 50),
                ),
              ),
              if (_selectedImage != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  child: const Text('Remove Image'),
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
              if (priceController.text.isEmpty ||
                  double.tryParse(priceController.text) == null) {
                mdShowAlert(Globs.appName, "Please enter a valid price", () {});
                return;
              }

              if (menuItem != null) {
                await _updateMenuItem(
                  menuItem['menu_item_id']?.toString() ??
                      menuItem['menu_id']?.toString() ??
                      '',
                  widget.category['category_id'].toString(),
                  nameController.text,
                  double.parse(priceController.text),
                  descriptionController.text,
                );
              } else {
                await _addMenuItem(
                  nameController.text,
                  double.parse(priceController.text),
                  descriptionController.text,
                );
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
        Uri.parse(SVKey.svAdminMenuItemsAdd),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['category_id'] = widget.category['category_id'].toString();
      request.fields['name'] = name;
      request.fields['base_price'] = price.toString();
      request.fields['description'] = description;

      if (_selectedImage != null) {
        final fileSize = await _selectedImage!.length();
        if (fileSize > _maxImageSize) {
          Globs.hideHUD();
          mdShowAlert(Globs.appName, "Image size exceeds 5MB limit.", () {});
          return;
        }
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
      mdShowAlert(Globs.appName, "Error: ${err.toString()}", () {});
    }
  }

  Future<void> _updateMenuItem(String menuItemId, String categoryId,
      String name, double price, String description) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminMenuItemsUpdate),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['menu_item_id'] = menuItemId;
      request.fields['category_id'] = categoryId;
      request.fields['name'] = name;
      request.fields['base_price'] = price.toString();
      request.fields['description'] = description;

      if (_selectedImage != null) {
        final fileSize = await _selectedImage!.length();
        if (fileSize > _maxImageSize) {
          Globs.hideHUD();
          mdShowAlert(Globs.appName, "Image size exceeds 5MB limit.", () {});
          return;
        }
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
      mdShowAlert(Globs.appName, "Error: ${err.toString()}", () {});
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
      // Show loading indicator
      Globs.showHUD();

      // Get session data
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final accessToken = session['auth_token'] as String?;

      // Validate required data
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Invalid authentication token');
      }

      if (widget.category['category_id'] == null) {
        throw Exception('Category ID is missing');
      }

      // Prepare request
      final requestBody = {
        'menu_item_id': menuItemId.toString(),
        'category_id': widget.category['category_id'].toString(),
      };

      debugPrint('Delete Request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(SVKey.svAdminMenuItemsDelete),
            headers: {
              'access_token': accessToken,
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Delete Response: ${response.statusCode}, ${response.body}');

      final responseObj = json.decode(response.body);
      Globs.hideHUD();

      if (!mounted) return;

      if (response.statusCode == 200) {
        if (responseObj[KKey.status] == "1") {
          // Success - refresh the list
          await fetchMenuItems();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Menu item deleted successfully')));
        } else {
          // API returned status 0
          final errorMsg =
              responseObj[KKey.message] ?? "Failed to delete menu item";
          _showErrorDialog(errorMsg);
        }
      } else {
        // HTTP error
        _showErrorDialog("Server error: ${response.statusCode}");
      }
    } on TimeoutException {
      Globs.hideHUD();
      _showErrorDialog("Request timed out. Please try again.");
    } on SocketException {
      Globs.hideHUD();
      _showErrorDialog("No internet connection.");
    } catch (e) {
      Globs.hideHUD();
      _showErrorDialog("Error: ${e.toString()}");
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
