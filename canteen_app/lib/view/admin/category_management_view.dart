import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../common_widget/round_textfield.dart';
import '../../view/admin/menu_items_management_view.dart';

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
      });

      final session = json.decode(Globs.udValueString(Globs.userPayload));
      Map<String, String> authHeader = {'access_token': session['auth_token']};
      final response = await http.post(
        Uri.parse(SVKey.svAdminCategoryList),
        headers: authHeader,
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            categories =
                List<Map<String, dynamic>>.from(responseObj[KKey.payload]);
            isLoading = false;
          });
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to fetch categories", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to fetch categories. Please try again.", () {});
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
        title: const Text("Category Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditCategoryDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text("No categories found"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _showAddEditCategoryDialog();
                        },
                        child: const Text("Add Category"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchCategories,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      print('${SVKey.imageUrl}  ${category['image']}');
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: category['image'] != null &&
                                        category['image'].toString().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '${SVKey.imageUrl}${category['image']}',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                                Icons.broken_image,
                                                size: 30);
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.category, size: 30),
                              ),
                              if (category['image'] != null &&
                                  category['image'].toString().isNotEmpty)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(category['name'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restaurant_menu),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MenuItemsManagementView(
                                        category: {
                                          'category_id':
                                              category['category_id'],
                                          'name': category['name'],
                                          'image': category['image']
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showAddEditCategoryDialog(
                                      category: category);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(
                                      category['category_id']);
                                },
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

  void _showAddEditCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category?['name']);
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
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
                      : (category != null &&
                              category['image'] != null &&
                              category['image'].toString().isNotEmpty)
                          ? Image.network(
                              '${SVKey.mainUrl}/uploads/category/${category['image']}',
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.add_photo_alternate,
                                    size: 50);
                              },
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
                mdShowAlert(Globs.appName, "Please enter category name", () {});
                return;
              }

              if (category != null) {
                await _updateCategory(
                    category['category_id'], nameController.text);
              } else {
                await _addCategory(nameController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(String name) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminCategoryAdd),
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
          fetchCategories();
          mdShowAlert(Globs.appName, "Category added successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to add category", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateCategory(int categoryId, String name) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(SVKey.svAdminCategoryUpdate),
      );

      request.headers['access_token'] = session['auth_token'];
      request.fields['category_id'] = categoryId.toString();
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
          fetchCategories();
          mdShowAlert(Globs.appName, "Category updated successfully", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            responseObj[KKey.message] ?? "Failed to update category", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteCategory(categoryId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    try {
      Globs.showHUD();
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final response = await http.post(
        Uri.parse(SVKey.svAdminCategoryDelete),
        headers: {
          'access_token': session['auth_token'],
          'Content-Type': 'application/json',
        },
        body: json.encode({'category_id': categoryId}),
      );

      Globs.hideHUD();

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          if (mounted) {
            Navigator.pop(context);
            fetchCategories();
            mdShowAlert(Globs.appName, "Category deleted successfully", () {});
          }
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] ?? "Failed to delete category", () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to delete category. Please try again.", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
