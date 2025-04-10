import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/login/otp_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_textfield.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  TextEditingController txtEmail = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 64,
              ),
              Text(
                "Reset Password",
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "Please enter your email to receive a reset code",
                style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                height: 60,
              ),
              RoundTextfield(
                hintText: "Email",
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(
                height: 30,
              ),
              RoundButton(
                  title: "Next",
                  onPressed: () {
                    btnSubmit();
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void btnSubmit() {
    if (!txtEmail.text.isEmail) {
      mdShowAlert(Globs.appName, MSG.enterEmail, () {});
      return;
    }

    endEditing();

    serviceCallForgotRequest({"email": txtEmail.text});
  }

  void serviceCallForgotRequest(Map<String, dynamic> parameter) async {
    Globs.showHUD();

    try {
      final response = await http.post(
        Uri.parse(SVKey.svForgotPasswordRequest),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(parameter),
      );

      Globs.hideHUD();

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPView(email: txtEmail.text),
            ),
          );
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] as String? ?? MSG.fail, () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to send reset code. Please try again.", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
