import 'package:flutter/material.dart';
import 'package:connect/menupage/mainp.dart';
import 'package:lottie/lottie.dart';

class TaskPostedAnimationScreen extends StatefulWidget {
  const TaskPostedAnimationScreen({super.key});

  @override
  State<TaskPostedAnimationScreen> createState() => _TaskPostedAnimationScreenState();
}

class _TaskPostedAnimationScreenState extends State<TaskPostedAnimationScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds then navigate
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LottieWidget(),
      ),
    );
  }
}

class LottieWidget extends StatelessWidget {
  const LottieWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/images/animations/done.json', 
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }
}
