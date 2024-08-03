import 'package:flutter/material.dart';
import 'dart:async';
import 'package:attendance/wrapper.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    // Initialize the AnimationController and Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Start the animation
    _controller.forward();

    // Navigate to Wrapper screen after 3 seconds
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        FadePageRoute(page: Wrapper()), // Pass the page argument
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 151, 195, 220),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/logo3.png'), // Your splash screen image
        ),
      ),
    );
  }
}

class FadePageRoute extends PageRouteBuilder {
  final Widget page;
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
