import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'dart:math';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:dateplan/app/routes/app_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points_plus/flutter_polyline_points_plus.dart';
import 'package:geolocator/geolocator.dart' as geoLoc;

import 'package:permission_handler/permission_handler.dart' as permission;

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linear_timer/linear_timer.dart';
import 'package:location/location.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../amplifyconfiguration.dart';

import '../../../../models/ModelProvider.dart';
import '../../../constants/helper.dart';
import '../../../constants/shared_preferences_keys.dart';
import '../../../constants/text_styles.dart';
import '../../../widgets/CustomeTittleText.dart';
import '../../../widgets/MyWidget.dart';
import '../../../widgets/RoundedButtonWidget.dart';
import '../../../widgets/Snack.dart';
import '../../../widgets/common_button.dart';
import '../../ConnectorController.dart';
import '../../loginscreen/controllers/loginscreen_controller.dart';
import '../../profilescreen/ProfileViewModel.dart';
import '../CheckStatusModel.dart';
import '../IncomingBooikingModel.dart';
import '../IncomingBooking.dart';
import 'package:amplify_core/src/types/api/graphql/graphql_response.dart' as gr;

import '../LocationService.dart';
import '../SubscribeBookingDetailsModel.dart';
import 'AmplifyApiName.dart';
import 'package:geocoding/geocoding.dart' as geoc;
import 'package:http/http.dart' as http;

import 'location_isolate.dart';
part 'mapcontroller.dart';
part 'appsyncController.dart';
part 'helpercontroller.dart';

@pragma("vm:entry-point")
@pragma("vm:entry-point", true)
@pragma("vm:entry-point", !bool.fromEnvironment("dart.vm.product"))
@pragma("vm:entry-point", "get")
@pragma("vm:entry-point",
    "call") // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  DartPluginRegistrant.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    final position = await determinePosition();
    print(">>>>>>>>>position jks jks${position.longitude}");
    return Future.value(true);
  });
}

class DriverDashboardController extends GetxController
    with Helper, WidgetsBindingObserver, GetSingleTickerProviderStateMixin {
  List<Map<String, double>> locationDataFromIsolate = [];

  FlutterIsolate? isolateField;
  late AdvancedDrawerController advancedDrawerController;
  final count = 0.obs;
  LatLng sourceLocation = LatLng(20.288187, 85.817814);
  LatLng destination = LatLng(20.290983, 85.845584);

  Completer<GoogleMapController> mapControl = Completer<GoogleMapController>();
  List<LatLng> polylineCoordinates = [];
  GoogleMapController? mapController;

  LatLng? currentLocation = const LatLng(20.288187, 85.817814);

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  Rx<bool> isDisappear = Rx<bool>(false);
  double mapHeight = 0;

  List<List<LatLng>> routeCoordinates = [];

  int selectedRouteIndex = -1;
  Map<List<LatLng>, Color> routeColorsMap = {};
  List<Color> routeColors = [
    Colors.lime,
    Colors.grey,
    Colors.yellow,
    Colors.orange,
    Colors.deepPurple
  ];
  StreamSubscription<gr.GraphQLResponse<String>>? subscription;
  StreamSubscription<gr.GraphQLResponse<String>>? subscription2;

  String? riderIdNew;
  String? vehicleIdNew;
  String? authToken;

  geoc.Placemark? locationDetailsUser;
  IncomingBooikingModel? incomingBookingModel;
  CheckStatusModel? checkStatusModel;
  LinearTimerController? timerController;
  ProfileViewModel? profileViewModel;
  bool otpVerifiedStatus = false;
  getProfileDetails() {
    MyWidgets.showLoading3();
    Get.find<ConnectorController>().GETMETHODCALL_TOKEN(
        api:
            "https://backend.eviman.co.in/api/riders/v1/profile/${riderIdNew ?? 0}",
        token: authToken ?? "",
        fun: (map) {
          print(">>>>" + map.toString());
          Get.back();
          if (map is Map &&
              map.containsKey("success") &&
              map['success'] == true) {
            profileViewModel =
                ProfileViewModel.fromJson(map as Map<String, dynamic>);
            update(['prof']);
          } else {
            profileViewModel = null;
            Get.back();
            // Snack.callError("Something went wrong");
          }
        });
  }

  checkStatus() {
    MyWidgets.showLoading3();
    Get.find<ConnectorController>().GETMETHODCALL(
        api:
            "https://backend.eviman.co.in/api/riders/v1/online-status/${riderIdNew ?? ""}",
        fun: (map) {
          incomingBookingModel = null;
          print(">>>>>>>>>>>>>online-status" + map.toString());
          Get.back();
          if (map != null &&
              map is Map &&
              map.containsKey('success') &&
              map['success'] == true) {
            checkStatusModel =
                CheckStatusModel.fromJson(map as Map<String, dynamic>);
            if (checkStatusModel != null &&
                checkStatusModel?.riderStatus != null &&
                checkStatusModel?.riderStatus?.activeRide != null) {
              if (checkStatusModel?.riderStatus?.activeRide?.rideStatus
                          .toString()
                          .trim() ==
                      "CONFIRMED" ||
                  checkStatusModel?.riderStatus?.activeRide?.rideStatus
                          .toString()
                          .trim() ==
                      "OTP VERIFIED") {
                incomingBookingModel = IncomingBooikingModel(
                    incomingBooking: IncomingBooking(
                  bookingId:
                      checkStatusModel?.riderStatus?.activeRide?.bookingId ??
                          "",
                  clientLat:
                      checkStatusModel?.riderStatus?.activeRide?.pickupLat ??
                          "",
                  clientLng:
                      checkStatusModel?.riderStatus?.activeRide?.pickupLng ??
                          "",
                  destinationLng:
                      checkStatusModel?.riderStatus?.activeRide?.dropLng ?? "",
                  destinationLat:
                      checkStatusModel?.riderStatus?.activeRide?.dropLat ?? "",
                  dropAddress:
                      checkStatusModel?.riderStatus?.activeRide?.dropAddress ??
                          "",
                  pickupAddress: checkStatusModel
                          ?.riderStatus?.activeRide?.pickupAddress ??
                      "",
                  clientId:
                      checkStatusModel?.riderStatus?.activeRide?.clientId ?? 0,
                  // clientName: "",
                  clientName:
                      checkStatusModel?.riderStatus?.clientName ??
                          "JKS",
                  clientPhone: checkStatusModel?.riderStatus?.clientPhone ?? "",
                  fareInfo:
                      checkStatusModel?.riderStatus?.activeRide?.fareInfo ?? 0,
                  status:
                      checkStatusModel?.riderStatus?.activeRide?.rideStatus ??
                          "",
                  rider: int.tryParse(checkStatusModel
                          ?.riderStatus?.activeRide?.riderAssigned ??
                      "0"),
                ));
                subscribeBookingDetailsModel = SubscribeBookingDetailsModel(
                    subscribeBookingDetails: SubscribeBookingDetails(
                  bookingId:
                      checkStatusModel?.riderStatus?.activeRide?.bookingId ??
                          "",
                  bookingStatus:
                      checkStatusModel?.riderStatus?.activeRide?.rideStatus ??
                          "",
                  otp: checkStatusModel?.riderStatus?.activeRide?.otp ?? 0000,
                  riderId: int.tryParse(checkStatusModel
                          ?.riderStatus?.activeRide?.riderAssigned ??
                      "0"),
                  updatedById: int.tryParse(riderIdNew ?? "0"),
                  vehicleId: int.tryParse(vehicleIdNew ?? "0"),
                ));
                travelDist =
                    checkStatusModel?.riderStatus?.activeRide?.distance ?? "0";
                maxChildSize = Rx<double>(0.7);
                initialChildSize = Rx<double>(0.5);
                snapSize = Rx<List<double>>(
                    [0.1, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.6]);
                subscribeBookingDetails(
                    checkStatusModel?.riderStatus?.activeRide?.bookingId ?? "");
                if (checkStatusModel?.riderStatus?.activeRide?.rideStatus
                        .toString()
                        .trim() ==
                    "OTP VERIFIED") {
                  otpVerifiedStatus = true;
                }
                // getPolyPoints();
                setCustomMarkerIcon();
                update(['allPage','top']);
              }
            }

            if (checkStatusModel != null &&
                checkStatusModel?.riderStatus?.isOnline != null) {
              if (checkStatusModel?.riderStatus?.isOnline ?? false) {
                isDisappear = Rx<bool>(true);
                calBackgroundServices("true");
                subscribeIncomingBooking();
              } else {
                isDisappear = Rx<bool>(false);
                callOrStopServices();
              }
            }
            update(['allPage','top']);
          }
          else {
            incomingBookingModel = null;
            Snack.callError((map ?? "Something went wrong").toString());
          }
        });
  }

  getRiderId() async {
    riderIdNew = await SharedPreferencesKeys().getStringData(key: 'riderId');
    vehicleIdNew =
        await SharedPreferencesKeys().getStringData(key: 'vehicleId');
    authToken = await SharedPreferencesKeys().getStringData(key: 'authToken');
    getProfileDetails();
    getRideAnalytics();
    configureAmplify().then((value) {
      checkStatus();
    });
  }

  Future<void> configureAmplify() async {
    try {
      final api = AmplifyAPI(modelProvider: ModelProvider.instance);
      if (!(Amplify.isConfigured)) {
        await Amplify.addPlugins([api]);
        await Amplify.configure(amplifyconfig);
      }

      safePrint("Amplify configured successfully");
    } catch (e) {
      safePrint("Error configuring Amplify: $e");
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  void subscribeIncomingBooking() {
    print(">>>>>>>>>>>>>>>>>riderId" + riderIdNew.toString());
    int riderId = int.parse((riderIdNew != null && riderIdNew != "")
        ? ((riderIdNew ?? 0).toString())
        : "0"); // Replace with the desired rider ID

    // Subscribe to the GraphQL subscription with the parameter
    final Stream<gr.GraphQLResponse<String>> operation = Amplify.API.subscribe(
        GraphQLRequest<String>(
          document: """
          subscription IncomingBooking(\$rider: Int!) {
            incomingBooking(rider: \$rider) {
              rider
              clientLat
              clientLng
              clientName
              clientPhone
              clientId
              fareInfo
              bookingId
              destinationLat
              destinationLng
              dropAddress
              pickupAddress
              status
            }
          }
        """,
          variables: {
            'rider': riderId,
          },
        ), onEstablished: () {
      safePrint('Subscription established');
    });

    subscription = operation.listen(
      (event) {
        if (event.data != null) {
          Map? receiveDataNewClose = jsonDecode(event.data as String) ?? {};
          if(receiveDataNewClose != null &&
              receiveDataNewClose['incomingBooking']['status'].toString().trim() == "Booking Timeout"){
            // incomingBookingModel = null;
            // subscribeBookingDetailsModel = null;
            userDetails = "";
            closeDialogIfOpen();
          }
          else if (userDetails == "" && incomingBookingModel == null) {
            Map? receiveDataNew = jsonDecode(event.data as String) ?? {};
            // Booking Timeout
             if (receiveDataNew != null &&
                receiveDataNew['incomingBooking']['status'].toString().trim() ==
                    "Incoming Booking") {
              userDetails = (event.data ?? "").toString();
              Map? receiveData = jsonDecode(event.data as String) ?? {};
              incomingBookingModel = null;
              Vibration.vibrate();
              flutterLocalNotificationsPlugin.show(
                888,
                "Eviman App",
                "Please be ready for trips",
                const NotificationDetails(
                    android: AndroidNotificationDetails(
                        "eViman-rider", "foregrounf service",
                        icon: 'ic_bg_service_small',
                        ongoing: true,
                        enableVibration: true,
                        importance: Importance.high,
                        autoCancel: true,
                        sound: RawResourceAndroidNotificationSound(
                            'excuseme_boss'),
                        channelShowBadge: true,
                        enableLights: true,
                        color: Colors.green,
                        colorized: true,
                        playSound: true)),
              );
              calculateDistanceUsingAPI(
                      desLat: double.tryParse(
                          receiveData?['incomingBooking']['clientLat'] ?? "0"),
                      desLong: double.tryParse(
                          receiveData?['incomingBooking']['clientLng'] ?? "0"),
                      originLat: currentLocation?.latitude ?? 0,
                      originLong: currentLocation?.longitude ?? 0)
                  .then((value1) {
                calculateDistanceUsingAPI(
                        desLat: double.tryParse(receiveData?['incomingBooking']
                                ['destinationLat'] ??
                            "0"),
                        desLong: double.tryParse(receiveData?['incomingBooking']
                                ['destinationLng'] ??
                            "0"),
                        originLat: double.tryParse(
                            receiveData?['incomingBooking']['clientLat'] ??
                                "0"),
                        originLong: double.tryParse(
                            receiveData?['incomingBooking']['clientLng'] ??
                                "0"))
                    .then((value2) {
                  showRideAcceptDialog(Get.context!, Get.width * 0.9,
                      dropAddress: receiveData?['incomingBooking']
                          ['dropAddress'],
                      pickupAddress: receiveData?['incomingBooking']
                          ['pickupAddress'],
                      pickUpDistance: value1,
                      travelDistance: value2,
                      receiveData: receiveData);
                  safePrint("distance value2" + value2.toString());
                });
                safePrint("distance value1" + value1.toString());
              });

              safePrint(">>>>>>>>>>>mapData" + receiveData.toString());
            }
            else {
              // Snack.callSuccess("Please take action quick");
            }
          }
          else {
            // Snack.callSuccess("Please take action quick");
          }
        }
        safePrint('Subscription event data received: ${event.data}');
      },
      onError: (Object e) => safePrint('Error in subscription stream: $e'),
    );
  }

  String? pickUpDist;
  String? travelDist;
  SubscribeBookingDetailsModel? subscribeBookingDetailsModel;
  void subscribeBookingDetails(String? bookingId) {
    // Replace with the desired rider ID

    // Subscribe to the GraphQL subscription with the parameter
    final Stream<gr.GraphQLResponse<String>> operation = Amplify.API.subscribe(
        GraphQLRequest<String>(
          document: """
         subscription subscribeBookingDetails(\$bookingId: String!) {
    subscribeBookingDetails(bookingId: \$bookingId) {
    bookingId
    bookingStatus
    otp
    riderId
    updatedBy
    updatedById
    updatedByUserType
    vehicleId
    }
}
        """,
          variables: {
            'bookingId': bookingId,
          },
        ), onEstablished: () {
      safePrint('Subscription established2');
    });

    subscription2 = operation.listen(
      (event) {
        if (event.data != null) {
          Map? receiveDataNew = jsonDecode(event.data as String) ?? {};
          if (receiveDataNew != null &&
              ((receiveDataNew['subscribeBookingDetails']['bookingStatus']
                          .toString()
                          .trim() ==
                      "Booking Timeout") ||
                  (receiveDataNew['subscribeBookingDetails']['bookingStatus']
                          .toString()
                          .trim() ==
                      "CANCELLED BY CUSTOMER") ||
                  (receiveDataNew['subscribeBookingDetails']['bookingStatus']
                          .toString()
                          .trim() ==
                      "CANCELLED BY RIDER"))) {
            userDetails = "";
            initialChildSize = Rx<double>(0.1);
            maxChildSize = Rx<double>(0.1);
            snapSize = Rx<List<double>>([0.1]);
            incomingBookingModel = null;
            subscribeBookingDetailsModel = null;
            polylineCoordinates = [];
            unsubscribe2();
            update(['allPage','top']);
          } else {
            Map? receiveData = jsonDecode(event.data as String) ?? {};
            subscribeBookingDetailsModel =
                SubscribeBookingDetailsModel.fromJson(
                    receiveData as Map<String, dynamic>);
            update(['allPage','top']);
          }
        }
        safePrint('Subscription event data received2: ${event.data}');
      },
      onError: (Object e) => safePrint('Error in subscription stream: $e'),
    );
  }

  Future<void> upDateRideStatus(String? sta, {String? bookingId}) async {
    print(">>>>>>>>>>>>>>>>subscribeBookingDetailsModel" +
        (subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ?? "")
            .toString());
    MyWidgets.showLoading3();
    Map<String, dynamic> postData = {
      "bookingId": bookingId ?? "",
      "bookingStatus": sta ?? "",
      "updatedById": riderIdNew ?? "",
      "updatedByUserType": "Rider",
      "amountReceived": double.tryParse(amountEditingController.text ?? "0") ??
          0 //Pass when bookingStatus is COMPLETED
    };
    print(">>>>>>>>>>>>>>>" + (postData).toString());
    Get.find<ConnectorController>().PATCH_METHOD1_POST_TOKEN(
        api: "https://backend.eviman.co.in/api/rides/v1/update-ride-status",
        token: authToken ?? "token",
        json: postData,
        fun: (map) {
          Get.back();
          print(">>>>>>>>>>mapSta" + map.toString());
        });
  }

  Future<void> upDateRideStatusOtpVeryFy(String? sta,
      {String? bookingId}) async {
    print(">>>>>>>>>>>>>>>>subscribeBookingDetailsModel" +
        (subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ?? "")
            .toString());
    MyWidgets.showLoading3();
    Map<String, dynamic> postData = {
      "bookingId": bookingId ?? "",
      "bookingStatus": sta ?? "",
      "updatedById": riderIdNew ?? "",
      "updatedByUserType": "Rider",
      "amountReceived": double.tryParse(amountEditingController.text ?? "0") ??
          0 //Pass when bookingStatus is COMPLETED
    };
    print(">>>>>>>>>>>>>>>" + (postData).toString());
    Get.find<ConnectorController>().PATCH_METHOD1_POST_TOKEN(
        api: "https://backend.eviman.co.in/api/rides/v1/update-ride-status",
        token: authToken ?? "token",
        json: postData,
        fun: (map) {
          Get.back();
          if (map is Map &&
              map.containsKey('success') &&
              (map['success'] == "true" || map['success'] == true)) {
            otpVerifiedStatus = true;
            update(['drag']);
          } else {
            Snack.callError((map ?? "Something went wrong").toString());
          }
          print(">>>>>>>>>>mapSta" + map.toString());
        });
  }

  Future<void> upDateRideStatusComplete(String? sta,  String? amount,
      {String? bookingId}) async {
    print(">>>>>>>>>>>>>>>>subscribeBookingDetailsModel" +
        (subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ?? "")
            .toString());
    // MyWidgets.showLoading3();
    Map<String, dynamic> postData = {
      "bookingId": bookingId ?? "",
      "bookingStatus": sta ?? "",
      "updatedById": riderIdNew ?? "",
      "updatedByUserType": "Rider",
      "amountReceived": double.tryParse((amount??"0").toString() ?? "0") ?? 0 //Pass when bookingStatus is COMPLETED
    };
    print(">>>>>>>>>>>>>>>" + (postData).toString());
    Get.find<ConnectorController>().PATCH_METHOD1_POST_TOKEN(
        api: "https://backend.eviman.co.in/api/rides/v1/update-ride-status",
        token: authToken ?? "token",
        json: postData,
        fun: (map) {
          // Get.back();
          completeRide();
          print(">>>>>>>>>>mapSta" + map.toString());
        });
  }

  String userDetails = "";
  void unsubscribe() {
    if (subscription != null) {
      incomingBookingModel = null;
      subscription?.cancel();
    }
  }

  void unsubscribe2() {
    if (subscription2 != null) {
      subscribeBookingDetailsModel = null;
      subscription2?.cancel();
    }
  }

  createRide() {
    if (incomingBookingModel != null) {
      Map<String, dynamic> postData = {
        "bookingId":
            incomingBookingModel?.incomingBooking?.bookingId ?? "EVIMAN_1",
        "riderAssigned": riderIdNew ?? "41",
        "vehicleAssigned": vehicleIdNew ?? "33",
        "vehicleTypeId": incomingBookingModel?.incomingBooking?.fareInfo??"",
        "clientId": incomingBookingModel?.incomingBooking?.clientId ?? "28",
        "pickupLat":
            incomingBookingModel?.incomingBooking?.clientLat ?? "8.2522",
        "pickupLng":
            incomingBookingModel?.incomingBooking?.clientLng ?? "15.2656",
        "dropLat":
            incomingBookingModel?.incomingBooking?.destinationLat ?? "17.5455",
        "dropLng":
            incomingBookingModel?.incomingBooking?.destinationLng ?? "14.5222",
        "pickupAddress": incomingBookingModel?.incomingBooking?.pickupAddress ??
            "Angul, Odisha, India",
        "dropAddress": incomingBookingModel?.incomingBooking?.dropAddress ??
            "Bhubaneswar, Odisha"
      };
      print(">>>>>>>>>" + postData.toString());
      MyWidgets.showLoading3();
      Get.find<ConnectorController>().POSTMETHOD_TOKEN(
          api: "https://backend.eviman.co.in/api/rides/v1/create-ride",
          json: postData,
          token: authToken ?? "",
          fun: (map) {
            Get.back();
            if (map is Map &&
                map.containsKey('success') &&
                map['success'] == true) {
            } else {
              Snack.callError((map ?? "Something went wrong").toString());
            }
            print(">>>>>" + map.toString());
          });
    }
  }

  subscriptionStatus() {
    Amplify.Hub.listen(
      HubChannel.Api,
      (ApiHubEvent event) {
        if (event is SubscriptionHubEvent) {
          safePrint(event.status);
        }
      },
    );
  }

  void cancelRide() async {
    bool isOk = await showCommonPopupNew3(
        "Are you sure you want to cancel it?", "If yes, please press ok.",
        barrierDismissible: false,
        isYesOrNoPopup: true,
        filePath: "assets/json/congratulation.json");
    if (isOk) {
      userDetails = "";
      initialChildSize = Rx<double>(0.1);
      maxChildSize = Rx<double>(0.1);
      snapSize = Rx<List<double>>([0.1]);
      incomingBookingModel = null;
      polylineCoordinates = [];

      update(['drag', 'map']);
      upDateRideStatus("CANCELLED BY RIDER",
              bookingId: subscribeBookingDetailsModel
                      ?.subscribeBookingDetails?.bookingId ??
                  "")
          .then((value) {
        unsubscribe2();
      });
    }
  }

  void completeRide() async {
    bool isOk = await showCommonPopupNew3(
        "Congratulation", "You have successfully completed this ride",
        barrierDismissible: true,
        isYesOrNoPopup: false,
        filePath: "assets/json/done.json");
    if (isOk) {}
  }

  void infoDialog() async {
    bool isOk = await showCommonPopupNew3(
        "eViman App collect location(Background location) data to enable identification of nearby driver even when the app is closed or not in use",
        "No need to worry",
        barrierDismissible: true,
        isYesOrNoPopup: false,
        filePath: "assets/json/done.json");
    if (isOk) {
       goOnline(true);
    }
  }

  void infoDialog1() async {
    var status = await permission.Permission.location.status;
    var status1 = await permission.Permission.locationAlways.status;
    // var status2 = await permission.Permission.notification.status;
    print(">>>>>>>>>>>>>>status$status");
    if (status.isDenied || status.isPermanentlyDenied || status1.isDenied || status1.isPermanentlyDenied ) {
      bool isOk = await showCommonPopupNew6(
          "eViman App need your background location and notification permission(Please select allow all the time).We are redirecting to you app setting please select allow all the time.It's required to give smooth less service to you",
          "No need to worry",
          barrierDismissible: true,
          isYesOrNoPopup: true
      );
      if (isOk) {
        permission.openAppSettings();
      }
    }else{
      permission. Permission.notification.request();
      permissionAllow = true;
      getRiderId();
      getCurrentLocation();
    }
  }
  closeDialogIfOpen() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
  void completeRide1(
      {double? distance, String? amount, String? durationInMinutes}) async {
    double distanceInKilometer = (distance!) / 1000;

    bool isOk = await showCommonPopupNew5(
        "Travel Distance-${(distanceInKilometer ?? 0).toStringAsFixed(2)} K.M.\nTime Taken $durationInMinutes minutes",
        "You need to collect ₹$amount from customer",
        barrierDismissible: true,
        isYesOrNoPopup: true,
        filePath: "assets/json/done.json");
    if (isOk) {
      userDetails = "";
      initialChildSize = Rx<double>(0.1);
      maxChildSize = Rx<double>(0.1);
      snapSize = Rx<List<double>>([0.1]);
      incomingBookingModel = null;
      polylineCoordinates = [];

      update(['drag', 'map']);
      upDateRideStatusComplete("COMPLETED",
              bookingId: subscribeBookingDetailsModel
                      ?.subscribeBookingDetails?.bookingId ??
                  "",amount)
          .then((value) {
        unsubscribe2();
      });
    }
  }

  getLatLngList() {
    try {
      Get.find<ConnectorController>().GETMETHODCALL_TOKEN(
          api: "https://backend.eviman.co.in/api/rider_data/v1/get-rider-data",
          token: authToken ?? "",
          fun: (map) {
            if (map is Map &&
                map['success'] == true &&
                map.containsKey("ride") &&
                map['ride'] != null) {
              calculateDistance(jsonDecode((map['ride']['data']))['list']);
            } else {
              Snack.callError("Something went wrong");
            }
            dev.log(">>>>>>>>>>>latlngList" +
                jsonDecode((map['ride']['data']))['list'].toString());
          });
    } catch (e) {
      Snack.callError("Something went wrong");
    }
  }

  String totalDistanceNew = "0.00";
  String totalAmount = "0.00";
  String totalRides = "0.00";

  getRideAnalytics() {
    Get.find<ConnectorController>().POSTMETHOD_TOKEN(
        api: "https://backend.eviman.co.in/api/rides/v1/get-rides-analytics",
        token: authToken ?? "",
        fun: (map) {
          print(">>>>>>>>>>>rides-analytics"+map.toString());
          if(map is Map && map.containsKey("result") && map['result'] != null){
            totalDistanceNew = (map['result']['totalDistance']??"0.00").toString();
            totalAmount = (map['result']['totalAmount']??"0.00").toString();
            totalRides = (map['result']['totalRides']??"0.00").toString();
            update(['analytics','amt']);
          }else{
             totalDistanceNew = "0.00";
             totalAmount = "0.00";
             totalRides = "0.00";
             update(['analytics','amt']);
          }
        });
  }

  calculateDistance(List<dynamic> latLngList) async {
    // calculateDistanceUsingAPI
    dev.log(">>>>>>>>>>>DISTLIST" + latLngList.toString());
    MyWidgets.showLoading3();
    double totalDistance = 0;
    if (latLngList.length > 1) {
      for (int i = 0; i < (latLngList.length - 1); i++) {
        await calculateDistanceUsingAPIReturnMeter(
                originLong: latLngList[i]['longitude'],
                originLat: latLngList[i]['latitude'],
                desLat: latLngList[i + 1]['latitude'],
                desLong: latLngList[i + 1]['longitude'])
            .then((value) {
          if (value != 0) {
            print(">>>>>>>>>>>>>>>valueJKs"+value.toString());
            totalDistance = totalDistance + value;
            print(">>>>>>>>>>>>>>>valueJKs"+totalDistance.toString());
          }
        });
      }
    }
    closeDialogIfOpen();

    print(">>>>>>>>>>>>>>>>>travel distance$totalDistance");
    String? startDate =
        await SharedPreferencesKeys().getStringData(key: 'startDate');
    DateTime startDate1 = DateTime.parse(startDate!);
    DateTime endDate = DateTime.now();
    Duration duration = endDate.difference(startDate1);
    double distanceInKilometer = totalDistance / 1000;
    print(">>>>>>>>>>>>>>>>>travel distance$distanceInKilometer");
    getActualAmount(distanceInKilometer.toString(), duration.inMinutes.toString()).then((value) {
      if (value.toString().trim() != "") {
        completeRide1(
            amount: value ?? "40",
            distance: totalDistance,
            durationInMinutes: duration.inMinutes.toString());
      } else {
        Snack.callError("Something went wrong");
      }
    });
    // subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ??
  }

  Future<String> getActualAmount(String distance, String duration) {
    Completer<String> completer = Completer<String>();
    Map<String, dynamic> postData = {
      "rideBookingId":
          subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ??
              "",
      "distance": distance,
      "duration": duration
    };
    print("postData"+postData.toString());
    try {
      Get.find<ConnectorController>().POSTMETHOD_TOKEN(
          api: "https://backend.eviman.co.in/api/rides/v1/actual-fare",
          token: authToken ?? "",
          json: postData,
          fun: (map) {
            print(">>>>>>>>>>>>>>>>amountMap" + map.toString());
            if (map is Map &&
                map.containsKey("success") &&
                map['success'] == true) {
              completer.complete(map['fare'] ?? "");
            } else {
              completer.complete("");
            }
          });
    } catch (e) {
      completer.complete("");
    }

    return completer.future;
  }

  Rx<List<double>> snapSize = Rx<List<double>>([0.1, 0.2]);
  Rx<double> maxChildSize = Rx<double>(0.2);
  Rx<double> initialChildSize = Rx<double>(0.1);
  TextEditingController otpEditingController = TextEditingController();
  TextEditingController amountEditingController = TextEditingController();

  Stream<ConnectivityResult>? connectivitySubscription;
  StreamSubscription<geoLoc.Position>? positionStream;
  Connectivity connectivity = Connectivity();
  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
     advancedDrawerController = AdvancedDrawerController();
    connectivitySubscription = connectivity.onConnectivityChanged;
    // getRiderId();
    super.onInit();
  }
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    geoLoc.LocationPermission permission;


    permission = await geoLoc.Geolocator.checkPermission();
    if(permission == geoLoc.LocationPermission.always){
      return true;
    }
    if (permission == geoLoc.LocationPermission.denied || permission == geoLoc.LocationPermission.whileInUse ) {
      return false;
    }
    if (permission == geoLoc.LocationPermission.deniedForever) {
      // openAppSettings();
      // ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return false;
    }
    if(permission == geoLoc.LocationPermission.whileInUse){
      return false;
    }
    return true;
  }

  requestForNotification() async {
    await permission.Permission.notification.isDenied.then((value) {
      if(value){
        permission.Permission.notification.request();
      }
    }) ;
  }

  bool permissionAllow = false;
  askPermissions() async {
    // var sta =  permission.Permission.locationAlways;
    handleLocationPermission().then((value) async {

      if(value){
        var sta = await permission. Permission.notification.request();
        if(sta.isPermanentlyDenied || sta.isDenied){
          permissionAllow = false;
          update(['allPage']);
        }else{
          permissionAllow = true;
          // update(['allPage']);
          getRiderId();
          getCurrentLocation();
        }
      }else{
        permissionAllow = false;
        update(['allPage']);
      }
    });
  }

  @override
  void onReady() {
    // Timer.periodic(Duration(seconds: 20), (timer) { showRideAcceptDialog(Get.context!,Get.width*0.9); });
    // showModalbottomSheet();
    // getCurrentLocation();
    // infoDialog1();
    askPermissions();
    // timerController  =LinearTimerController(this);

    super.onReady();
  }

  // Add more colors as needed

  makingPhoneCall(String? number) async {
    var url = Uri.parse("tel:${number ?? 9178109443}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    // advancedDrawerController.dispose();
    mapControl = Completer<GoogleMapController>();
    positionStream?.cancel();
    // timerController?.dispose();
    unsubscribe();
    // locationUpdateTimer?.cancel();
    // locationService.stopLocationUpdates();
    super.onClose();
  }

  void increment() => count.value++;
  LocationService locationService = LocationService();
  Timer? locationUpdateTimer;

  geoc.Placemark? locationDetails;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(">>>>>>>>>>>>>>>>jks" + state.toString());
    /*if(state == AppLifecycleState.paused){
      getRiderId();
    }*/
    if (state == AppLifecycleState.detached) {
      // locationService.stopLocationUpdates();
    }
  }
}
