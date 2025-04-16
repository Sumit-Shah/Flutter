import 'dart:convert';

import 'package:canteen_app/common/globs.dart';
import 'package:canteen_app/view/admin/admin_dashboard_view.dart';
import 'package:canteen_app/view/main_tabview/main_tabview.dart';
import 'package:flutter/material.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StarupViewState();
}

class _StarupViewState extends State<StartupView> {
  @override
  void initState() {
    super.initState();
    goWelcomePage();
  }

  void goWelcomePage() async {
    await Future.delayed(const Duration(seconds: 3));
    welcomePage();
  }

  void welcomePage() {
    final session = json.decode(Globs.udValueString(Globs.userPayload));

    if (session["user_type"] == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const MainTabView()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const AdminDashboardView()));
    }
  }

  @override
  Widget build(BuildContext content) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/img/splash_bg.png",
            width: media.width,
            height: media.height,
            fit: BoxFit.cover,
          ),
          Image.asset(
            "assets/img/foods.png",
            width: media.width * 0.55,
            height: media.width * 0.55,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
