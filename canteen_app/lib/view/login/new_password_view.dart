import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common/extension.dart';
import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:canteen_app/view/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../common_widget/round_textfield.dart';

class NewPasswordView extends StatefulWidget {
  final Map nObj;
  const NewPasswordView({super.key, required this.nObj});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();

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
                "New Password",
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "Please enter your new password",
                style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(
                height: 60,
              ),
              RoundTextfield(
                hintText: "New Password",
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(
                height: 25,
              ),
              RoundTextfield(
                hintText: "Confirm Password",
                controller: txtConfirmPassword,
                obscureText: true,
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

  // TODO: Action
  void btnSubmit() {
    if (txtPassword.text.length < 6) {
      mdShowAlert(Globs.appName, MSG.enterPassword, () {});
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      mdShowAlert(Globs.appName, MSG.enterPasswordNotMatch, () {});
      return;
    }

    endEditing();

    serviceCallForgotSetNew({
      "user_id": widget.nObj[KKey.userId].toString(),
      "reset_code": widget.nObj[KKey.resetCode].toString(),
      "new_password": txtPassword.text
    });
  }

  // TODO: ServiceCall

  void serviceCallForgotSetNew(Map<String, dynamic> parameter) async {
    Globs.showHUD();

    try {
      final response = await http.post(
        Uri.parse(SVKey.svForgotPasswordSetNew),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(parameter),
      );

      Globs.hideHUD();

      if (response.statusCode == 200) {
        final responseObj = json.decode(response.body);
        if (responseObj[KKey.status] == "1") {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] as String? ?? MSG.success, () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false);
          });
        } else {
          mdShowAlert(Globs.appName,
              responseObj[KKey.message] as String? ?? MSG.fail, () {});
        }
      } else {
        mdShowAlert(Globs.appName,
            "Failed to set new password. Please try again.", () {});
      }
    } catch (err) {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    }
  }
}
