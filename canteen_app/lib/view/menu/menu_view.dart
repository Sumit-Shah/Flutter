import 'dart:convert';
import 'package:canteen_app/view/more/my_order_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common_widget/round_textfield.dart';
import 'menu_items_view.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> filteredCategories = [];
  bool isLoading = true;
  bool hasError = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
    searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true;
      hasError = false;
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

      print('Response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['payload'] != null) {
          setState(() {
            categories = List<Map<String, dynamic>>.from(data['payload']);
            filteredCategories = categories;
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch categories');
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

  void _filterCategories() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredCategories = categories.where((category) {
        final name = category['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final baseUrl =
        SVKey.imageUrl.endsWith('/') ? SVKey.imageUrl : '${SVKey.imageUrl}/';
    final fullUrl = '$baseUrl$imagePath';
    print('Image URL: $fullUrl');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Menu",
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyOrderView()),
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
                hintText: "Search Food",
                controller: searchController,
                left: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset("assets/img/search.png",
                      width: 20, height: 20),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                      ? _buildErrorView()
                      : filteredCategories.isEmpty
                          ? _buildEmptyView()
                          : _buildCategoryList(media),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        const Icon(Icons.error, size: 50, color: Colors.red),
        const SizedBox(height: 10),
        const Text("Failed to load categories"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: fetchCategories,
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Column(
      children: [
        const Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
        const SizedBox(height: 10),
        const Text("No categories found"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: fetchCategories,
          child: const Text("Refresh"),
        ),
      ],
    );
  }

  Widget _buildCategoryList(Size media) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuItemsView(mObj: category),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: category["image"]?.isNotEmpty == true
                      ? Image.network(
                          _getImageUrl(category["image"]),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Image error: ${_getImageUrl(category["image"])} - $error');
                            return Image.asset(
                              "assets/img/menu_placeholder.png",
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          "assets/img/menu_placeholder.png",
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category["name"] ?? "Category",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${category["items_count"]?.toString() ?? "0"} items",
                        style: TextStyle(
                            color: TColor.secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  "assets/img/btn_next.png",
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
