// ignore_for_file: prefer_const_constructors, camel_case_types

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terminal_demo/Constants/app_colors.dart';
import 'package:terminal_demo/Constants/constant.dart';
import 'package:terminal_demo/Screens/Trade/openoreder_screen.dart';
import 'package:terminal_demo/Screens/Trade/pendingoreder_screen.dart';
import '../Functions.dart';
import '../Models/CommenRequestModel.dart';
import '../Models/logindata.dart';
import '../Services/closeorder_service.dart';
import '../Services/deleteorder_service.dart';
import '../Services/openorder_service.dart';
import '../Utils/shared.dart';
import '../Widgets/custom_text.dart';
import '../Widgets/dottedline.dart';
import 'Trade/closeoreder_screen.dart';
import 'Trade/deleteoreder_screen.dart';
import 'Trade/requestoreder_screen.dart';
import 'login_screen.dart';

class Trade_Screen extends StatefulWidget {
  static const String routeName = '/trade';

  const Trade_Screen({super.key});

  @override
  State<Trade_Screen> createState() => _Trade_ScreenState();
}

class _Trade_ScreenState extends State<Trade_Screen> with SingleTickerProviderStateMixin {
  String _selectedFromDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String _selectedToDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  late TabController _tabController;
  final List<Tab> _ordTypeTabs = <Tab>[
    const Tab(
      child: CustomText(
        text: 'Open Order',
        size: 14.0,
        fontWeight: FontWeight.bold,
        textColor: AppColors.defaultColor,
        align: TextAlign.center,
      ),
      // text: "Open\n Order",
    ),
    // const Tab(
    //   child: CustomText(
    //     text: 'Pending\n Order',
    //     size: 12.0,
    //     fontWeight: FontWeight.bold,
    //     textColor: AppColors.defaultColor,
    //     align: TextAlign.center,
    //   ),
    // ),
    // const Tab(
    //   child: CustomText(
    //     text: 'Request\n Order',
    //     size: 12.0,
    //     fontWeight: FontWeight.bold,
    //     textColor: AppColors.defaultColor,
    //     align: TextAlign.center,
    //   ),
    // ),
    const Tab(
      child: CustomText(
        text: 'Close Order',
        size: 14.0,
        fontWeight: FontWeight.bold,
        textColor: AppColors.defaultColor,
        align: TextAlign.center,
      ),
    ),
    const Tab(
      child: CustomText(
        text: 'Delete Order',
        size: 14.0,
        fontWeight: FontWeight.bold,
        textColor: AppColors.defaultColor,
        align: TextAlign.center,
      ),
    )
  ];
  final Shared _shared = Shared();
  late LoginData _userData;
  final OpenorderService _openorderService = OpenorderService();
  final CloseorderService _closeorderService = CloseorderService();
  final DeleteorderService _deleteorderService = DeleteorderService();
  Accountdetails? _firstAccountDetails;
  bool _isLoading = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    checkIsLogin();
    _tabController = TabController(vsync: this, length: _ordTypeTabs.length);

    // _tabController.animateTo(Constants.tradeType == '3' || Constants.tradeType == '4' ? 1 : 0);



    // callGetOpenOrderDetailsApi();
    // callGetCloseOrderDetailsApi();
    // callGetDeleteOrderDetailsApi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isMounted = false;
    super.dispose();
    if (!mounted) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Constants.isLogin ? buildLoggedInView() : buildLoggedOutView();
  }

  Future<void> checkIsLogin() async {
    String loginData = await _shared.getLoginData();
    bool isLogin = await _shared.getIsLogin();

    setState(() {
      Constants.isLogin = isLogin;
      if (isLogin) {
        callGetOpenOrderDetailsApi();
        callGetCloseOrderDetailsApi();
        callGetDeleteOrderDetailsApi();
        // initStreamControllers();
      }
      if (loginData.isNotEmpty) {
        _userData = LoginData.getJson(json.decode(loginData));
        Constants.loginId = _userData.loginId;
        Constants.token = _userData.token;
        debugPrint('L-------O-------G-------I-------N------DATA');
      }
    });
  }

  buildLoggedInView() {
    var size = MediaQuery.of(context).size;
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 35.0,
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomText(
                  text: 'Date',
                  size: 15.0,
                  fontWeight: FontWeight.normal,
                  textColor: AppColors.textColor,
                  align: TextAlign.start,
                ),
                GestureDetector(
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Functions.calenderStyle(context),
                          child: child!,
                        );
                      },
                    ).then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          _selectedFromDate =
                              DateFormat('dd/MM/yyyy').format(selectedDate);
                          Constants.startDate = _selectedFromDate;
                          // callGetOpenOrderDetailsApi();
                          // callGetCloseOrderDetailsApi();
                          // callGetDeleteOrderDetailsApi();
                        });
                      }
                    });
                  },
                  child: Container(
                    width: size.width * 0.25,
                    height: 25.0,
                    // color: AppColors.primaryColor,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.5),
                        border: Border.all(color: AppColors.primaryColor)),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedFromDate,
                      style: const TextStyle(
                          color: AppColors.textColor, fontSize: 13.0),
                    ),
                  ),
                ),
                const CustomText(
                  text: 'To',
                  size: 15.0,
                  fontWeight: FontWeight.normal,
                  textColor: AppColors.textColor,
                  align: TextAlign.start,
                ),
                GestureDetector(
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Functions.calenderStyle(context),
                          child: child!,
                        );
                      },
                    ).then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          _selectedToDate =
                              DateFormat('dd/MM/yyyy').format(selectedDate);
                          Constants.endDate = _selectedToDate;
                          // callGetOpenOrderDetailsApi();
                          // callGetCloseOrderDetailsApi();
                          // callGetDeleteOrderDetailsApi();
                        });
                      }
                    });
                  },
                  child: Container(
                    width: size.width * 0.25,
                    height: 25.0,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.5),
                        border: Border.all(color: AppColors.primaryColor)),
                    alignment: Alignment.center,
                    child: Text(
                      _selectedToDate,
                      style: const TextStyle(
                          color: AppColors.textColor, fontSize: 13.0),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    debugPrint(
                        "startDate->$_selectedFromDate/endDate->$_selectedToDate");
                    setState(() {
                      _isLoading = true;
                    });
                    callGetOpenOrderDetailsApi();
                    callGetCloseOrderDetailsApi();
                    callGetDeleteOrderDetailsApi();
                  },
                  child: Container(
                    height: 25.0,
                    width: size.width * 0.25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    child: Stack(
                      children: [
                        Visibility(
                          visible: !_isLoading,
                          child: CustomText(
                            text: 'Search',
                            size: 15.0,
                            fontWeight: FontWeight.bold,
                            textColor: AppColors.defaultColor,
                            align: TextAlign.start,
                          ),
                        ),
                        Visibility(
                          visible: _isLoading,
                          child: SizedBox(
                            height: 20.0,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.defaultColor,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.primaryColor,
            thickness: 1,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomText(
                      text: 'Balance:',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                    Expanded(
                        child: DottedLine(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.center,
                      lineLength: double.infinity,
                      lineThickness: 1.0,
                      dashColor: AppColors.hintColor,
                      dashRadius: 0.0,
                      dashGapLength: 4.0,
                      dashGapRadius: 2.0,
                    )),
                    CustomText(
                      text: _firstAccountDetails != null
                          // ? NumberFormat('#,##,000').format(firstAccountDetails!.balance!).toString()
                          ? Functions.formatNum(_firstAccountDetails!.balance!)
                          : '0',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                  ],
                ),
                SizedBox(
                  height: size.height * .01,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomText(
                      text: 'Used Margin:',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                    Expanded(
                        child: DottedLine(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.center,
                      lineLength: double.infinity,
                      lineThickness: 1.0,
                      dashColor: AppColors.hintColor,
                      dashRadius: 0.0,
                      dashGapLength: 4.0,
                      dashGapRadius: 2.0,
                    )

                        // CustomPaint(
                        //   painter: DashedLineVerticalPainter(),
                        // ),
                        ),
                    CustomText(
                      text: _firstAccountDetails != null
                          ? Functions.formatNum(
                              _firstAccountDetails!.usedMargin!)
                          : '0',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                  ],
                ),
                SizedBox(
                  height: size.height * .01,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomText(
                      text: 'Free Margin:',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                    Expanded(
                        child: DottedLine(
                      direction: Axis.horizontal,
                      alignment: WrapAlignment.center,
                      lineLength: double.infinity,
                      lineThickness: 1.0,
                      dashColor: AppColors.hintColor,
                      dashRadius: 0.0,
                      dashGapLength: 4.0,
                      dashGapRadius: 2.0,
                    )

                        // CustomPaint(
                        //   painter: DashedLineVerticalPainter(),
                        // ),
                        ),
                    CustomText(
                      text: _firstAccountDetails != null
                          ? Functions.formatNum(
                              _firstAccountDetails!.freeMargin!)
                          : '0',
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                      textColor: AppColors.textColor,
                      align: TextAlign.start,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: size.height * .01,
          ),
          Container(
            height: size.height / 15,
            width: size.width,
            decoration: const BoxDecoration(color: AppColors.primaryColor),
            child: TabBar(
              // onTap: (index) {
              //   setState(() {
              //     // getOrdersStatusFromIndex(index);
              //     currIndex = index;
              //   });
              //   debugPrint(index.toString());
              // },
              controller: _tabController,
              isScrollable: false,
              indicatorColor: AppColors.defaultColor,
              tabs: _ordTypeTabs,
            ),
          ),
          SizedBox(
            height: size.height * .01,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              // physics: NeverScrollableScrollPhysics(),
              // children: _pages,
              children: [
                OpenOrder_Screen(),
                // PendingOrder_Screen(openOrder: callGetOpenOrderDetailsApi),
                // RequestOrder_Screen(),
                CloseOrder_Screen(),
                DeleteOrder_Screen()
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildLoggedOutView() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Navigator.of(context)
          //     .pushNamed(Login_Screen.routeName,
          //         arguments: const Login_Screen(
          //           isFromSplash: false,
          //         ))
          //     .then((_) {
          //   checkIsLogin();
          // });
        },
        child: const Center(
          child: CustomText(
              text: 'Please Login',
              size: 18,
              fontWeight: FontWeight.bold,
              textColor: AppColors.textColor),
        ),
      ),
    );
  }

  void callGetOpenOrderDetailsApi() {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        var objVariable = openOrderReqToJson(OpenOrderRequest(
            loginid: _userData.loginId,
            firmname: Constants.projectName,
            clientId: int.parse(Constants.clientId),
            fromdate: _selectedFromDate,
            todate: _selectedToDate));
        _openorderService.openOrdObj(objVariable, context).then((response) {
          if (response.data != null) {
            List<dynamic> accountDetailsList = jsonDecode(response.data!);
            List<Accountdetails> accountDetails = accountDetailsList
                .map((item) => Accountdetails.fromJson(item))
                .toList();
            if (_isMounted) {
              setState(() {
                _isLoading = false;
                _firstAccountDetails =
                    accountDetails.isNotEmpty ? accountDetails[0] : null;
              });
            }
            // setState(() {
            //   isLoading = false;
            //   firstAccountDetails =
            //       accountDetails.isNotEmpty ? accountDetails[0] : null;
            // });
            debugPrint('ACC-------DETAIL------List--${accountDetails.length}');
          } else {
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // setState(() {
            //   isLoading = false;
            // });
            Functions.showToast(Constants.noData);
          }
        });
      } else {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // setState(() {
        //   isLoading = false;
        // });
        Functions.showToast(Constants.noInternet);
      }
    });
  }

  void callGetCloseOrderDetailsApi() {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        var objVariable = openOrderReqToJson(OpenOrderRequest(
            loginid: _userData.loginId,
            firmname: Constants.projectName,
            clientId: int.parse(Constants.clientId),
            fromdate: _selectedFromDate,
            todate: _selectedToDate));
        _closeorderService.closeOrdObj(objVariable, context).then((response) {
          if (response.data != null) {
            // List<dynamic> accountDetailsList = jsonDecode(response.data!);
            // List<Accountdetails> accountDetails = accountDetailsList
            //     .map((item) => Accountdetails.fromJson(item))
            //     .toList();
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
            }

            debugPrint(response.data);
          } else {
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
            }
            Functions.showToast(Constants.noData);
          }
        });
      } else {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Functions.showToast(Constants.noInternet);
      }
    });
  }

  void callGetDeleteOrderDetailsApi() {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        var objVariable = openOrderReqToJson(OpenOrderRequest(
            loginid: _userData.loginId,
            firmname: Constants.projectName,
            clientId: int.parse(Constants.clientId),
            fromdate: _selectedFromDate,
            todate: _selectedToDate));
        _deleteorderService.delOrdObj(objVariable, context).then((response) {
          if (response.data != null) {
            // List<dynamic> accountDetailsList = jsonDecode(response.data!);
            // List<Accountdetails> accountDetails = accountDetailsList
            //     .map((item) => Accountdetails.fromJson(item))
            //     .toList();
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
            }
            debugPrint(response.data);
          } else {
            if (_isMounted) {
              setState(() {
                _isLoading = false;
              });
            }
            Functions.showToast(Constants.noData);
          }
        });
      } else {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Functions.showToast(Constants.noInternet);
      }
    });
  }
}
