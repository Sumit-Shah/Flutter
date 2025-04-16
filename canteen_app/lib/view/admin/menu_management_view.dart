import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import '../../common_widget/round_textfield.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  List<Map<String, dynamic>> menus = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    fetchMenus();
  }

  Future<void> fetchMenus() async {
    try {
      setState(() {
        isLoading = true;
      });

      final session = json.decode(Globs.udValueString(Globs.userPayload));
      Map<String, String> authHeader = {'access_token': session['auth_token']};
      final response = await http.post(
        Uri.parse(SVKey.svAdminMenuList),
        headers: authHeader,
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            menus = List<Map<String, dynamic>>.from(responseObj[KKey.payload]);
            isLoading = false;
          });
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to fetch menu", () {});
        }
      } else {
        mdShowAlert(
            Globs.appName, "Failed to fetch menus. Please try again.", () {});
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
        title: const Text("Menu Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditMenuDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : menus.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu,
                          size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text("No Menu found"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _showAddEditMenuDialog(),
                        child: const Text("Add Menu"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchMenus,
                  child: ListView.builder(
                    itemCount: menus.length,
                    itemBuilder: (context, index) {
                      final menu = menus[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: _buildMenuImage(menu),
                          title: Text(menu['name'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showAddEditMenuDialog(menu: menu),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmationDialog(
                                    menu['menu_id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildMenuImage(Map<String, dynamic> menu) {
    final image = menu['image'];
    if (image != null && image.toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          '${SVKey.mainUrl}/uploads/menu/$image',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 30),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }
    return const Icon(Icons.restaurant_menu, size: 30);
  }

  void _showAddEditMenuDialog({Map<String, dynamic>? menu}) {
    final nameController = TextEditingController(text: menu?['name']);
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(menu == null ? 'Add Menu' : 'Edit Menu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundTextfield(
                hintText: "Name",
                controller: nameController,
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
                      : (menu != null &&
                              menu['image'] != null &&
                              menu['image'].toString().isNotEmpty)
                          ? Image.network(
                              '${SVKey.mainUrl}/uploads/menu/${menu['image']}',
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
                mdShowAlert(Globs.appName, "Please enter menu name", () {});
                return;
              }

              if (menu != null) {
                await _updateMenu(menu['menu_id'], nameController.text);
              } else {
                await _addMenu(nameController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMenu(String name) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminMenuAdd),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['name'] = name;

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
          fetchMenus();
          mdShowAlert(Globs.appName, "Menu added successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to add menu", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateMenu(int menuId, String name) async {
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
          fetchMenus();
          mdShowAlert(Globs.appName, "Menu updated successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to update menu", () {});
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
        title: const Text('Delete Menu'),
        content: const Text('Are you sure you want to delete this Menu Item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMenu(menuId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenu(int menuId) async {
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
            fetchMenus();
            mdShowAlert(Globs.appName, "Menu deleted successfully", () {});
          }
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to delete menu", () {});
        }
      } else {
        mdShowAlert(
            Globs.appName, "Failed to delete menu. Please try again.", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
