import 'dart:async';
import 'dart:convert';

import 'dart:math';
import 'dart:ui';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:dateplan/app/routes/app_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_polyline_points_plus/flutter_polyline_points_plus.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:location/location.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

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
import '../CheckStatusModel.dart';
import '../IncomingBooikingModel.dart';
import '../IncomingBooking.dart';
import 'package:amplify_core/src/types/api/graphql/graphql_response.dart' as gr;

import '../LocationService.dart';
import '../SubscribeBookingDetailsModel.dart';
import 'AmplifyApiName.dart';
import 'package:geocoding/geocoding.dart' as geoc;
import 'package:http/http.dart' as http;
part 'mapcontroller.dart';
part 'appsyncController.dart';
part 'helpercontroller.dart';

class DriverDashboardController extends GetxController
    with Helper, WidgetsBindingObserver {
  //TODO: Implement DriverDashboardController
  final advancedDrawerController = AdvancedDrawerController();
  final count = 0.obs;
  LatLng sourceLocation = LatLng(20.288187, 85.817814);
  LatLng destination = LatLng(20.290983, 85.845584);

  Completer<GoogleMapController> mapControl = Completer<GoogleMapController>();
  List<LatLng> polylineCoordinates = [];
  GoogleMapController? mapController;

  LatLng? currentLocation;

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
  CheckStatusModel ?checkStatusModel;

  checkStatus(){
    MyWidgets.showLoading3();
    Get.find<ConnectorController>().GETMETHODCALL(
        api: "http://65.1.169.159:3000/api/riders/v1/online-status/${riderIdNew??""}",
        fun: (map) {
          print(">>>>>>>>>>>>>online-status"+map.toString());
          Get.back();
          if (map != null && map is Map &&
              map.containsKey('success') &&
              map['success'] == true) {
            checkStatusModel = CheckStatusModel.fromJson(map as Map<String,dynamic>);
            if(checkStatusModel != null && checkStatusModel?.riderStatus != null &&
                checkStatusModel?.riderStatus?.activeRide != null){
              if(checkStatusModel?.riderStatus?.activeRide?.rideStatus.toString().trim() == "CONFIRMED" ||
                  checkStatusModel?.riderStatus?.activeRide?.rideStatus.toString().trim() == "OTP VERIFIED"
              ){
                incomingBookingModel = IncomingBooikingModel(incomingBooking:  IncomingBooking(
                  bookingId:checkStatusModel?.riderStatus?.activeRide?.bookingId??"",
                  clientLat:checkStatusModel?.riderStatus?.activeRide?.pickupLat??"",
                  clientLng:checkStatusModel?.riderStatus?.activeRide?.pickupLng??"",
                  destinationLng:checkStatusModel?.riderStatus?.activeRide?.dropLng??"",
                  destinationLat:checkStatusModel?.riderStatus?.activeRide?.dropLat??"",
                  dropAddress:checkStatusModel?.riderStatus?.activeRide?.dropAddress??"",
                  pickupAddress:checkStatusModel?.riderStatus?.activeRide?.pickupAddress??"",
                  clientId: checkStatusModel?.riderStatus?.activeRide?.clientId??0,
                  // clientName: "",
                  clientName: checkStatusModel?.riderStatus?.activeRide?.clientName??"JKS",
                  clientPhone:checkStatusModel?.riderStatus?.clientPhone??"",
                  fareInfo: checkStatusModel?.riderStatus?.activeRide?.fareInfo??0,
                  status:  checkStatusModel?.riderStatus?.activeRide?.rideStatus??"",
                  rider: int.tryParse(checkStatusModel?.riderStatus?.activeRide?.riderAssigned??"0"),
                ) );
                subscribeBookingDetailsModel = SubscribeBookingDetailsModel(
                    subscribeBookingDetails:SubscribeBookingDetails(
                        bookingId:checkStatusModel?.riderStatus?.activeRide?.bookingId??"",
                        bookingStatus: checkStatusModel?.riderStatus?.activeRide?.rideStatus??"",
                      otp: checkStatusModel?.riderStatus?.activeRide?.otp??0000,
                      riderId: int.tryParse(checkStatusModel?.riderStatus?.activeRide?.riderAssigned??"0"),
                      updatedById: int.tryParse(riderIdNew??"0") ,
                      vehicleId: int.tryParse(vehicleIdNew??"0"),
                    ) );
                travelDist = checkStatusModel?.riderStatus?.activeRide?.distance??"0";
                maxChildSize = Rx<double>(0.7);
                initialChildSize = Rx<double>(0.5);
                snapSize = Rx<List<double>>([0.1, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.6]);
                getPolyPoints();
                setCustomMarkerIcon();
                update(['top']);
              }

            }
            if(checkStatusModel != null &&  checkStatusModel?.riderStatus?.isOnline != null){
              if(checkStatusModel?.riderStatus?.isOnline??false ){
                isDisappear = Rx<bool>(true);
                calBackgroundServices("true");
                subscribeIncomingBooking();
              }else{
                isDisappear = Rx<bool>(false);
                callOrStopServices();
              }
            }
            update(['top']);

          } else {
            Snack.callError((map ?? "Something went wrong").toString());
          }
        });
  }

  getRiderId() async {
    riderIdNew = await SharedPreferencesKeys().getStringData(key: 'riderId');
    vehicleIdNew =
        await SharedPreferencesKeys().getStringData(key: 'vehicleId');
    authToken = await SharedPreferencesKeys().getStringData(key: 'authToken');
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
          if (userDetails == "") {
            Map? receiveDataNew = jsonDecode(event.data as String) ?? {};
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
                "Pleas be ready for trips",
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
            } else {
              Snack.callSuccess("Please take action quick");
            }
          } else {
            Snack.callSuccess("Please take action quick");
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
          if(receiveDataNew != null && receiveDataNew['subscribeBookingDetails']['bookingStatus'].toString().trim() == "Booking Timeout"){
            userDetails = "";
            initialChildSize = Rx<double>(0.1);
            maxChildSize = Rx<double>(0.1);
            snapSize = Rx<List<double>>([0.1]);
            incomingBookingModel = null;
            subscribeBookingDetailsModel = null;
            polylineCoordinates = [];
            update(['top']);
          }else{
            Map? receiveData = jsonDecode(event.data as String) ?? {};
            subscribeBookingDetailsModel = SubscribeBookingDetailsModel.fromJson(
                receiveData as Map<String, dynamic>);
          }
        }
        safePrint('Subscription event data received2: ${event.data}');
      },
      onError: (Object e) => safePrint('Error in subscription stream: $e'),
    );
  }

  upDateRideStatus(String? sta) {
    MyWidgets.showLoading3();
    Map<String, dynamic> postData = {
      "bookingId":
      subscribeBookingDetailsModel?.subscribeBookingDetails?.bookingId ?? "EVIMAN_1",
      "bookingStatus": sta ?? "COMPLETED",
      "updatedById": riderIdNew ?? "41",
      "updatedByUserType": "Rider",
      "amountReceived": 950 //Pass when bookingStatus is COMPLETED
    };
    print(">>>>>>>>>>>>>>>" + jsonEncode(postData).toString());
    Get.find<ConnectorController>().PATCH_METHOD1_POST_TOKEN(
        api: "http://65.1.169.159:3000/api/rides/v1/update-ride-status",
        token: authToken ?? "token",
        json: postData,
        fun: (map) {
          Get.back();
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
        "vehicleTypeId": "1",
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
          api: "http://65.1.169.159:3000/api/rides/v1/create-ride",
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

  Rx<List<double>> snapSize = Rx<List<double>>([0.1, 0.2]);
  Rx<double> maxChildSize = Rx<double>(0.2);
  Rx<double> initialChildSize = Rx<double>(0.1);
  TextEditingController otpEditingController = TextEditingController();
  TextEditingController amountEditingController = TextEditingController();
  @override
  void onInit() {
    WidgetsBinding.instance.addObserver(this);
    // getRiderId();
    super.onInit();
  }

  @override
  void onReady() {
    // Timer.periodic(Duration(seconds: 20), (timer) { showRideAcceptDialog(Get.context!,Get.width*0.9); });
    // showModalbottomSheet();
    getCurrentLocation();
    getRiderId();

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
