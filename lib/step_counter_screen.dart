import 'dart:async';
import 'package:deumyproject/services.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({Key? key}) : super(key: key);

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {

  SharedPreferences? preferences;
  bool appOpenFirstTime = false;
  int totalStep = 0;
  int todaySteps = 0;
  int? yesterdaySteps = 0;
  double? todayEarnTotalCoin = 0;

  @override
  void initState() {
    requestPermission();
    super.initState();
  }

  check() async {

    appOpenFirstTime = preferences!.getBool("opened") ?? false;

    print("App Opened First Time : $appOpenFirstTime");

    if (appOpenFirstTime) {
      todaySteps = totalStep;
      preferences!.setBool("opened", true);
      print("todaySteps <<< $todaySteps");
    } else {
      yesterdaySteps = preferences!.getInt("steps") ?? 0;
      todaySteps = preferences!.getInt("today") ?? 0;
      print("yesterdaySteps ?? $yesterdaySteps");
      print("todaySteps ?? $todaySteps");
    }
    setState(() {});
  }

  Stream<StepCount>? _stepCountStream;

  /// Handle step count changed
  void onStepCount(StepCount event) {
    totalStep = event.steps;

    // if (appOpenFirstTime) {
    //   yesterdaySteps = totalStep;
    //   preferences!.setInt("steps", yesterdaySteps!);
    //   print("todaySteps <<< $todaySteps");
    //   print("yesterdaySteps =<<< : $yesterdaySteps");
    // }

    todaySteps = totalStep - yesterdaySteps!;
    preferences!.setInt("today", todaySteps);
    print("TOTAL STEPS : $totalStep");
    print("yesterdaySteps => : $yesterdaySteps");

    /// Earn coin calculator
    int totalStepCount = todaySteps;
    double totalEarn = 1050;
    if (totalEarn != 0) {
      todayEarnTotalCoin = totalStepCount / totalEarn;
    } else {
      todayEarnTotalCoin = double.infinity;
    }
    setState(() {});
  }

  void onStepCountError(error) {}

  Future<void> initPlatformState() async {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream!.listen(onStepCount).onError(onStepCountError);
  }

  Future<void> requestPermission() async {
    preferences = await SharedPreferences.getInstance();
    const permission = Permission.activityRecognition;

    if (await permission.isDenied) {
      final result = await permission.request();
      if (result.isGranted) {
        print("Permission is granted");
        initPlatformState();
        await initializeService();
      } else if (result.isDenied) {
        print("Permission is denied");
      } else if (result.isPermanentlyDenied) {
        print("Permission is permanently denied");
      }
    } else if (await permission.isGranted) {
      print("Permission Granted trying to read the value");
      check();
      initPlatformState();
      await initializeService();
    }

  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Text("STEP COUNTER : $todaySteps", style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 25),
            Text("COIN FOR TODAY : ${todayEarnTotalCoin!.toStringAsFixed(2)}", style: const TextStyle(fontSize: 25)),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
