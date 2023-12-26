// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:stylish_bottom_bar/model/bar_items.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
import 'package:terminal_demo/Screens/bankdetails_screen.dart';
import 'package:terminal_demo/Screens/contactus_screen.dart';
import 'package:terminal_demo/Screens/liverate_screen.dart';
import 'package:terminal_demo/Screens/login_screen.dart';
import 'package:terminal_demo/Screens/profile_screen.dart';
import 'package:terminal_demo/Screens/trade_screen.dart';
import 'package:terminal_demo/Screens/update_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Constants/app_colors.dart';
import '../Constants/constant.dart';
import '../Constants/images.dart';
import '../Constants/notify_socket_update.dart';
import '../Functions.dart';
import '../Models/CommenRequestModel.dart';
import '../Models/client_header.dart';
import '../Models/logindata.dart';
import '../Popup/alert_confirm_popup.dart';
import '../Providers/liverate_provider.dart';
import '../Routes/page_route.dart';
import '../Services/notification_service.dart';
import '../Services/openorder_service.dart';
import '../Services/socket_service.dart';
import '../Utils/shared.dart';
import '../Widgets/custom_text.dart';
import 'coin_screen.dart';
import 'economiccalender_scree.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = PageRoutes.homescreen;

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  late Future<String> permissionStatusFuture;
  var permGranted = "granted";
  var permDenied = "denied";
  var permUnknown = "unknown";
  var permProvisional = "provisional";
  int selectedIndex = 0;
  double left = 10;
  double bottom1 = 100;
  double right = 10;
  double bottom2 = 100;
  late LiverateProvider _liverateProvider;
  ClientHeaderData clientHeaderData = ClientHeaderData();
  bool isBannerVisible = false;
  bool isInternetConnected = false;
  bool isAddVisible = true;
  List<Widget> widgetsList = [
    const LiveRateScreen(),
    const Trade_Screen(),
    const Update_Screen(),
    const BankDetail_Screen(),
    const ContactUs_Screen(),
    // const Coin_Screen(),
  ];
  DateTime? currentBackPressTime;
  DateTime now = DateTime.now();

  List<String> booking = [];
  bool isLoading = false;
  bool isDiscoveredOverlay = false;
  Shared shared = Shared();
  OpenorderService openorderService = OpenorderService();
  late LoginData userData;
  late NotificationService notificationService;
  late ProfileDetails accountDetails;
  int tapCount = 0;
  int lastTap = 0;

  // int consecutiveTaps = 0;
  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void checkIsLogin() async {
    String loginData = await shared.getLoginData();
    shared.getIsLogin().then((loginStatus) {
      setState(() {
        Constants.isLogin = loginStatus;
      });
    });
    if (loginData.isNotEmpty) {
      userData = LoginData.getJson(json.decode(loginData));
      Constants.loginId = userData.loginId;
      Constants.token = userData.token;
      // debugPrint('L-------O-------G-------I-------N------DATA');
    }
  }

  @override
  void initState() {
    super.initState();
    notificationService = NotificationService();
    permissionStatusFuture = getCheckNotificationPermStatus();

    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    // checkDiscovered();
    notificationService.initializePlatformNotifications();
    _liverateProvider = Provider.of<LiverateProvider>(context, listen: false);

    NotificationPermissions.requestNotificationPermissions(
            iosSettings: const NotificationSettingsIos(
                sound: true, badge: true, alert: true))
        .then((_) {
      // when finished, check the permission status
      setState(() {
        permissionStatusFuture = getCheckNotificationPermStatus();
      });
    });

    loadLiveData();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('${message.data}');
      debugPrint('${message.senderId}');
      if (message.data['bit'] == '1') {
        showNotificationAlertDialog(
          message.data['title'],
          message.data['body'],
          message.data['bit'],
        );
      }

      if (!Platform.isIOS) {
        NotificationService().showLocalNotification(
            body: message.data['title'],
            title: message.data['body'],
            payload: 'Hello');
      }
    });
    // listenToNotificationStream();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      debugPrint('Opened');
      if (message != null) {
        if (message.data['bit'] == '1') {
          onItemTapped(2);
        } else {
          onItemTapped(0);
        }
      }
    });
//on open notification while in kill mode
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        if (message.data['bit'] == '1') {
          onItemTapped(2);
        } else {
          onItemTapped(0);
        }
      }
    });
    checkIsLogin();

    // callGetOpenOrderDetailsApi();
    initStreamControllers();
    initConnectivityListener();
  }

  void initStreamControllers() {
    NotifySocketUpdate.controllerHome = StreamController.broadcast();
    NotifySocketUpdate.controllerOrderDetails = StreamController.broadcast();
    NotifySocketUpdate.controllerAccountDetails = StreamController();
    // NotifySocketUpdate.controllerAccountDetails!.stream
    //     .asBroadcastStream()
    //     .listen(
    //   (event) {
    //     loadProfileData();
    //   },
    // );
    NotifySocketUpdate.controllerHome!.stream.listen((event) {
      loadLiveData();
    });
    NotifySocketUpdate.controllerOrderDetails!.stream.listen((event) {
      setState(() {
        onItemTapped(1);
      });
    });
  }

  void initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((connection) {
      if (connection == ConnectivityResult.none) {
        setState(() {
          isInternetConnected = false;
        });
      } else {
        setState(() {
          isInternetConnected = true;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<String> getCheckNotificationPermStatus() {
    return NotificationPermissions.getNotificationPermissionStatus()
        .then((status) {
      switch (status) {
        case PermissionStatus.denied:
          return permDenied;
        case PermissionStatus.granted:
          return permGranted;
        case PermissionStatus.unknown:
          return permUnknown;
        case PermissionStatus.provisional:
          return permProvisional;
        default:
          return permUnknown;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        debugPrint('appLifeCycleState inactive');
        break;
      case AppLifecycleState.resumed:
        debugPrint('appLifeCycleState resumed');
        setState(() {
          permissionStatusFuture = getCheckNotificationPermStatus();
        });
        // handleResumedState();
        break;
      case AppLifecycleState.paused:
        debugPrint('appLifeCycleState paused');
        break;
      case AppLifecycleState.detached:
        // shared.setisAddBannerVisible(false);
        // bool isAddVisible
        debugPrint('appLifeCycleState detached');
        break;
      // case AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  loadLiveData() async {
    setState(() {
      clientHeaderData = _liverateProvider.getClientHeaderData();
    });

    _liverateProvider.bannerImage!.isNotEmpty
        ? isAddVisible
            ? setState(() {
                isBannerVisible = true;
                isAddVisible = false;
              })
            : null
        : setState(() {
            isAddVisible = true;
          });
    if (clientHeaderData.bookingNo1 != null &&
        clientHeaderData.bookingNo1!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo1!);
    }
    if (clientHeaderData.bookingNo2 != null &&
        clientHeaderData.bookingNo2!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo2!);
    }
    if (clientHeaderData.bookingNo3 != null &&
        clientHeaderData.bookingNo3!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo3!);
    }
    if (clientHeaderData.bookingNo4 != null &&
        clientHeaderData.bookingNo4!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo4!);
    }
    if (clientHeaderData.bookingNo5 != null &&
        clientHeaderData.bookingNo5!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo5!);
    }
    if (clientHeaderData.bookingNo6 != null &&
        clientHeaderData.bookingNo6!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo6!);
    }
    if (clientHeaderData.bookingNo7 != null &&
        clientHeaderData.bookingNo7!.trim().isNotEmpty) {
      booking.add(clientHeaderData.bookingNo7!);
    }
  }

  @override
  void dispose() {
    NotifySocketUpdate.controllerHome!.close();
    NotifySocketUpdate.controllerOrderDetails!.close();
    NotifySocketUpdate.controllerAccountDetails!.close();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: [
        Scaffold(
          onDrawerChanged: (isOpened) {
            checkIsLogin();
          },
          key: _scaffoldKey,
          backgroundColor: AppColors.defaultColor,
          appBar: AppBar(
            // systemOverlayStyle:
            //     SystemUiOverlayStyle(statusBarColor: AppColors.primaryColor),
            backgroundColor: AppColors.defaultColor,
            automaticallyImplyLeading: false,
            toolbarHeight: 60,
            elevation: 0.0,
            iconTheme: const IconThemeData(color: AppColors.primaryColor),
            title: GestureDetector(
              onTap: () {
                if (!Constants.isLogin) {
                  handleTap();
                } else {
                  Functions.showToast('Yoy Are Already Login.');
                }
              },
              child: Image.asset(
                AppImagePath.headerLogo,
                scale: 7.5,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
              icon: const Icon(
                Icons.menu,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          drawer: buildAppDrawer(),
          body: Container(
            color: AppColors.bgColor,
            // decoration: BoxDecoration(
            //   // color:
            //   image: DecorationImage(
            //     image: AssetImage(AppImagePath.bg),
            //     fit: BoxFit.cover,
            //   ),
            // ),
            child: buildBody(size),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: selectedIndex,
            height: 60,
            backgroundColor: AppColors.defaultColor,
            animationCurve: Curves.fastEaseInToSlowEaseOut,
            items: <Widget>[
              Icon(
                Icons.home,
                size: 24,
                color: selectedIndex == 0
                    ? AppColors.primaryColor
                    : AppColors.textColor,
              ),
              Icon(Icons.area_chart,
                  size: 24,
                  color: selectedIndex == 1
                      ? AppColors.primaryColor
                      : AppColors.textColor),
              Icon(Icons.notification_add_sharp,
                  size: 24,
                  color: selectedIndex == 2
                      ? AppColors.primaryColor
                      : AppColors.textColor),
              Icon(Icons.home_work,
                  size: 24,
                  color: selectedIndex == 3
                      ? AppColors.primaryColor
                      : AppColors.textColor),
              Icon(Icons.contact_phone,
                  size: 24,
                  color: selectedIndex == 4
                      ? AppColors.primaryColor
                      : AppColors.textColor),
            ],
            onTap: (index) {
              onItemTapped(index);
            },
          ),
        ),
        Visibility(
          visible: isBannerVisible,
          child: Container(
            color: AppColors.textColor.withOpacity(.7),
            child: Center(
              child: Stack(
                // mainAxisSize: MainAxisSize.max,
                alignment: Alignment.center,
                children: <Widget>[
                  Center(
                    child: Image.network(
                      _liverateProvider.bannerImage!,
                      height: size.height * .7,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: size.width * .6,
                        margin: const EdgeInsets.only(bottom: .01),
                        child: ElevatedButton(
                          child: const Text(
                            textScaleFactor: 1.0,
                            "SKIP",
                            style: TextStyle(fontSize: 16),
                          ),
                          onPressed: () {
                            setState(() {
                              isBannerVisible = false;
                              isAddVisible = false;
                              // shared.setisAddBannerVisible(false);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: left,
          bottom: bottom1,
          child: GestureDetector(
            onTap: () {
              showCallDialog();
            },
            onPanUpdate: (dragDetails) {
              setState(() {
                left += dragDetails.delta.dx;
                bottom1 -= dragDetails.delta.dy;
              });
            },
            child: Container(
              // heroTag: 'call1',
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: const Icon(
                Icons.call,
                color: AppColors.defaultColor,
                size: 30.0,
              ),
            ),
          ),
        ),
        Positioned(
          right: right,
          bottom: bottom2,
          child: GestureDetector(
            onTap: () {
              openWhatsapp();
            },
            onPanUpdate: (dragDetails) {
              setState(() {
                right -= dragDetails.delta.dx;
                bottom2 -= dragDetails.delta.dy;
              });
            },
            child: Container(
              // heroTag: 'call1',
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: Image.asset(
                AppImagePath.whatsapp,
                scale: 2,
              ),
            ),
          ),

          // DescribedFeatureOverlay(
          //   featureId: 'feature3',
          //   targetColor: AppColors.defaultColor,
          //   textColor: AppColors.defaultColor,
          //   backgroundColor: const Color(0xFF141414).withOpacity(0.4),
          //   contentLocation: ContentLocation.below,
          //   title: const CustomText(
          //     text: 'WhatsApp chat',
          //     size: 20.0,
          //     fontWeight: FontWeight.bold,
          //     textColor: AppColors.defaultColor,
          //   ),
          //   pulseDuration: const Duration(seconds: 1),
          //   enablePulsingAnimation: true,
          //   barrierDismissible: false,
          //   onComplete: () async {
          //     debugPrint('Tapped tap target of.');
          //     return true;
          //   },
          //   onOpen: () async {
          //     debugPrint('Tab here to open WhatsApp chat.');
          //     shared.setIsDiscoverd(true);
          //     return isDiscoveredOverlay;
          //   },
          //   overflowMode: OverflowMode.extendBackground,
          //   openDuration: const Duration(seconds: 1),
          //   description: const Text('Tab here to open WhatsApp chat.'),
          //   tapTarget: const Image(
          //     image: AssetImage(AppImagePath.whatsapp),
          //   ),
          //   child:
          //   GestureDetector(
          //     onTap: () {
          //       openWhatsapp();
          //     },
          //     onPanUpdate: (dragDetails) {
          //       setState(() {
          //         right -= dragDetails.delta.dx;
          //         bottom2 -= dragDetails.delta.dy;
          //       });
          //     },
          //     child: Container(
          //       // heroTag: 'call1',
          //       padding: const EdgeInsets.all(10.0),
          //       decoration: const BoxDecoration(
          //         shape: BoxShape.circle,
          //         color: AppColors.textColor,
          //       ),
          //       child: Image.asset(
          //         AppImagePath.whatsapp,
          //         scale: 2,
          //       ),
          //     ),
          //   ),
          // ),
        ),
      ],
    );
  }

  buildAppDrawer() {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      bottom: false,
      child: Drawer(
        backgroundColor: AppColors.defaultColor,
        child: Column(
          children: [
            Container(
              height: 120.0,
              color: AppColors.defaultColor,
              alignment: Alignment.center,
              child: const Center(
                child: Image(
                  image: AssetImage(AppImagePath.drawerLogo),
                  height: 120.0,
                  width: 120.0,
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Visibility(
              visible: Constants.isLogin ? true : false,
              child: CustomText(
                text: Constants.isLogin && Constants.loginName.isNotEmpty
                    ? Constants.loginName
                    : '',
                textColor: AppColors.primaryColor,
                size: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(
              // height: 10.0,
              color: AppColors.primaryColor,
              thickness: .8,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: selectedIndex == 0
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                          Navigator.of(context).pop();
                        },
                        leading: Icon(
                          Icons.home,
                          color: selectedIndex == 0
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),

                        // SvgPicture.asset(
                        //   AppImagePath.liveImage,
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Live Rate',
                          style: TextStyle(
                            color: selectedIndex == 0
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: selectedIndex == 1
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedIndex = 1;
                          });
                          Navigator.of(context).pop();
                        },
                        leading: Icon(
                          Icons.area_chart,
                          color: selectedIndex == 1
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),

                        // SvgPicture.asset(
                        //   AppImagePath.liveImage,
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Trade',
                          style: TextStyle(
                            color: selectedIndex == 1
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: selectedIndex == 2
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedIndex = 2;
                          });
                          Navigator.of(context).pop();
                        },
                        leading: Icon(
                          Icons.notification_add_sharp,
                          color: selectedIndex == 2
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),

                        // SvgPicture.asset(
                        //   AppImagePath.updateImage,
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Updates',
                          style: TextStyle(
                            color: selectedIndex == 2
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: selectedIndex == 3
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedIndex = 3;
                          });
                          Navigator.of(context).pop();
                        },
                        leading: Icon(
                          Icons.home_work,
                          color: selectedIndex == 3
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),
                        // SvgPicture.asset(
                        //   AppImagePath.bankImage,
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Bank Detail',
                          style: TextStyle(
                            color: selectedIndex == 3
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: selectedIndex == 4
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            selectedIndex = 4;
                          });
                          Navigator.of(context).pop();
                        },
                        leading: Icon(
                          Icons.contact_phone,
                          color: selectedIndex == 4
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),
                        // SvgPicture.asset(
                        //   AppImagePath.contactImage,
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Contact Us',
                          style: TextStyle(
                            color: selectedIndex == 4
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: selectedIndex == 5
                          ? AppColors.primaryColor
                          : AppColors.defaultColor,
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pushNamed(EconomicCalenderScreen.routeName);
                        },
                        leading: Icon(
                          Icons.calendar_month_sharp,
                          color: selectedIndex == 5
                              ? AppColors.defaultColor
                              : AppColors.primaryColor,
                          size: 24,
                        ),
                        // const Image(
                        //   image: AssetImage(AppImagePath.economicImage),
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: Text(
                          textScaleFactor: 1.0,
                          'Economic Calendar',
                          style: TextStyle(
                            color: selectedIndex == 5
                                ? AppColors.defaultColor
                                : AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: Constants.isLogin,
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .pushNamed(ProfileScreen.routeName);
                        },
                        leading: Icon(
                          Icons.file_copy_sharp,
                          color: AppColors.primaryColor,
                          size: 24,
                        ),
                        title: const Text(
                          textScaleFactor: 1.0,
                          'Profile',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () async {
                        Platform.isIOS
                            ? Share.share(Constants.iOSAppRedirect)
                            : Share.share(Constants.androidAppStoreRedirect);
                      },
                      leading: Icon(
                        Icons.share_sharp,
                        color: AppColors.primaryColor

                        /*selectedIndex == 5
            
                      ? AppColors.primaryColor
                      : AppColors.primaryColor*/
                        ,
                        size: 24,
                      ),
                      // const Image(
                      //   image: AssetImage(AppImagePath.economicImage),
                      //   height: 24,
                      //   width: 24,
                      //   color: AppColors.primaryColor,
                      // ),
                      title: const Text(
                        textScaleFactor: 1.0,
                        'Share',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    ListTile(
                      onTap: () {
                        StoreRedirect.redirect(
                          androidAppId: Constants.androidAppRateAndUpdate,
                          iOSAppId: Constants.iOSAppId,
                        );
                        Navigator.of(context).pop();
                      },
                      leading: Icon(
                        Icons.star_rate_rounded,
                        color: AppColors.primaryColor

                        /*selectedIndex == 5
            
                      ? AppColors.primaryColor
                      : AppColors.primaryColor*/
                        ,
                        size: 24,
                      ),
                      // const Image(
                      //   image: AssetImage(AppImagePath.economicImage),
                      //   height: 24,
                      //   width: 24,
                      //   color: AppColors.primaryColor,
                      // ),
                      title: const Text(
                        textScaleFactor: 1.0,
                        'Rate App',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: Constants.isLogin,
                      child: ListTile(
                        onTap: () {
                          openLogoutPopup();
                          // Dialog_Utils.showConfirmDialog(context,
                          //     title: 'Mahalaxmi Bullion',
                          //     content: 'Are you sure you want to logout?',
                          //     okBtnText: 'Logout',
                          //     cancelBtnText: 'Cancel',
                          //     okBtnFunctionConfirm: shared.clear);
                        },
                        leading: Icon(
                          Icons.logout,
                          color: AppColors.primaryColor

                          /*selectedIndex == 5
            
                        ? AppColors.primaryColor
                        : AppColors.primaryColor*/
                          ,
                          size: 24,
                        ),
                        // const Image(
                        //   image: AssetImage(AppImagePath.economicImage),
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: const Text(
                          textScaleFactor: 1.0,
                          'Logout',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: false,
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            Login_Screen.routeName,
                            arguments: const Login_Screen(
                              isFromSplash: false,
                            ),
                          );
                        },
                        leading: Icon(
                          Icons.login,
                          color: AppColors.primaryColor

                          /*selectedIndex == 5
            
                        ? AppColors.primaryColor
                        : AppColors.primaryColor*/
                          ,
                          size: 24,
                        ),
                        // const Image(
                        //   image: AssetImage(AppImagePath.economicImage),
                        //   height: 24,
                        //   width: 24,
                        //   color: AppColors.primaryColor,
                        // ),
                        title: const Text(
                          textScaleFactor: 1.0,
                          'Login',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  openLogoutPopup() {
    return DialogUtil.showConfirmDialog(context,
        title: Constants.alertAndCnfTitle,
        content: 'Are you sure you want to logout?',
        okBtnText: 'Logout',
        cancelBtnText: 'Cancel',
        okBtnFunctionConfirm: onLogout,
        isVisible: false);
  }

  onLogout() {
    shared.clear();
    if (selectedIndex == 0) {
      Constants.isLogin = false;
      Navigator.of(context).pop();
    }
    setState(() {
      onItemTapped(0);
      Navigator.of(context).pop();
    });
  }

  buildBody(Size size) {
    return WillPopScope(
      onWillPop: () {
        DialogUtil.showConfirmDialog(context,
            title: Constants.alertAndCnfTitle,
            content: 'Are you sure you want to exit app?',
            okBtnText: 'Exit',
            cancelBtnText: 'Cancel',
            okBtnFunctionConfirm: onExit,
            isVisible: false);
        return Future.value(false);
      },
      child: Column(
        children: [
          Visibility(
            visible: !isInternetConnected,
            child: Container(
              width: size.width,
              decoration: const BoxDecoration(
                color: AppColors.red,
              ),
              padding: const EdgeInsets.all(3.0),
              margin: const EdgeInsets.only(bottom: 2.0),
              alignment: Alignment.center,
              child: const CustomText(
                text: 'Please Check Internet Connection.',
                textColor: AppColors.defaultColor,
                size: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Visibility(
            visible: clientHeaderData.marquee != null &&
                clientHeaderData.marquee!.isNotEmpty,
            child: Container(
              height: 20.0,
              color: AppColors.primaryColor,
              child: Marquee(
                textScaleFactor: 1.0,
                text: clientHeaderData.marquee == null
                    ? 'No Marquee Found'
                    : clientHeaderData.marquee!,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryTextColor),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 400.0,
                velocity: 50.0,
                pauseAfterRound: const Duration(milliseconds: 10),
                startPadding: 10.0,
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ),
          widgetsList.elementAt(selectedIndex),
          Visibility(
            visible: clientHeaderData.marquee2 != null &&
                clientHeaderData.marquee2!.isNotEmpty,
            child: Container(
              height: 20.0,
              color: AppColors.primaryColor,
              child: Marquee(
                textScaleFactor: 1.0,
                text: clientHeaderData.marquee != null
                    ? clientHeaderData.marquee2!
                    : 'No Marquee Found',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryTextColor),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 400.0,
                velocity: 50.0,
                pauseAfterRound: const Duration(milliseconds: 10),
                startPadding: 10.0,
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> callGetOpenOrderDetailsApi() async {
    String loginData = await shared.getLoginData();
    shared.getIsLogin().then(
      (loginStatus) {
        if (loginStatus) {
          setState(() {
            userData = LoginData.getJson(json.decode(loginData));
            Constants.loginId = userData.loginId;
            Constants.token = userData.token;
            if (loginData.isNotEmpty) {
              userData = LoginData.getJson(json.decode(loginData));
              Constants.loginId = userData.loginId;
              Constants.token = userData.token;
              Functions.checkConnectivity().then((isConnected) {
                if (isConnected) {
                  var objVariable = openOrderReqToJson(OpenOrderRequest(
                      loginid: userData.loginId,
                      firmname: Constants.projectName,
                      clientId: int.parse(Constants.clientId),
                      fromdate: Constants.startDate,
                      todate: Constants.endDate));
                  openorderService
                      .openOrdObj(objVariable, context)
                      .then((response) {
                    if (response.data != null) {
                      // List<dynamic> accountDetailsList = jsonDecode(response.data!);
                      // List<Accountdetails> accountDetails = accountDetailsList
                      //     .map((item) => Accountdetails.fromJson(item))
                      //     .toList();
                      // setState(() {
                      //   isLoading = false;
                      //   firstAccountDetails =
                      //   accountDetails.isNotEmpty ? accountDetails[0] : null;
                      // });
                      // debugPrint('ACC-------DETAIL------List--${accountDetails.length}');
                    } else {
                      // setState(() {
                      //   isLoading = false;
                      // });
                      // Functions.showToast(Constants.noData);
                    }
                  });
                } else {
                  // setState(() {
                  //   isLoading = false;
                  // });
                  // Functions.showToast(Constants.noInternet);
                }
              });
              // debugPrint('L-------O-------G-------I-------N------DATA');
            }
          });
        }
      },
    );
  }

  showNotificationAlertDialog(String title, String body, String bit) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        var size = MediaQuery.of(context).size;
        return
            //   AlertDialog(
            //   title:
            //   Row(
            //     // crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Image(
            //         image: AssetImage(AppImagePath.header_logo),
            //         height: 50.0,
            //         width: 50.0,
            //       ),
            //       Expanded(
            //         child: Text(
            //           title,
            //           style: const TextStyle(
            //             color: AppColors.primaryColor,
            //             fontSize: 18.0,
            //             fontWeight: FontWeight.bold,
            //           ),
            //           textAlign: TextAlign.start,
            //           overflow: TextOverflow.clip,
            //         ),
            //       ),
            //     ],
            //   ),
            //   content: CustomText(
            //     text: body,
            //     textColor: AppColors.textColor,
            //     size: 16.0,
            //     fontWeight: FontWeight.normal,
            //     align: TextAlign.start,
            //   ),
            //   actions: [
            //     Center(
            //       child: ElevatedButton(
            //         style: ButtonStyle(
            //           backgroundColor:
            //           MaterialStateProperty.all(AppColors.primaryColor),
            //         ),
            //         onPressed: () {
            //           // Navigator.of(context).pop();
            //           onNotificationClick(bit);
            //         },
            //         child: const CustomText(
            //           text: 'Okay',
            //           textColor: AppColors.defaultColor,
            //           size: 14.0,
            //           fontWeight: FontWeight.normal,
            //         ),
            //       ),
            //     ),
            //   ],
            // );
            Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0)), //this right here
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryColor),
              // color: AppColors.primaryColor,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: size.width * 0.15,
                  width: size.width,
                  // decoration:  BoxDecoration(
                  //     border: Border.all(color: AppColors.primaryColor),
                  //   // color: AppColors.primaryColor,
                  //   // borderRadius: BorderRadius.only(
                  //   //     topLeft: Radius.circular(10),
                  //   //     topRight: Radius.circular(10)),
                  // ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Image(
                      image: AssetImage(AppImagePath.headerLogo),
                      // height: 50.0,
                      // width: 50.0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Divider(
                    thickness: 1,
                    color: AppColors.primaryColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(title,
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                          color: AppColors.primaryColor)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(body,
                      textScaleFactor: 1.0,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15.0,
                          color: AppColors.textColor)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    child: Container(
                      height: size.width * 0.11,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      alignment: Alignment.center,
                      child: Text('Ok',
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                              color: AppColors.defaultColor)),
                    ),
                    onTap: () {
                      onNotificationClick(bit);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  onNotificationClick(String bit) {
    if (bit == '1') {
      onItemTapped(2);
    } else {
      onItemTapped(0);
    }
    Navigator.of(context).pop();
  }

  showCallDialog() {
    showDialog(
      context: context,
      builder: (builder) {
        return AlertDialog(
          actions: [
            Visibility(
              visible: (clientHeaderData.bookingNo1 == null ||
                          clientHeaderData.bookingNo1!.isEmpty) &&
                      (clientHeaderData.bookingNo2 == null ||
                          clientHeaderData.bookingNo2!.isEmpty) &&
                      (clientHeaderData.bookingNo3 == null ||
                          clientHeaderData.bookingNo3!.isEmpty) &&
                      (clientHeaderData.bookingNo4 == null ||
                          clientHeaderData.bookingNo4!.isEmpty) &&
                      (clientHeaderData.bookingNo5 == null ||
                          clientHeaderData.bookingNo5!.isEmpty) &&
                      (clientHeaderData.bookingNo6 == null ||
                          clientHeaderData.bookingNo6!.isEmpty) &&
                      (clientHeaderData.bookingNo7 == null ||
                          clientHeaderData.bookingNo7!.isEmpty)
                  ? false
                  : true,
              child: Container(
                width: MediaQuery.of(context).size.width * 100,
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.0),
                  border: Border.all(
                    color: AppColors.primaryColor,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 100,
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50.0),
                              border: Border.all(color: Colors.transparent),
                              gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primaryColor,
                                    AppColors.primaryColor,
                                  ],
                                  begin: FractionalOffset(0.0, 1.0),
                                  end: FractionalOffset(1.0, 0.0),
                                  stops: [0.0, 2.0],
                                  tileMode: TileMode.clamp),
                            ),
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.all(10),
                            child: Column(
                              children: const <Widget>[
                                Icon(
                                  Icons.mobile_screen_share,
                                  color: AppColors.defaultColor,
                                  size: 30.0,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            width: MediaQuery.of(context).size.width * 100,
                            child: const Text(
                              textScaleFactor: 1.0,
                              "BOOKING NUMBER",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo1 == null ||
                                    clientHeaderData.bookingNo1!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: '' /*liveData.bookingNo1*/),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo1!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo2 == null ||
                                    clientHeaderData.bookingNo2!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo2),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo2!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo3 == null ||
                                    clientHeaderData.bookingNo3!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo3),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo3!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo4 == null ||
                                    clientHeaderData.bookingNo4!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo4),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo4!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo5 == null ||
                                    clientHeaderData.bookingNo5!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo5),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo5!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo6 == null ||
                                    clientHeaderData.bookingNo6!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo6),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo6!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: clientHeaderData.bookingNo7 == null ||
                                    clientHeaderData.bookingNo7!.isEmpty
                                ? false
                                : true,
                            child: GestureDetector(
                              onTap: () {
                                launchUrl(
                                  Uri(
                                      scheme: 'tel',
                                      path: clientHeaderData.bookingNo7),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                width: MediaQuery.of(context).size.width * 100,
                                child: Text(
                                  textScaleFactor: 1.0,
                                  clientHeaderData.bookingNo7!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> openWhatsapp() async {
    var whatsapp = "+91${clientHeaderData.whatsappNo1}";
    var whatsappUrlAndroid = "whatsapp://send?phone=$whatsapp&text=''";
    // var whatsappUrlIOS = "https://wa.me/$whatsapp?text=''}";
    var whatsappUrlIOS = "whatsapp://wa.me/$whatsapp/?text=";
    var urlIOS = Uri.parse(whatsappUrlIOS);
    var urlAndroid = Uri.parse(whatsappUrlAndroid);
    if (Platform.isIOS) {
      launchUrl(urlIOS).then((isLaunched) {
        if (isLaunched) {
          // Functions.showToast('Whatsapp Launched');
        } else {
          Functions.showToast('Whatsapp not Installed');
        }
      }).catchError(
        (exception) {
          Functions.showToast('Whatsapp not Found');
        },
      );
    }

    if (Platform.isAndroid) {
      launchUrl(urlAndroid).then((isLaunched) {
        if (isLaunched) {
          // Functions.showToast('Whatsapp Launched');
        } else {
          Functions.showToast('Whatsapp not Installed');
        }
      }).catchError((exception) {
        Functions.showToast('Whatsapp not Found');
      });
    }
  }

  void handleResumedState() async {
    try {
      await SocketService.getLiveRateData(context);
    } catch (error) {
      debugPrint('Error in getLiveRateData: $error');
    }
  }

  checkDiscovered() {
    shared.getIsDiscoverd().then((isDiscovered) {
      if (!isDiscovered) {
        isDiscoveredOverlay = true;
      } else {
        isDiscoveredOverlay = false;
      }
    });
  }

  void loadProfileData() {
    setState(() {
      accountDetails = _liverateProvider.getAccountData();
    });
  }

  onExit() {
    return exit(0);
  }

  void handleTap() {
    const int tripleClickDuration = 800; // Adjust as needed
    int now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastTap < tripleClickDuration) {
      tapCount++;
    } else {
      tapCount = 1;
    }

    if (tapCount == 3) {
      // Perform the task when triple click occurs
      Navigator.of(context)
          .pushNamed(
        Login_Screen.routeName,
        arguments: const Login_Screen(
          isFromSplash: false,
        ),
      )
          .then((_) {
        checkIsLogin();
      });
      print("Triple click!");
      // Reset tap count after performing the task
      tapCount = 0;
    }

    lastTap = now;
  }
}
