part of 'driver_dashboard_controller.dart';

extension HelperController on DriverDashboardController {
  goOnline(bool val) {
    Map sendData = {
      "status": (val) ? 1 : 0,
    };
    print(">>>>>update-online-status" + sendData.toString());
    Get.find<ConnectorController>().PATCH_METHOD_TOKEN(
        api: "http://65.1.169.159:3000/api/riders/v1/update-online-status/" +
            riderIdNew.toString(),
        json: sendData,
        token: authToken ?? "",
        fun: (map) {
          print(">>>>>>" + map.toString());
          if (map is Map &&
              map.containsKey("success") &&
              map['success'] == true) {
            if (isDisappear.value == true) {
              callOrStopServices().then((value) {
                userDetails = "";
                incomingBookingModel = null;
                unsubscribe();
                unsubscribe2();
              });
              isDisappear = Rx<bool>(false);
              userDetails = "";
              initialChildSize = Rx<double>(0.1);
              maxChildSize = Rx<double>(0.1);
              snapSize = Rx<List<double>>([0.1]);
              incomingBookingModel = null;
              polylineCoordinates = [];
              isDisappear.refresh();
              update(['top']);
              // stopBackgroundService();
            } else {
              // callBackgroundService();
              calBackgroundServices("true");
              userDetails = "";
              subscribeIncomingBooking();
              isDisappear = Rx<bool>(true);
              isDisappear.refresh();
              userDetails = "";
              initialChildSize = Rx<double>(0.1);
              maxChildSize = Rx<double>(0.1);
              snapSize = Rx<List<double>>([0.1]);
              incomingBookingModel = null;
              polylineCoordinates = [];
              update(['top']);
            }
          } else {}
        });
  }

  showModalbottomSheet() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
              child: Container(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 02.0, vertical: 0),
                        child: Container(
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        AssetImage("assets/images/avatar1.jpg"),
                                    maxRadius: 30,
                                    minRadius: 10,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  CustomeTittleText(
                                    text: "Amrit Jena",
                                    textsize: 18,
                                  ),
                                ],
                              ),
                              Image.asset(
                                "assets/icon/noti_gif2.gif",
                                height: 70,
                                width: 70,
                                colorBlendMode: BlendMode.color,
                                color: Colors.red,
                                filterQuality: FilterQuality.high,
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 08.0, vertical: 0),
                        child: Column(
                          children: [
                            Text("Pick Up"),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.location_searching_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Lagos-Abeokuta Expressway KM 748",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 9),
                        height: 8,
                        width: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 9),
                        height: 8,
                        width: 2,
                        color: Colors.black,
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: Color(0xffADD685),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            "Queen Street 73",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CommonButton(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, bottom: 1),
                              buttonText: "Ignore",
                              onTap: () {},
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 2,
                            child: CommonButton(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, bottom: 1),
                              buttonText: "Accept",
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void showRideAcceptDialog(BuildContext context, double screenSizeWidth,
      {String? pickUpDistance,
      String? travelDistance,
      String? pickupAddress,
      String? dropAddress,
      Map? receiveData}) {
    Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          content: Stack(children: [
            Container(
              height: Get.height * 0.44,
              width: screenSizeWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color(0xff16192C),
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 1,
                        blurRadius: 1,
                        color: Colors.grey.shade300)
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "There’s a new trip around you",
                    style: TextStyles(context)
                        .getBoldStyle()
                        .copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_searching_rounded,
                        size: 20,
                        color: Colors.red,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Container(
                        width: Get.width * 0.7,
                        child: Text(
                          pickupAddress ?? "Lagos-Abeokuta Expressway KM 748",
                          style: TextStyles(context)
                              .getBoldStyle()
                              .copyWith(color: Colors.white, fontSize: 14),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 9),
                    height: 8,
                    width: 2,
                    color: Colors.white,
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 9),
                    height: 8,
                    width: 2,
                    color: Colors.white,
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: Color(0xffADD685),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Container(
                        width: Get.width * 0.7,
                        child: Text(
                          dropAddress ?? "Queen Street 73",
                          style: TextStyles(context)
                              .getBoldStyle()
                              .copyWith(color: Colors.white, fontSize: 14),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    child: const Icon(
                                      Icons.map,
                                      color: Color(0xffA6B7D4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      pickUpDistance ?? "32Km",
                                      style: TextStyles(context)
                                          .getBoldStyle()
                                          .copyWith(
                                              color: Colors.white,
                                              fontSize: 28),
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    "PickUp distance",
                                    style: TextStyles(context)
                                        .getDescriptionStyle()
                                        .copyWith(fontSize: 12),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Container(
                          height: 60,
                          width: 2,
                          color: Color(0xffA6B7D4),
                        ),
                        SizedBox(
                          height: 70,
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 10),
                                    child: const Icon(
                                      Icons.map,
                                      color: Color(0xffA6B7D4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    child: Text(
                                      travelDistance ?? "32Km",
                                      style: TextStyles(context)
                                          .getBoldStyle()
                                          .copyWith(
                                              color: Colors.white,
                                              fontSize: 28),
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    "Traveled distance",
                                    style: TextStyles(context)
                                        .getDescriptionStyle()
                                        .copyWith(fontSize: 12),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CommonButton(
                          padding: const EdgeInsets.only(
                              left: 2, right: 2, bottom: 4),
                          buttonText: "Cancel",
                          backgroundColor: Colors.red,
                          onTap: () {
                            userDetails = "";
                            maxChildSize = Rx<double>(0.2);
                            snapSize = Rx<List<double>>([0.1, 0.2]);
                            pickUpDistance = null;
                            pickUpDistance = null;
                            maxChildSize = Rx<double>(0.2);
                            initialChildSize = Rx<double>(0.1);
                            snapSize = Rx<List<double>>([0.1, 0.2]);
                            update(['drag']);
                            unsubscribe2();
                            snapSize.refresh();
                            maxChildSize.refresh();
                            Get.back();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: CommonButton(
                          padding: const EdgeInsets.only(
                              left: 2, right: 2, bottom: 4),
                          buttonText: "Accept",
                          onTap: () {
                            // userDetails = "";
                            print(">>>>>>>>>>" + receiveData.toString());
                            if (receiveData != null) {
                              try {
                                maxChildSize = Rx<double>(0.7);
                                initialChildSize = Rx<double>(0.5);
                                snapSize = Rx<List<double>>(
                                    [0.1, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.6]);
                                pickUpDist = pickUpDistance;
                                travelDist = travelDistance;
                                snapSize.refresh();
                                maxChildSize.refresh();
                                initialChildSize.refresh();
                                incomingBookingModel =
                                    IncomingBooikingModel.fromJson(
                                        (receiveData ?? {})
                                            as Map<String, dynamic>);
                                update(['drag']);
                                print(">>>>>>>>>>" +
                                    (incomingBookingModel?.toJson())
                                        .toString());
                                subscribeBookingDetails(incomingBookingModel
                                    ?.incomingBooking?.bookingId);
                                createRide();
                                sourceLocation = LatLng(
                                    double.tryParse(incomingBookingModel
                                                ?.incomingBooking?.clientLat ??
                                            "20.288187") ??
                                        20.288187,
                                    double.tryParse(incomingBookingModel
                                                ?.incomingBooking?.clientLng ??
                                            "85.817814") ??
                                        85.817814);
                                destination = LatLng(
                                    double.tryParse(incomingBookingModel
                                                ?.incomingBooking
                                                ?.destinationLat ??
                                            "20.288187") ??
                                        20.290983,
                                    double.tryParse(incomingBookingModel
                                                ?.incomingBooking
                                                ?.destinationLng ??
                                            "85.817814") ??
                                        85.845584);
                                getPolyPoints();
                                setCustomMarkerIcon();
                                Get.back();
                              } catch (e) {
                                userDetails = "";
                                maxChildSize = Rx<double>(0.2);
                                snapSize = Rx<List<double>>([0.1, 0.2]);
                                pickUpDistance = null;
                                pickUpDistance = null;
                                maxChildSize = Rx<double>(0.2);
                                initialChildSize = Rx<double>(0.1);
                                snapSize = Rx<List<double>>([0.1, 0.2]);
                                update(['drag']);
                                unsubscribe2();
                                snapSize.refresh();
                                maxChildSize.refresh();
                                Get.back();
                              }

                              // fetchDirections();
                            }
                            else{
                              Get.back();
                            }


                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
                top: 10,
                right: 6,
                left: 266,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        userDetails = "";
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ))
          ]),
          backgroundColor: const Color(0xff16192C),
          insetPadding: EdgeInsets.all(2),
          contentPadding: EdgeInsets.all(0),
        ));
  }

  void openGoogleMaps(
      {double latitude = 20.382649, double longitude = 86.367002}) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  void otpDialog(BuildContext context, double screenSizeWidth) {
    Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          content: Stack(children: [
            Container(
              height: Get.height * 0.24,
              width: screenSizeWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 1,
                        blurRadius: 1,
                        color: Colors.grey.shade300)
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                      "Otp: ${subscribeBookingDetailsModel?.subscribeBookingDetails?.otp ?? ""}"),
                  PinFieldAutoFill(
                    textInputAction: TextInputAction.done,
                    codeLength: 4,
                    controller: otpEditingController,
                    decoration: UnderlineDecoration(
                      textStyle:
                          const TextStyle(fontSize: 16, color: Colors.blue),
                      colorBuilder: const FixedColorBuilder(
                        Colors.transparent,
                      ),
                      bgColorBuilder: FixedColorBuilder(
                        Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    // currentCode: controllerX.messageOtpCode.value,
                    onCodeSubmitted: (code) {
                      print("onCodeSubmitted $code");
                    },
                    onCodeChanged: (code) {
                      // controllerX.messageOtpCode.value = code??"000000";
                      // controller.countdownController.pause();
                      if (code?.length == 4) {
                        // controllerX.verifyOtp(code ??"000000");
                        // To perform some operation
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: CommonButton(
                          padding: const EdgeInsets.only(
                              left: 22, right: 22, bottom: 4),
                          buttonText: "Verify OTP",
                          backgroundColor: Colors.red,
                          height: 33,
                          onTap: () {
                            // userDetails = "";
                            if (subscribeBookingDetailsModel != null) {
                              if (subscribeBookingDetailsModel
                                      ?.subscribeBookingDetails?.otp
                                      .toString()
                                      .trim() ==
                                  otpEditingController.text.toString().trim()) {
                                upDateRideStatus("OTP VERIFIED");
                                Get.back();
                              } else {
                                Snack.callError("Please enter a valid otp");
                              }
                            } else {
                              Snack.callError("Something went wrong");
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
                right: 0,
                left: 266,
                top: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // userDetails = "";
                        print(">>>>>>>>>>>>>>backPressed");
                        Get.back();
                      },
                    ),
                  ),
                ))
          ]),
          backgroundColor: const Color(0xff16192C),
          insetPadding: EdgeInsets.all(2),
          contentPadding: EdgeInsets.all(0),
        ));
  }

  void goToMapDialog(BuildContext context, double screenSizeWidth) {
    Get.dialog(
        barrierDismissible: false,
        AlertDialog(
          content: Stack(children: [
            Container(
              height: Get.height * 0.24,
              width: screenSizeWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 1,
                        blurRadius: 1,
                        color: Colors.grey.shade300)
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: CommonButton(
                      padding: const EdgeInsets.only(
                          left: 4, right: 4, bottom: 10, top: 10),
                      buttonText: "Move To Pick Up Address",
                      backgroundColor: Colors.red,
                      height: 25,
                      isIcon: true,
                      onTap: () {
                        Get.back();
                        openGoogleMaps(
                            latitude: double.tryParse(incomingBookingModel
                                        ?.incomingBooking?.clientLat ??
                                    "0") ??
                                0,
                            longitude: double.tryParse(incomingBookingModel
                                        ?.incomingBooking?.clientLng ??
                                    "0") ??
                                0);
                      },
                    ),
                  ),
                  Expanded(
                    child: CommonButton(
                      padding: const EdgeInsets.only(
                          left: 4, right: 4, bottom: 10, top: 10),
                      buttonText: "Move to Travel Address",
                      backgroundColor: Colors.red,
                      height: 25,
                      isIcon: true,
                      onTap: () {
                        // userDetails = "";
                        Get.back();
                        openGoogleMaps(
                            latitude: double.tryParse(incomingBookingModel
                                        ?.incomingBooking?.destinationLat ??
                                    "0") ??
                                0,
                            longitude: double.tryParse(incomingBookingModel
                                        ?.incomingBooking?.destinationLng ??
                                    "0") ??
                                0);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
                right: 0,
                left: 266,
                top: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.transparent),
                  child: Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        // userDetails = "";
                        print(">>>>>>>>>>>>>>backPressed");
                        Get.back();
                      },
                    ),
                  ),
                ))
          ]),
          backgroundColor: const Color(0xff16192C),
          insetPadding: EdgeInsets.all(2),
          contentPadding: EdgeInsets.all(0),
        ));
  }

  double getHeight(BoxConstraints constraints) {
    if (isDisappear.value) {
      mapHeight = (constraints.maxHeight / 10) * 9;
    } else {
      mapHeight = (constraints.maxHeight);
    }
    // update(['map']);
    return mapHeight;
  }

  callServices() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
    /* else{
      service.startService();
      FlutterBackgroundService().invoke("setAsForeground");
      Future.delayed(const Duration(seconds: 7));
      FlutterBackgroundService().invoke("setAsBackground");
    }*/
  }

  Future<void> callOrStopServices() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke("stopService");
      }
      return;
    } catch (e) {
      print(">>>>>>\n\n" + e.toString());
      return;
    }
  }

  Future<void> calBackgroundServices(String? sta) async {
    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (isRunning == false) {
        service.startService();
        // FlutterBackgroundService().invoke("setAsForeground");
      }
      // FlutterBackgroundService().invoke("isForeGround",{"sta":sta??"true"});
      return;
    } catch (e) {
      print(">>>>>>>>>>>error JKs\n\n" + e.toString());
      return;
    }
  }

  void gotoSplashScreen() async {
    bool isOk = await showCommonPopupNew(
      "Are you sure?",
      "You want to Sign Out.",
      Get.context!,
      barrierDismissible: true,
      isYesOrNoPopup: true,
    );
    if (isOk) {
      await SharedPreferencesKeys().setStringData(key: "authToken", text: "");
      await SharedPreferencesKeys()
          .setStringData(key: "isLogin", text: "false");
      await SharedPreferencesKeys().setStringData(key: "riderId", text: "");
      callOrStopServices().then((value) {
        Get.delete<LoginscreenController>();
        Get.delete<DriverDashboardController>();
        Get.offAndToNamed(Routes.LOGINSCREEN);
      });

      // ignore: use_build_context_synchronously
    }
  }

  void handleMenuButtonPressed() {
    // NOTICE: Manage Advanced Drawer state through the Controller.
    // _advancedDrawerController.value = AdvancedDrawerValue.visible();
    advancedDrawerController.showDrawer();
  }
}
