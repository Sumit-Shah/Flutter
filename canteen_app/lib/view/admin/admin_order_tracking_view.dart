import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminOrderTrackingView extends StatefulWidget {
  const AdminOrderTrackingView({super.key});

  @override
  State<AdminOrderTrackingView> createState() => _AdminOrderTrackingViewState();
}

class _AdminOrderTrackingViewState extends State<AdminOrderTrackingView> {
  List orders = [];
  int totalOrders = 0;
  int completedOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    Globs.showHUD(status: "Fetching Orders...");

    final adminPayload = Globs.udValue(Globs.userPayload);
    final token = adminPayload[KKey.authToken] ?? '';

    if (token.isEmpty) {
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as admin')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(SVKey.svAdminOrderList),
        headers: {
          'Content-Type': 'application/json',
          'access_token': token,
        },
        body: jsonEncode({}),
      );

      final responseData = jsonDecode(response.body);
      Globs.hideHUD();

      if (response.statusCode == 200 && responseData[KKey.status] == '1') {
        // Sort orders by created_date in descending order (latest first)
        List sortedOrders = responseData[KKey.payload];
        sortedOrders.sort((a, b) {
          DateTime dateA = DateTime.parse(a['created_date']);
          DateTime dateB = DateTime.parse(b['created_date']);
          return dateB.compareTo(dateA); // Descending order
        });

        setState(() {
          orders = sortedOrders;
          totalOrders = responseData['total_orders'] ?? 0;
          completedOrders = responseData['completed_orders'] ?? 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData[KKey.message] ?? 'Failed to fetch orders')),
        );
      }
    } catch (error) {
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error fetching orders. Please try again.')),
      );
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    Globs.showHUD(status: "Updating Status...");

    final adminPayload = Globs.udValue(Globs.userPayload);
    final token = adminPayload[KKey.authToken] ?? '';

    if (token.isEmpty) {
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as admin')),
      );
      return;
    }

    try {
      print(
          'Updating Order ID: $orderId to Status: $newStatus with Token: $token');
      final response = await http.post(
        Uri.parse(SVKey.svAdminUpdateOrderStatus),
        headers: {
          'Content-Type': 'application/json',
          'access_token': token,
        },
        body: jsonEncode({
          'order_id': orderId.toString(),
          'status': newStatus,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('Update Status Response: $responseData');
      Globs.hideHUD();

      if (response.statusCode == 200 && responseData[KKey.status] == '1') {
        await _fetchOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData[KKey.message] ?? 'Status updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData[KKey.message] ?? 'Failed to update status')),
        );
      }
    } catch (error) {
      print('Update Status Error: $error');
      Globs.hideHUD();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error updating status. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int incompleteOrders =
        totalOrders - completedOrders; // Calculate incomplete orders

    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: Text(
          "Order Tracking",
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
            Text(
              "Total Orders: $totalOrders",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Completed Orders: $completedOrders",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Incomplete Orders: $incompleteOrders",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        "No orders found.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        var order = orders[index];
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
                                "User ID: ${order['user_id']}",
                                style: TextStyle(
                                  color: TColor.secondaryText,
                                  fontSize: 13,
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: order['status'] == 'delivered'
                                        ? null
                                        : () => _updateOrderStatus(
                                            order['order_id'], 'delivered'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: TColor.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Mark Delivered",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: order['status'] == 'pending'
                                        ? null
                                        : () => _updateOrderStatus(
                                            order['order_id'], 'pending'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: TColor.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Mark Not Delivered",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
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
                                "Placed At: ${DateTime.parse(order['created_date']).toLocal().toString()}",
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
