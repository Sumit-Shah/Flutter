import 'package:canteen_app/common/color_extension.dart';
import 'package:canteen_app/common_widget/round_button.dart';
import 'package:flutter/material.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Image.asset(
                  "assets/img/welcome_top_shape.png",
                  width: media.width,
                ),
                Image.asset(
                  "assets/img/ing_logo.png",
                  width: media.width * 0.55,
                  height: media.width * 0.55,
                  fit: BoxFit.contain,
                ),
              ],
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Text(
              "Discover the best foods from our \nCanteen and fast delivery to your\nplace",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(
              height: media.width * 0.1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: "Login",
                onPressed: () {
                  // Navigator.push(context,
                  //     MaterialPageRoute(
                  //       builder: (context) => const LoginView(),
                  //     ),
                  //     );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: "Create an Account",
                type: RoundButtonType.textPrimary,
                onPressed: () {
                  // Navigator.push(context,
                  //     MaterialPageRoute(
                  //       builder: (context) => const SignUpView(),
                  //     ),
                  //     );
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:canteen_app/common/color_extension.dart';
// import 'package:flutter/material.dart';

// class WelcomeView extends StatefulWidget {
//   const WelcomeView({super.key});

//   @override
//   State<WelcomeView> createState() => _WelcomeViewState();
// }

// class _WelcomeViewState extends State<WelcomeView> {
//   @override
//   Widget build(BuildContext context) {
//     var media = MediaQuery.of(context).size;

//     return Scaffold(
//       body: Column(
//         children: [
//           Stack(
//             alignment: Alignment.bottomCenter,
//             children: [
//               Image.asset("canteen_app/assets/img/welcome_top_shape.png",
//                   width: media.width),
//               Image.asset(
//                 "assets/img/foods.png",
//                 width: media.width * 0.55,
//                 height: media.width * 0.55,
//                 fit: BoxFit.contain,
//               ),
//             ],
//           ),
//           SizedBox(
//             height: media.width * 0.1,
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 25),
//             child: Container(
//               height: 56,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                   color: TColor.primary, borderRadius: BorderRadius.circular(28),),
//                 child: Text("Login", style: TextStyle(color: TColor.white, fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//             ),
//           ),
//           SizedBox(
//             height: media.width * 0.1,
//           ),
//         ],
//       ),
//     );
//   }
// }
