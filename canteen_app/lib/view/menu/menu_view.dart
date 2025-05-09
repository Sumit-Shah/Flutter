import 'dart:convert';
import 'package:canteen_app/view/more/cart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:canteen_app/view/more/my_order_view.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common_widget/round_textfield.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  Map<String, dynamic>? _selectedCategory;
  List<Map<String, dynamic>> _menuItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isItemsLoading = false;
  bool _hasItemsError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final response = await http
          .post(
            Uri.parse(SVKey.svUserCategoryList),
            headers: {
              'access_token': session['auth_token'] ?? '',
              'Content-Type': 'application/json',
            },
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['payload'] != null) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(data['payload']);
            _filteredCategories = _categories;
            _isLoading = false;
            if (_categories.isNotEmpty) {
              _selectedCategory = _categories[0];
              _fetchItemsForCategory(_selectedCategory!);
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch categories');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _fetchItemsForCategory(Map<String, dynamic> category) async {
    setState(() {
      _isItemsLoading = true;
      _hasItemsError = false;
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
              'category_id': category['category_id'].toString(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['payload'] != null) {
          setState(() {
            _menuItems = List<Map<String, dynamic>>.from(data['payload']);
            _isItemsLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch menu items');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isItemsLoading = false;
        _hasItemsError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching items: $e')),
        );
      }
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories.where((category) {
        final name = category['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();

      if (_selectedCategory != null &&
          !_filteredCategories.any(
              (c) => c['category_id'] == _selectedCategory!['category_id'])) {
        if (_filteredCategories.isNotEmpty) {
          _selectedCategory = _filteredCategories[0];
          _fetchItemsForCategory(_selectedCategory!);
        } else {
          _selectedCategory = null;
          _menuItems = [];
          _isItemsLoading = false;
          _hasItemsError = false;
        }
      }
    });
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl =
        SVKey.imageUrl.endsWith('/') ? SVKey.imageUrl : '${SVKey.imageUrl}/';
    return '$baseUrl$imagePath';
  }

  Widget _buildErrorView(String message, VoidCallback retry) {
    return Column(
      children: [
        const Icon(Icons.error, size: 50, color: Colors.red),
        const SizedBox(height: 10),
        Text(message),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: retry,
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget _buildEmptyView(String message, VoidCallback refresh) {
    return Column(
      children: [
        const Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
        const SizedBox(height: 10),
        Text(message),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: refresh,
          child: const Text("Refresh"),
        ),
      ],
    );
  }

  Widget _buildHorizontalCategoryGrid() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          final isSelected =
              _selectedCategory?['category_id'] == category['category_id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _fetchItemsForCategory(category);
            },
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? TColor.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: category["image"]?.isNotEmpty == true
                        ? Image.network(
                            _getImageUrl(category["image"]),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            "assets/img/menu_placeholder.png",
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category["name"] ?? "",
                    style: TextStyle(
                      color: isSelected ? Colors.white : TColor.primaryText,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
      ),
    );
  }

  Widget _buildMenuItems() {
    if (_isItemsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_hasItemsError) {
      return _buildErrorView(
        "Failed to load menu items",
        () => _fetchItemsForCategory(_selectedCategory!),
      );
    } else if (_menuItems.isEmpty) {
      return const Center(child: Text("No items in this category."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: _buildMenuItemImage(item),
            title: Text(item['name'] ?? 'Item'),
            subtitle: Text('Rs. ${item['base_price'] ?? '0'}'),
            trailing: IconButton(
              icon: Icon(Icons.add_shopping_cart, color: TColor.primary),
              onPressed: () {
                Cart.addItem(
                  item['name'],
                  double.parse(item['base_price'].toString()),
                  image: _getImageUrl(item['image']),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['name']} added to cart')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItemImage(Map<String, dynamic> item) {
    final imageUrl = _getImageUrl(item['image']);
    return imageUrl.isNotEmpty
        ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
        : Image.asset("assets/img/menu_placeholder.png",
            width: 60, height: 60, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView("Failed to load categories", _fetchCategories)
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Menu",
                              style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyOrderView()),
                              );
                            },
                            icon: Image.asset(
                              "assets/img/shopping_cart.png",
                              width: 25,
                              height: 25,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      RoundTextfield(
                        hintText: "Search Food",
                        controller: _searchController,
                        left: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset("assets/img/search.png",
                              width: 20, height: 20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_filteredCategories.isEmpty)
                        _buildEmptyView(
                          _searchController.text.isEmpty
                              ? "No categories"
                              : "No results found",
                          _fetchCategories,
                        )
                      else
                        _buildHorizontalCategoryGrid(),
                      const SizedBox(height: 20),
                      if (_selectedCategory != null)
                        Text(
                          "Items in ${_selectedCategory!['name']}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 10),
                      _buildMenuItems(),
                    ],
                  ),
                ),
    );
  }
}
