import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  List<Map<String, dynamic>> orders = [];
  int selectedTab = 0; // 0: Day, 1: Week, 2: Month

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    Globs.showHUD(status: "Fetching Order History...");

    final userPayload = Globs.udValue(Globs.userPayload);
    final token = userPayload[KKey.authToken] ?? '';

    if (token.isEmpty) {
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view order history')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(SVKey.svUserOrderHistory),
        headers: {
          'Content-Type': 'application/json',
          'access_token': token,
        },
        body: jsonEncode({}),
      );

      final responseData = jsonDecode(response.body);
      Globs.hideHUD();

      if (response.statusCode == 200 && responseData[KKey.status] == '1') {
        List<Map<String, dynamic>> sortedOrders = (responseData[KKey.payload]
                    as List<dynamic>? ??
                [])
            .cast<Map<String, dynamic>>()
          ..sort((a, b) {
            final dateA =
                DateTime.tryParse(a['created_date'] ?? '') ?? DateTime(1970);
            final dateB =
                DateTime.tryParse(b['created_date'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA); // Descending order
          });

        setState(() {
          orders = sortedOrders;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData[KKey.message] ??
                  'Failed to fetch order history')),
        );
      }
    } catch (error) {
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching order history. Please try again.')),
      );
    }
  }

  List<Map<String, dynamic>> _filterOrdersByTab(int tabIndex) {
    final now = DateTime.now();
    DateTime startDate;

    switch (tabIndex) {
      case 0: // Day
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 1: // Week
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 2: // Month
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        return orders;
    }

    return orders.where((order) {
      final orderDate =
          DateTime.tryParse(order['created_date'] ?? '') ?? DateTime(1970);
      return orderDate.isAfter(startDate) ||
          orderDate.isAtSameMomentAs(startDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filterOrdersByTab(selectedTab);

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: Text(
          "Order History",
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Image.asset(
            "assets/img/btn_back.png",
            width: 20,
            height: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton("Day", 0),
                _buildTabButton("Week", 1),
                _buildTabButton("Month", 2),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Text(
                        "No orders found for this period.",
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredOrders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        var order = filteredOrders[index];
                        return Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: TColor.textfield,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Order #${order['order_id']}",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Total: Rs. ${order['total'].toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Deliver to: ${order['delivery_floor']} Floor",
                                style: TextStyle(
                                  color: TColor.secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                              if (order['delivery_notes'] != null &&
                                  order['delivery_notes'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    "Notes: ${order['delivery_notes']}",
                                    style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                "Status: ${order['status'] == 'delivered' ? 'Completed and Delivered' : 'Not Delivered'}",
                                style: TextStyle(
                                  color: order['status'] == 'delivered'
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Items:",
                                style: TextStyle(
                                  color: TColor.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: order['items'].length,
                                separatorBuilder: (context, index) => Divider(
                                  indent: 10,
                                  endIndent: 10,
                                  color: TColor.secondaryText.withOpacity(0.5),
                                  height: 1,
                                ),
                                itemBuilder: (context, itemIndex) {
                                  var item = order['items'][itemIndex];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ClipOval(
                                          child: item["image"] != null &&
                                                  item["image"].isNotEmpty
                                              ? Image.network(
                                                  item["image"],
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      _buildPlaceholderIcon(),
                                                )
                                              : _buildPlaceholderIcon(),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            "${item['name']} x${item['qty']}",
                                            style: TextStyle(
                                              color: TColor.primaryText,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "Rs. ${(item['price'] * item['qty']).toStringAsFixed(2)}",
                                          style: TextStyle(
                                            color: TColor.primaryText,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Placed At: ${DateFormat('MMM d, yyyy, h:mm a').format(DateTime.parse(order['created_date']).toLocal())}",
                                style: TextStyle(
                                  color: TColor.secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int tabIndex) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = tabIndex;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selectedTab == tabIndex ? TColor.primary : TColor.textfield,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                selectedTab == tabIndex ? TColor.white : TColor.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: TColor.textfield,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.fastfood,
        size: 20,
        color: TColor.secondaryText,
      ),
    );
  }
}
