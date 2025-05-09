import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/more/cart.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EsewaConfigData {
  static const String clientId =
      'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R';
  static const String secretKey = 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==';
  static const Environment environment = Environment.test;
}

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

  Future<void> _initiatePayment(BuildContext context) async {
    try {
      final productId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: EsewaConfigData.environment,
          clientId: EsewaConfigData.clientId,
          secretId: EsewaConfigData.secretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: productId,
          productName: 'Canteen Order',
          productPrice: total.toStringAsFixed(2),
          callbackUrl:
              'https://your-server.com/payment/callback', // Update this to your actual callback
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) async {
          debugPrint(':::SUCCESS::: => $data');
          await _verifyTransaction(context, data);
        },
        onPaymentFailure: (data) {
          _showSnackBar(context, 'Payment Failed: ${data.message}',
              retry: () => _initiatePayment(context));
        },
        onPaymentCancellation: (data) {
          _showSnackBar(context, 'Payment Cancelled: ${data.message}',
              retry: () => _initiatePayment(context));
        },
      );
    } catch (e) {
      debugPrint('EXCEPTION: $e');
      _showSnackBar(context, 'Error: $e',
          retry: () => _initiatePayment(context));
    }
  }

  Future<void> _verifyTransaction(
      BuildContext context, EsewaPaymentSuccessResult result) async {
    Globs.showHUD(status: "Verifying Payment...");
    try {
      final url =
          'https://rc.esewa.com.np/api/epay/transaction/status/?product_code=EPAYTEST&transaction_uuid=${result.refId}&total_amount=${result.totalAmount}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _placeOrder(context, result.refId);
        return;
      } else {
        _showSnackBar(context, 'Verification API Call Failed');
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      _showSnackBar(context, 'Error verifying transaction: $e');
    } finally {
      Globs.hideHUD();
    }
  }

  Future<void> _placeOrder(BuildContext context, [String? refId]) async {
    Globs.showHUD(status: "Placing Order...");
    final userPayload = Globs.udValue(Globs.userPayload);
    final token = userPayload[KKey.authToken] ?? '';

    if (token.isEmpty) {
      Globs.hideHUD();
      _showSnackBar(context, 'Please log in to place an order');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(SVKey.svUserPlaceOrder),
        headers: {
          'Content-Type': 'application/json',
          'access_token': token,
        },
        body: jsonEncode({
          'items': orderedItems,
          'total': total,
          'delivery_floor': deliveryFloor,
          'delivery_notes': deliveryNotes,
          if (refId != null) 'payment_ref_id': refId,
        }),
      );

      final responseData = jsonDecode(response.body);
      Globs.hideHUD();

      if (response.statusCode == 200 && responseData[KKey.status] == '1') {
        Cart.clear();
        _showSnackBar(context,
            'Order placed successfully! Order ID: ${responseData[KKey.payload]['order_id']}');
        Navigator.pop(context);
      } else {
        _showSnackBar(
            context, responseData[KKey.message] ?? 'Failed to place order');
      }
    } catch (e) {
      Globs.hideHUD();
      _showSnackBar(context, 'Error placing order. Please try again.');
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retry != null
            ? SnackBarAction(label: 'Retry', onPressed: retry)
            : null,
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
      child: Icon(Icons.fastfood, size: 20, color: TColor.secondaryText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        title: Text("Checkout",
            style: TextStyle(
              color: TColor.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
        leading: IconButton(
          icon: Image.asset("assets/img/btn_back.png", width: 20, height: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummary(context),
              const SizedBox(height: 15),
              _buildDeliveryDetails(),
              const SizedBox(height: 15),
              Divider(color: TColor.secondaryText.withOpacity(0.5), height: 1),
              const SizedBox(height: 15),
              _buildTotalSection(),
              const SizedBox(height: 30),
              RoundButton(
                  title: "Make Payment",
                  onPressed: () => _initiatePayment(context)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Order Summary",
            style: TextStyle(
              color: TColor.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
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
                color: TColor.secondaryText.withOpacity(0.5)),
            itemBuilder: (context, index) {
              var item = orderedItems[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Row(
                  children: [
                    ClipOval(
                      child: item["image"]?.isNotEmpty == true
                          ? Image.network(item["image"],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderIcon())
                          : _buildPlaceholderIcon(),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text("${item["name"]} x${item["qty"]}",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                    Text(
                        "Rs. ${(item["price"] * item["qty"]).toStringAsFixed(2)}",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Delivery Details",
            style: TextStyle(
              color: TColor.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 8),
        Text("Deliver to: $deliveryFloor Floor",
            style: TextStyle(color: TColor.secondaryText, fontSize: 13)),
        if (deliveryNotes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text("Notes: $deliveryNotes",
                style: TextStyle(color: TColor.secondaryText, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Total",
            style: TextStyle(
              color: TColor.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            )),
        Text("Rs. ${total.toStringAsFixed(2)}",
            style: TextStyle(
              color: TColor.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
