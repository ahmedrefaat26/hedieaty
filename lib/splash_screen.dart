import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hedieaty/get_started_screen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      backgroundColor: Colors.lightBlue ,
      splash: Column(
        children: [
          Center(
            child: SizedBox(
              width: 300, // Set a specific width
              height: 300, // Set a specific height
              child: LottieBuilder.asset("assets/splash.json"),
            ),
          )
        ],
      ),
      splashIconSize: 400,
      nextScreen: GetStartedScreen(),
    );
  }
}
