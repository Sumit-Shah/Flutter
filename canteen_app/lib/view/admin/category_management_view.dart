import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${SVKey.baseUrl}categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          setState(() {
            categories =
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
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    title: Text(category['name']),
                    subtitle: Text(category['description'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAddEditCategoryDialog(category: category);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(category['id']);
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

  void _showAddEditCategoryDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category?['name']);
    final descriptionController =
        TextEditingController(text: category?['description']);

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
                'description': descriptionController.text,
              };

              if (category != null) {
                data['id'] = category['id'];
                await _updateCategory(data);
              } else {
                await _addCategory(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchCategories();
          mdShowAlert(Globs.appName, "Category added successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateCategory(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${SVKey.baseUrl}categories/${data['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchCategories();
          mdShowAlert(Globs.appName, "Category updated successfully", () {});
        }
      }
    } catch (err) {
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
      final response = await http.delete(
        Uri.parse('${SVKey.baseUrl}categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchCategories();
          mdShowAlert(Globs.appName, "Category deleted successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
