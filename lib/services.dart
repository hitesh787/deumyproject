import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    "step",
    "step service",
    importance: Importance.high,
    playSound: false,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: "step",
      initialNotificationTitle: "step service",
      initialNotificationContent: "initializing",
      foregroundServiceNotificationId: 888,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  int todaySteps = 0;
  // DateTime stepsInAnHour = DateTime.now();
  // int stepsInAnHour1 = 0;

  // final controller = StreamController<String>();
  Pedometer.stepCountStream.listen(
    (event) async {
      todaySteps = event.steps;

      // for(int i=0;i<event.steps;i++){
      //   todaySteps = i;
      //   print("Today Steps ::  $todaySteps");
      // }

      // stepsInAnHour = event.timeStamp;
      // Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      //   stepsInAnHour1 = todaySteps;
      //   print("TOTAL HOURS $stepsInAnHour1");
      // });

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          flutterLocalNotificationsPlugin.show(
            888,
            "Step Counter",
            "Today Step $todaySteps",
            NotificationDetails(
                android: AndroidNotificationDetails(
              "step",
              "step service",
              icon: 'ic_bg_service_small',
              ongoing: true,
              playSound: false,
            )),
          );
        }
      }
    },
  );
}
