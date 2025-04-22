import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/more/cart.dart';
import 'package:flutter/material.dart';

import 'checkout_view.dart';

class MyOrderView extends StatefulWidget {
  const MyOrderView({super.key});

  @override
  State<MyOrderView> createState() => _MyOrderViewState();
}

class _MyOrderViewState extends State<MyOrderView> {
  String _selectedFloor = 'First'; // Default floor
  final List<String> _floors = ['First', 'Second', 'Third'];
  String _deliveryNotes = ''; // Store delivery notes
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showNotesDialog() {
    _notesController.text = _deliveryNotes; // Pre-fill with existing notes
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Delivery Notes'),
        content: TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter delivery instructions',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _deliveryNotes = _notesController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Image.asset(
                        "assets/img/btn_back.png",
                        width: 20,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "My Order",
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: TColor.textfield),
                child: Cart.items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "Your cart is empty",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: Cart.items.length,
                        separatorBuilder: (context, index) => Divider(
                          indent: 25,
                          endIndent: 25,
                          color: TColor.secondaryText.withOpacity(0.5),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          var item = Cart.items[index];
                          return Container(
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
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  _buildPlaceholderIcon(),
                                        )
                                      : _buildPlaceholderIcon(),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    item["name"],
                                    style: TextStyle(
                                      color: TColor.primaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          Cart.updateQuantity(
                                              item["name"], item["qty"] - 1);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: TColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                    Text(
                                      "${item["qty"]}",
                                      style: TextStyle(
                                        color: TColor.primaryText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          Cart.updateQuantity(
                                              item["name"], item["qty"] + 1);
                                        });
                                      },
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: TColor.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 15),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deliver Radio Buttons
                    Text(
                      "Deliver",
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Column(
                      children: _floors.map((floor) {
                        return RadioListTile<String>(
                          value: floor,
                          groupValue: _selectedFloor,
                          onChanged: (value) {
                            setState(() {
                              _selectedFloor = value!;
                            });
                          },
                          title: Text(
                            '$floor Floor',
                            style: TextStyle(
                              color: TColor.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          activeColor: TColor.primary,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Delivery Instructions",
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showNotesDialog,
                          icon: Icon(Icons.add, color: TColor.primary),
                          label: Text(
                            "Add Notes",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_deliveryNotes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _deliveryNotes,
                          style: TextStyle(
                            color: TColor.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Divider(
                      color: TColor.secondaryText.withOpacity(0.5),
                      height: 20,
                    ),
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
                          "Rs. ${Cart.getTotal().toStringAsFixed(2)}",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    RoundButton(
                      title: "Proceed to Checkout",
                      onPressed: () {
                        if (Cart.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please add at least one item to your order"),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutView(
                              orderedItems: Cart.items,
                              total: Cart.getTotal(),
                              deliveryFloor: _selectedFloor,
                              deliveryNotes: _deliveryNotes,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
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
