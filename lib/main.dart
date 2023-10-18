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

import 'package:geolocator/geolocator.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:geolocator_android/geolocator_android.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync<ThemeController>(() => ThemeController.init(),
      permanent: true);

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
  List<Map<String, double>> locationData = [];
  StreamSubscription<geoLoc.Position>? positionStream;

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

  if (riderId != null && authToken != null && riderId != "" && authToken != "") {

    GeolocatorPlatform geolocator = GeolocatorPlatform.instance;

    LocationSettings locationSettings = AndroidSettings(
        accuracy: geoLoc.LocationAccuracy.high,
        distanceFilter: 100,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
          "Example app will continue to receive your location even when you aren't using it",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
        ),
        forceLocationManager: true);


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
                      "https://backend.eviman.co.in/api/rider_data/v1/create-rider-data",
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
                      "https://backend.eviman.co.in/api/rider_data/v1/create-rider-data",
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
                        print("Message is: >>1" + (e.response?.data ?? "").toString());
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
  }



  if (vehicleId != null && authToken != null && vehicleId != "" && authToken != ""){
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      Position? curentPosition;
      vehicleId = await SharedPreferencesKeys().getStringData(key: 'vehicleId');
      authToken = await SharedPreferencesKeys().getStringData(key: 'authToken');
      print("background Service call\n ");
      if (vehicleId != null && authToken != null && vehicleId != "" && authToken != "") {
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
                for(int i=0;i<placeMarks.length;i++){
                  if(placeMarks[i].subLocality != null && placeMarks[i].locality != null){
                    locationDetails = placeMarks[i];
                    break;
                  }
                }

              }
              Map<String, dynamic> postData = {
                "currentCity": await getLocality(position)?? locationDetails?.locality ?? "India",
                "currentLocality": await getSubLocality(position)?? ((locationDetails?.subLocality != null && locationDetails?.subLocality != "")?(locationDetails?.subLocality ?? locationDetails?.locality ?? "India"):locationDetails?.locality),
                "lat": (position.latitude ?? 0).toString(),
                "lng": (position.longitude ?? 0).toString()
              };
              print(">>>>>postData" + postData.toString());
              // print(">>>>>>>>api" + "https://backend.eviman.co.in/api/vehicles/v1/update/location/" + (vehicleId ?? 0).toString());
              try {
                var dio = Dio();
                service1.Response response = await dio.patch(
                  "https://backend.eviman.co.in/api/vehicles/v1/update/location/${vehicleId ?? 0}",
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
              // Fluttertoast.showToast(msg: e.toString());
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
              // Fluttertoast.showToast(msg: "To avail our app functionality it's mandatory to enable your location");
            });
          }
        }
      }
    });
  }
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
        autoStart: false,
        notificationChannelId: "eViman-rider",
        initialNotificationTitle: "eViman background service enable",
        initialNotificationContent: "It's following data security policy",
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: false),
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

@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
Future<String> getLocality(Position position) async {
  String data = "Rourkela";
  List<Placemark> placeMarks = await placemarkFromCoordinates(
      position.latitude, position.longitude);
  try{
    Placemark? locationDetails = placeMarks.firstWhere((element) => element.locality != null &&
        (element.locality??"").toString().trim() != "" && element.locality != "null");
    data = locationDetails.locality??"Rourkela";
  }catch(e){
    data = "Rourkela";
  }
  return data;
}


@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point", "call")
Future<String> getSubLocality(Position position) async {
  String data = "Rourkela";
  List<Placemark> placeMarks = await placemarkFromCoordinates(
      position.latitude, position.longitude);
  try{
    Placemark? locationDetails = placeMarks.firstWhere((element) => element.subLocality != null &&
        (element.subLocality??"").toString().trim() != "" && element.subLocality != "null");
    data = locationDetails.subLocality??"Rourkela";
  }catch(e){
    data = "Rourkela";
  }
  return data;
}

