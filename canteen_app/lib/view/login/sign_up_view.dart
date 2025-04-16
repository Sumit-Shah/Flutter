import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_io/io.dart';
import '../../common_widget/round_textfield.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();
  final TextEditingController txtMobile = TextEditingController();
  final TextEditingController txtAddress = TextEditingController();
  String _pushToken = "";
  String _deviceType = "unknown";

  @override
  void initState() {
    super.initState();
    _detectDeviceType();
    // _getPushToken(); // Uncomment if are using push notifications
  }

  void _detectDeviceType() {
    if (Platform.isAndroid) {
      _deviceType = "android";
    } else if (Platform.isIOS) {
      _deviceType = "ios";
    } else {
      _deviceType = "web";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Text(
                "Sign Up",
                style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Create your account",
                style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              RoundTextfield(
                hintText: "Name",
                controller: txtName,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Email",
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Password",
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Confirm Password",
                controller: txtConfirmPassword,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Mobile",
                controller: txtMobile,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: "Address",
                controller: txtAddress,
              ),
              const SizedBox(height: 30),
              RoundButton(
                title: "Sign Up",
                onPressed: btnSubmit,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginView(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: TColor.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Login",
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void btnSubmit() {
    if (txtName.text.isEmpty) {
      mdShowAlert(Globs.appName, MSG.enterName, () {});
      return;
    }

    if (!txtEmail.text.isEmail) {
      mdShowAlert(Globs.appName, MSG.enterEmail, () {});
      return;
    }

    if (txtPassword.text.length < 6) {
      mdShowAlert(Globs.appName, MSG.enterPassword, () {});
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      mdShowAlert(Globs.appName, MSG.enterPasswordNotMatch, () {});
      return;
    }

    if (txtMobile.text.isEmpty) {
      mdShowAlert(Globs.appName, MSG.enterMobile, () {});
      return;
    }

    if (txtAddress.text.isEmpty) {
      mdShowAlert(Globs.appName, MSG.enterAddress, () {});
      return;
    }

    endEditing();

    serviceCallRegister({
      "name": txtName.text,
      "email": txtEmail.text,
      "password": txtPassword.text,
      "mobile": txtMobile.text,
      "address": txtAddress.text,
      "push_token": _pushToken,
      "device_type": _deviceType,
    });
  }

  Future<void> serviceCallRegister(Map<String, dynamic> parameter) async {
    Globs.showHUD();

    try {
      final response = await http
          .post(
            Uri.parse(SVKey.svSignUp),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(parameter),
          )
          .timeout(const Duration(seconds: 30));

      Globs.hideHUD();

      final responseObj = json.decode(response.body);

      if (response.statusCode == 200 && responseObj[KKey.status] == "1") {
        mdShowAlert(
          Globs.appName,
          responseObj[KKey.message] ?? "Registration successful",
          () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginView()),
              (route) => false,
            );
          },
        );
      } else {
        mdShowAlert(
          Globs.appName,
          responseObj[KKey.message] ?? "Registration failed",
          () {},
        );
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(
          Globs.appName, "Something went wrong. Please try again.", () {});
      debugPrint("Registration error: $err");
    }
  }

  void endEditing() {
    FocusScope.of(context).unfocus();
  }
}
