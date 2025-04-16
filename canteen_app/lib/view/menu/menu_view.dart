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
  List menuArr = [];
  bool isLoading = true;
  bool hasError = false;
  TextEditingController txtSearch = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      // Get session data
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      if (session['auth_token'] == null) {
        throw Exception('Authentication token not found');
      }

      final headers = {
        'access_token': session['auth_token'].toString(),
        'Content-Type': 'application/json',
      };

      debugPrint('Fetching categories from: ${SVKey.svUserCategoryList}');
      debugPrint('Headers: $headers');

      final response = await http.post(
        Uri.parse(SVKey.svUserCategoryList),
        headers: headers,
        body: json.encode({}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);

        if (responseObj['status'] == "1") {
          if (responseObj['payload'] != null) {
            setState(() {
              menuArr = List<Map<String, dynamic>>.from(responseObj['payload']);
              isLoading = false;
            });
          } else {
            throw Exception('Payload is null in response');
          }
        } else {
          final errorMessage =
              responseObj['message'] ?? "Failed to fetch categories";
          throw Exception(errorMessage);
        }
      } else {
        throw Exception(
            'Server responded with status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });

      // Show error to user (optional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 180),
            width: media.width * 0.27,
            height: media.height * 0.6,
            decoration: BoxDecoration(
              color: TColor.primary,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(35),
                  bottomRight: Radius.circular(35)),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 46),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Menu",
                          style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MyOrderView()));
                          },
                          icon: Image.asset(
                            "assets/img/shopping_cart.png",
                            width: 25,
                            height: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RoundTextfield(
                      hintText: "Search Food",
                      controller: txtSearch,
                      left: Container(
                        alignment: Alignment.center,
                        width: 30,
                        child: Image.asset(
                          "assets/img/search.png",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (hasError)
                    _buildErrorWidget()
                  else if (menuArr.isEmpty)
                    _buildEmptyWidget()
                  else
                    _buildCategoryList(media),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        const Icon(Icons.error_outline, size: 50, color: Colors.red),
        const SizedBox(height: 10),
        const Text("Failed to load categories"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: fetchCategories,
          child: const Text("Retry"),
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Column(
      children: [
        const Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
        const SizedBox(height: 10),
        const Text("No categories available"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: fetchCategories,
          child: const Text("Refresh"),
        ),
      ],
    );
  }

  Widget _buildCategoryList(Size media) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: menuArr.length,
      itemBuilder: ((context, index) {
        var mObj = menuArr[index] as Map? ?? {};
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuItemsView(mObj: mObj),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8, right: 20),
                width: media.width - 100,
                height: 90,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 7,
                          offset: Offset(0, 4))
                    ]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: mObj["image"] != null
                        ? Image.network(
                            '${SVKey.mainUrl}/uploads/${mObj["image"]}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/img/menu_placeholder.png",
                                width: 80,
                                height: 80,
                              );
                            },
                          )
                        : Image.asset(
                            "assets/img/menu_placeholder.png",
                            width: 80,
                            height: 80,
                          ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mObj["name"]?.toString() ?? "Category",
                          style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${mObj["items_count"]?.toString() ?? "0"} items",
                          style: TextStyle(
                              color: TColor.secondaryText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ]),
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/img/btn_next.png",
                      width: 15,
                      height: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
