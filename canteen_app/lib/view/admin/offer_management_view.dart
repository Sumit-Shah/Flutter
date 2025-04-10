import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class OfferManagementView extends StatefulWidget {
  const OfferManagementView({super.key});

  @override
  State<OfferManagementView> createState() => _OfferManagementViewState();
}

class _OfferManagementViewState extends State<OfferManagementView> {
  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      // Fetch offers
      final offerResponse = await http.get(
        Uri.parse('${SVKey.baseUrl}offers'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch restaurants
      final restaurantResponse = await http.get(
        Uri.parse('${SVKey.baseUrl}restaurants'),
        headers: {'Content-Type': 'application/json'},
      );

      if (offerResponse.statusCode == 200 &&
          restaurantResponse.statusCode == 200) {
        final offerObj = json.decode(offerResponse.body);
        final restaurantObj = json.decode(restaurantResponse.body);

        if (offerObj[KKey.status] == "1" && restaurantObj[KKey.status] == "1") {
          setState(() {
            offers = List<Map<String, dynamic>>.from(offerObj[KKey.payload]);
            restaurants =
                List<Map<String, dynamic>>.from(restaurantObj[KKey.payload]);
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
        title: const Text("Offer Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddEditOfferDialog();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                return Card(
                  child: ListTile(
                    title: Text(offer['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Discount: ${offer['discount']}%'),
                        Text('Valid until: ${offer['valid_until']}'),
                        Text(
                            'Restaurant: ${_getRestaurantName(offer['restaurant_id'])}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showAddEditOfferDialog(offer: offer);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(offer['id']);
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

  String _getRestaurantName(int restaurantId) {
    final restaurant = restaurants.firstWhere(
      (r) => r['id'] == restaurantId,
      orElse: () => {'name': 'Unknown'},
    );
    return restaurant['name'];
  }

  void _showAddEditOfferDialog({Map<String, dynamic>? offer}) {
    final titleController = TextEditingController(text: offer?['title']);
    final discountController =
        TextEditingController(text: offer?['discount']?.toString());
    final descriptionController =
        TextEditingController(text: offer?['description']);
    final validUntilController =
        TextEditingController(text: offer?['valid_until']);
    int? selectedRestaurantId = offer?['restaurant_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer == null ? 'Add Offer' : 'Edit Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundTextfield(
                hintText: "Title",
                controller: titleController,
              ),
              const SizedBox(height: 10),
              RoundTextfield(
                hintText: "Discount (%)",
                controller: discountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              RoundTextfield(
                hintText: "Valid Until (YYYY-MM-DD)",
                controller: validUntilController,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: selectedRestaurantId,
                decoration: InputDecoration(
                  labelText: 'Restaurant',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: restaurants.map((restaurant) {
                  return DropdownMenuItem<int>(
                    value: restaurant['id'],
                    child: Text(restaurant['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRestaurantId = value;
                },
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
                'title': titleController.text,
                'discount': double.parse(discountController.text),
                'description': descriptionController.text,
                'valid_until': validUntilController.text,
                'restaurant_id': selectedRestaurantId,
              };

              if (offer != null) {
                data['id'] = offer['id'];
                await _updateOffer(data);
              } else {
                await _addOffer(data);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOffer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}offers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Offer added successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  Future<void> _updateOffer(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${SVKey.baseUrl}offers/${data['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Offer updated successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }

  void _showDeleteConfirmationDialog(int offerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteOffer(offerId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOffer(int offerId) async {
    try {
      final response = await http.delete(
        Uri.parse('${SVKey.baseUrl}offers/$offerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          fetchData();
          mdShowAlert(Globs.appName, "Offer deleted successfully", () {});
        }
      }
    } catch (err) {
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
