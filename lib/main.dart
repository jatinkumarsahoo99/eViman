import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';
import 'package:vibration/vibration.dart';

import 'MainClass.dart';
import 'app/constants/shared_preferences_keys.dart';
import 'app/data/BinderData.dart';
import 'app/logic/controllers/theme_provider.dart';
import 'app/modules/driverDashboard/controllers/workmanager_initializer.dart';
import 'app/providers/flutterbackgroundservices.dart';
import 'app/routes/app_pages.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:dio/dio.dart' as service1;
import 'package:geolocator/geolocator.dart' as geoLoc;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

/*  await Permission.locationAlways.isDenied.then((value) {
    if(value){
      Permission.locationAlways.request();
    }
  }) ;
  await Permission.location.isDenied.then((value) {
    if(value){
      Permission.location.request();
    }
  }) ;
  await Permission.notification.isDenied.then((value) {
    if(value){
      Permission.notification.request();
    }
  }) ;*/
  await Get.putAsync<ThemeController>(() => ThemeController.init(),
      permanent: true);
  // final int helloAlarmID = 0;
  // await AndroidAlarmManager.initialize();
  // await AndroidAlarmManager.periodic(const Duration(seconds: 3), helloAlarmID, BackgroundTask.printHello);

  // initializeWorkManager();
  await initializeService();

  await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((_) => runApp(MainClass()));

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }
}

@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // handleLocationPermission();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String sta = "false";
  StreamSubscription<geoLoc.Position>? positionStream;
  geoLoc.GeolocatorPlatform geolocator = geoLoc.GeolocatorPlatform.instance;
  List<Map<String, double>> locationData = [];
  geoLoc.LocationSettings locationSettings = geoLoc.AndroidSettings(
      accuracy: geoLoc.LocationAccuracy.high,
      distanceFilter: 500,
      forceLocationManager: true);

  if (service is AndroidServiceInstance) {
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  String? vehicleId = await SharedPreferencesKeys().getStringData(key: 'vehicleId');
  String? riderId = await SharedPreferencesKeys().getStringData(key: 'riderId');
  String? authToken =
      await SharedPreferencesKeys().getStringData(key: 'authToken');

  positionStream =
      geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (geoLoc.Position position) async {
      // sendPort.send(position.toJson());
      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      locationData.add(data);
      print(">>>>>>>>>message from isolate JKS3" + locationData.toString());

      checkInternetConnectivity().then((value) async {
        if(value){

          String ? isInternetError = await SharedPreferencesKeys().getStringData(key: 'isInternetError');
          String ? listData = await SharedPreferencesKeys().getStringData(key: 'latLngForDst');
          if(isInternetError == "yes"){
           /* flutterLocalNotificationsPlugin.show(
              888,
              "Eviman App",
              "Currently I am testing(balanced)",
              const NotificationDetails(
                  android: AndroidNotificationDetails(
                    "eViman-rider",
                    "MY FOREGROUND SERVICE",
                    icon: 'ic_bg_service_small',
                    ongoing: true,
                  )),
            );*/

            Map<String,dynamic> postDataNew = {
              "data":listData??"" ,
              "dateTime":"",
              "rider_id":riderId??""
            };
            print(">>>>>>>>>>>>>>>postData"+postDataNew.toString());

            try {
              var dio = Dio();
              service1.Response response = await dio.post(
                "http://65.1.169.159:3000/api/rider_data/v1/create-rider-data",
                options: Options(headers: {
                  "Authorization":
                  "Bearer " + ((authToken != null) ? authToken ?? '' : "")
                }),
                data: (postDataNew != null) ? jsonEncode(postDataNew) : null,
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                try {} catch (e) {
                  print("Message is: " + e.toString());
                }
              }
              else if (response.statusCode == 417) {
              } else {
                print("Message is: >>1");
              }
            } on DioError catch (e) {
              switch (e.type) {
                case DioErrorType.connectTimeout:
                case DioErrorType.cancel:
                case DioErrorType.sendTimeout:
                case DioErrorType.receiveTimeout:
                case DioErrorType.other:
                  print("Message is: >>1" + e.toString());
                  break;
                case DioErrorType.response:
                  print(
                      "Message is: >>1" + (e.response?.data ?? "").toString());
              }
            }

          }
          else{
           /* flutterLocalNotificationsPlugin.show(
              888,
              "Eviman App",
              "Currently I am testing(normal)",
              const NotificationDetails(
                  android: AndroidNotificationDetails(
                    "eViman-rider",
                    "MY FOREGROUND SERVICE",
                    icon: 'ic_bg_service_small',
                    ongoing: true,
                  )),
            );*/

            Map<String,dynamic> postDataNew = {
              "data":jsonEncode({'list': locationData}),
              "dateTime":"",
              "rider_id":riderId??""
            };
            print(">>>>>>>>>>>>>>>postData"+postDataNew.toString());
            try {
              var dio = Dio();
              service1.Response response = await dio.post(
                "http://65.1.169.159:3000/api/rider_data/v1/create-rider-data",
                options: Options(headers: {
                  "Authorization":
                  "Bearer " + ((authToken != null) ? authToken ?? '' : "")
                }),
                data: (postDataNew != null) ? jsonEncode(postDataNew) : null,
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                try {} catch (e) {
                  print("Message is: " + e.toString());
                }
              }
              else if (response.statusCode == 417) {
              } else {
                print("Message is: >>1");
              }
            } on DioError catch (e) {
              switch (e.type) {
                case DioErrorType.connectTimeout:
                case DioErrorType.cancel:
                case DioErrorType.sendTimeout:
                case DioErrorType.receiveTimeout:
                case DioErrorType.other:
                  print("Message is: >>1" + e.toString());
                  break;
                case DioErrorType.response:
                  print(
                      "Message is: >>1" + (e.response?.data ?? "").toString());
              }
            }

          }

          await SharedPreferencesKeys().setStringData(key: "isInternetError", text: "no");
        }else{
          await SharedPreferencesKeys().setStringData(key: "isInternetError", text: "yes");
          await SharedPreferencesKeys().setStringData(key: "latLngForDst", text: jsonEncode({"list": locationData}));
          /*flutterLocalNotificationsPlugin.show(
            888,
            "Eviman App",
            "Currently I am testing with offline(pending)",
            const NotificationDetails(
                android: AndroidNotificationDetails(
                  "eViman-rider",
                  "MY FOREGROUND SERVICE",
                  icon: 'ic_bg_service_small',
                  ongoing: true,
                )),
          );*/
        }
      });


    },
    onError: (e) {
      print(">>>>>>>>>>exception" + e.toString());
      // sendPort.send("Error: $e");
    },
    cancelOnError: true,
  );

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    Position? curentPosition;
    vehicleId = await SharedPreferencesKeys().getStringData(key: 'vehicleId');
    authToken = await SharedPreferencesKeys().getStringData(key: 'authToken');
    // print(">>>>>>>>>>>authToken????\n " + authToken.toString());
    if (vehicleId != null && authToken != null) {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                  forceAndroidLocationManager: true)
              .then((Position position) async {
            curentPosition = position;
            print("bg location ${position.latitude}");
            Placemark? locationDetails;
            List<Placemark> placeMarks = await placemarkFromCoordinates(
                position.latitude, position.longitude);
            if (placeMarks.isNotEmpty) {
              locationDetails = placeMarks.first;
            }
            Map<String, dynamic> postData = {
              "currentCity": locationDetails?.locality ?? "",
              "currentLocality": locationDetails?.subLocality ?? "",
              "lat": (position.latitude ?? 0).toString(),
              "lng": (position.longitude ?? 0).toString()
            };
            // print(">>>>>postData" + postData.toString());
            // print(">>>>>>>>api" + "http://65.1.169.159:3000/api/vehicles/v1/update/location/" + (vehicleId ?? 0).toString());
            try {
              var dio = Dio();
              service1.Response response = await dio.patch(
                "http://65.1.169.159:3000/api/vehicles/v1/update/location/${vehicleId ?? 0}",
                options: Options(headers: {
                  "Authorization":
                      "Bearer " + ((authToken != null) ? authToken ?? '' : "")
                }),
                data: (postData != null) ? jsonEncode(postData) : null,
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                try {} catch (e) {
                  print("Message is: " + e.toString());
                }
              } else if (response.statusCode == 417) {
              } else {
                print("Message is: >>1");
              }
            } on DioError catch (e) {
              switch (e.type) {
                case DioErrorType.connectTimeout:
                case DioErrorType.cancel:
                case DioErrorType.sendTimeout:
                case DioErrorType.receiveTimeout:
                case DioErrorType.other:
                  print("Message is: >>1" + e.toString());
                  break;
                case DioErrorType.response:
                  print(
                      "Message is: >>1" + (e.response?.data ?? "").toString());
              }
            }
          }).catchError((e) {
            Fluttertoast.showToast(msg: e.toString());
          });
        }
      }
    } else {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                  forceAndroidLocationManager: true)
              .then((Position position) {
            curentPosition = position;
            print("bg location ${position.latitude}");
            /*flutterLocalNotificationsPlugin.show(
              888,
              "Eviman App",
              "Currently we are starting our background service for updating you current location",
              const NotificationDetails(
                  android: AndroidNotificationDetails(
                "eViman-rider",
                "MY FOREGROUND SERVICE",
                icon: 'ic_bg_service_small',
                ongoing: true,
              )),
            );*/
          }).catchError((e) {
            Fluttertoast.showToast(msg: "To avail our app functionality it's mandatory to enable your location");
          });
        }
      }
    }
  });

  // print(">>>>>>>>>>>authToken????\n " + authToken.toString());
}

@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
      "eViman-rider", "initializing eViman background service",
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('excuseme_boss'),
      description: "Background service for location fetching",
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      ledColor: Colors.green,
      showBadge: true);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true,
        autoStart: true,
        notificationChannelId: "eViman-rider",
        initialNotificationTitle: "Location service enable",
        initialNotificationContent: "initializing eViman background service",
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true),
  );
  await service.startService();
}

@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
Future<bool> checkInternetConnectivity() async {
  final connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
// I am connected to a mobile network.
    return true;
  } else if (connectivityResult == ConnectivityResult.wifi) {
// I am connected to a wifi network.
    return true;
  } else if (connectivityResult == ConnectivityResult.ethernet) {
// I am connected to a ethernet network.
    return true;
  } else {
    return false;
  }
}
