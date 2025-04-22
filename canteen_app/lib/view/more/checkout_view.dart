import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/more/cart.dart';
import 'package:canteen_app/view/more/my_order_view.dart';
import 'package:flutter/material.dart';

class CheckoutView extends StatelessWidget {
  final List orderedItems;
  final double total;
  final String deliveryFloor;
  final String deliveryNotes;

  const CheckoutView({
    super.key,
    required this.orderedItems,
    required this.total,
    required this.deliveryFloor,
    required this.deliveryNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: Text(
          "Checkout",
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
              "Order Summary",
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(color: TColor.textfield),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderedItems.length,
                separatorBuilder: (context, index) => Divider(
                  indent: 25,
                  endIndent: 25,
                  color: TColor.secondaryText.withOpacity(0.5),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  var item = orderedItems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 25,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Circular item image/icon
                        ClipOval(
                          child: item["image"]?.isNotEmpty == true
                              ? Image.network(
                                  item["image"],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholderIcon(),
                                )
                              : _buildPlaceholderIcon(),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "${item["name"]} x${item["qty"]}",
                            style: TextStyle(
                              color: TColor.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "Rs. ${(item["price"] * item["qty"]).toStringAsFixed(2)}",
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
            ),
            const SizedBox(height: 15),
            Text(
              "Delivery Details",
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deliver to: $deliveryFloor Floor",
              style: TextStyle(
                color: TColor.secondaryText,
                fontSize: 13,
              ),
            ),
            if (deliveryNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Notes: $deliveryNotes",
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 15),
            Divider(
              color: TColor.secondaryText.withOpacity(0.5),
              height: 1,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Rs. ${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: TColor.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Spacer(),
            RoundButton(
              title: "Make Payment",
              onPressed: () {
                Cart.clear(); // Clear cart after payment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment processing initiated!"),
                  ),
                );
                Navigator.pop(context); // Return to previous screen
              },
            ),
            const SizedBox(height: 20),
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
