import 'dart:convert';
import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common_widget/round_textfield.dart';
import 'package:canteen_app/view/more/cart.dart';
import 'package:canteen_app/view/more/my_order_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Menu",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyOrderView(),
                            ),
                          );
                        },
                        icon: Image.asset(
                          "assets/img/shopping_cart.png",
                          width: 25,
                          height: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  RoundTextfield(
                    hintText: "Search Categories",
                    controller: _searchController,
                    left: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        "assets/img/search.png",
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? _buildErrorView(
                        "Failed to load categories", _fetchCategories)
                    : _filteredCategories.isEmpty
                        ? _buildEmptyView(
                            _searchController.text.isEmpty
                                ? "No categories"
                                : "No results",
                            _fetchCategories)
                        : _buildHorizontalCategoryGrid(),
          ),
          if (_selectedCategory != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(
                  "Items in ${_selectedCategory!['name']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_isItemsLoading)
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasItemsError)
              SliverToBoxAdapter(
                child: _buildErrorView("Failed to load menu items",
                    () => _fetchItemsForCategory(_selectedCategory!)),
              )
            else if (_menuItems.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyItemsView())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _menuItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: _buildMenuItemImage(item),
                        title: Text(item['name'] ?? 'Item'),
                        subtitle: Text('Rs. ${item['base_price'] ?? '0'}'),
                        trailing: IconButton(
                          icon: Icon(Icons.add_shopping_cart,
                              color: TColor.primary),
                          onPressed: () {
                            Cart.addItem(
                              item['name'],
                              double.parse(item['base_price'].toString()),
                              image: _getImageUrl(item['image']),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${item['name']} added to cart')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: _menuItems.length,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalCategoryGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth < 400 ? 60.0 : 70.0;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          final isSelected = _selectedCategory != null &&
              category['category_id'] == _selectedCategory!['category_id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _fetchItemsForCategory(category);
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? TColor.primary
                            : TColor.primary.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: category["image"]?.isNotEmpty == true
                          ? Image.network(
                              _getImageUrl(category["image"]),
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                "assets/img/menu_placeholder.png",
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              "assets/img/menu_placeholder.png",
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category["name"] ?? "Category",
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemImage(Map<String, dynamic> item) {
    final imageUrl = _getImageUrl(item['image']);
    if (imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: TColor.textfield,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.fastfood, size: 30),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: TColor.textfield,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.error, size: 30),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(message),
            TextButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String message, VoidCallback onRefresh) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(message),
            TextButton(onPressed: onRefresh, child: const Text("Refresh")),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsView() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("No menu items found"),
          ],
        ),
      ),
    );
  }
}
