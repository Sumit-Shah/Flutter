import 'dart:io';
import 'dart:convert';
import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common/service_call.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/more/my_order_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../common_widget/round_textfield.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker picker = ImagePicker();
  XFile? image;
  bool isLoading = true;
  bool isSaving = false;

  TextEditingController txtName = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtMobile = TextEditingController();
  TextEditingController txtAddress = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final token = session['auth_token'] ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${SVKey.baseUrl}user/profile'),
        headers: {
          'access_token': token,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['payload'] != null) {
          final userData = data['payload'];
          setState(() {
            txtName.text = userData['name'] ?? '';
            txtEmail.text = userData['email'] ?? '';
            txtMobile.text = userData['mobile'] ?? '';
            txtAddress.text = userData['address'] ?? '';
            txtPassword.text = '';
            txtConfirmPassword.text = '';
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch profile');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (txtPassword.text.isNotEmpty &&
        txtPassword.text != txtConfirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final session = json.decode(Globs.udValueString(Globs.userPayload));
      final token = session['auth_token'] ?? '';

      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      var response = await http.post(
        Uri.parse('${SVKey.baseUrl}user/update_profile'),
        body: {
          'name': txtName.text,
          'email': txtEmail.text,
          'mobile': txtMobile.text,
          'address': txtAddress.text,
          'password': txtPassword.text,
        },
        headers: {'access_token': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1') {
          // Update local user data
          final updatedUserData = {
            ...session,
            'name': txtName.text,
            'email': txtEmail.text,
            'mobile': txtMobile.text,
            'address': txtAddress.text,
          };
          Globs.udSet(updatedUserData, Globs.userPayload);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _signOut() {
    ServiceCall.logout();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profile",
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: TColor.placeholder,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          File(image!.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 65,
                        color: TColor.secondaryText,
                      ),
              ),
              // TextButton.icon(
              //   onPressed: () async {
              //     image = await picker.pickImage(source: ImageSource.gallery);
              //     setState(() {});
              //   },
              //   icon: Icon(
              //     Icons.edit,
              //     color: TColor.primary,
              //     size: 12,
              //   ),
              //   // label: Text(
              //     // "Edit Profile",
              //     // style: TextStyle(color: TColor.primary, fontSize: 12),
              //   // ),
              // ),
              Text(
                "Hi there ${txtName.text}!",
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: _signOut,
                child: Text(
                  "Sign Out",
                  style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Name",
                  hintText: "Enter Name",
                  controller: txtName,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Email",
                  hintText: "Enter Email",
                  keyboardType: TextInputType.emailAddress,
                  controller: txtEmail,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Mobile No",
                  hintText: "Enter Mobile No",
                  controller: txtMobile,
                  keyboardType: TextInputType.phone,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Address",
                  hintText: "Enter Address",
                  controller: txtAddress,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Password",
                  hintText: "* * * * * *",
                  obscureText: true,
                  controller: txtPassword,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                child: RoundTitleTextfield(
                  title: "Confirm Password",
                  hintText: "* * * * * *",
                  obscureText: true,
                  controller: txtConfirmPassword,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoundButton(
                  title: isSaving ? "Saving..." : "Save",
                  onPressed: isSaving
                      ? () {}
                      : () {
                          _updateProfile();
                        },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
