// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../Constants/app_colors.dart';
import '../Constants/constant.dart';
import '../Constants/images.dart';
import '../Constants/notify_socket_update.dart';
import '../Functions.dart';
import '../Models/CommenRequestModel.dart';
import '../Models/client_header.dart';
import '../Models/comex_data_model.dart';
import '../Models/liverate.dart';
import '../Models/logindata.dart';
import '../Models/reference_data.dart';
import '../Models/reference_data_rate.dart';
import '../Popup/alert_confirm_popup.dart';
import '../Providers/liverate_provider.dart';
import '../Services/insertopenorder_service.dart';
import '../Utils/shared.dart';
import '../Widgets/custom_text.dart';
import 'login_screen.dart';

class LiveRateScreen extends StatefulWidget {
  static const String routeName = '/live-rate';

  const LiveRateScreen({super.key});

  @override
  State<LiveRateScreen> createState() => _LiveRateScreenState();
}

class _LiveRateScreenState extends State<LiveRateScreen>
    with TickerProviderStateMixin {
  late LiverateProvider _liverateProvider;
  late TabController _tabController;
  late TabController _tabGoldSilverController;

  // Boolean flags
  bool isHighVisible = false;
  bool isLowVisible = false;
  bool isBuyVisible = true;
  bool isSellVisible = true;
  bool isRateVisible = true;
  bool isDiffVisible = true;
  bool isSellLoading = false;
  bool isBuyLoading = false;
  bool isSellPremiumRateDiffVisible = false;
  bool isReferenceContainerVisible = false;
  bool isMarketSelected = true;
  bool isGoldSelected = true;
  bool afterLoginView = true;
  late bool isBuySellSelected;
  bool isLogin = false;

  // Text controller
  final TextEditingController _priceController = TextEditingController();

  // Lists and other variables
  late List<Liverate> liveRatesDetailMaster=[];
  late List<Liverate> liveRatesDetailGold;
  late List<Liverate> liveRatesDetailSilver;
  late List<ReferenceDataRate> liveRateReferenceDetail;
  List<ReferenceData> referenceData = [];
  List<ReferenceDataRate> rateReferenceData = [];
  List<ComexDataModel> referenceComexData = [];
  List<ComexDataModel> referenceComexDataGold = [];
  List<ComexDataModel> referenceComexDataSilver = [];
  List<ComexDataModel> referenceFutureData = [];
  List<ComexDataModel> referenceInrData = [];
  late List<Liverate> liveRatesDetailOldMaster;
  late List<ReferenceDataRate> liveRateReferenceDetailOld;
  List<ComexDataModel> referenceComexDataOld = [];
  List<ComexDataModel> referenceFutureDataOld = [];
  List<ComexDataModel> referenceComexDataOldChange = [];
  List<ComexDataModel> referenceFutureDataOldChange = [];
  List<Liverate> liveRatesDetailOldChange = [];
  List<ReferenceDataRate> liveRateReferenceDetailOldChange = [];

  String bid = '';
  String ask = '';
  String high = '';
  String low = '';
  String quantity = '';
  List<String> items = [];
  ClientHeaderData clientHeadersDetail = ClientHeaderData();
  Shared shared = Shared();
  var streamController;
  List<GroupDetailsDropDown> dropDown = [];
  var oneClick, inTotal, step;
  String gmkg = '';
  InsertOpenOrderService insertOpenOrderService = InsertOpenOrderService();
  late LoginData userData;

  clearFields() {
    _priceController.clear();
  }

  @override
  void initState() {
    super.initState();

    _initializeControllers();
    _liverateProvider = Provider.of<LiverateProvider>(context, listen: false);
    checkIsLogin();
    loadData();
    dropDown = _liverateProvider.getDropDownData();
    _initializeListeners();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 1, vsync: this);
    _tabGoldSilverController = TabController(length: 2, vsync: this);
    NotifySocketUpdate.controllerHome = StreamController();
    NotifySocketUpdate.controllerMainData = StreamController();
    NotifySocketUpdate.dropDown = StreamController();
    streamController = StreamController<List<Liverate>>.broadcast();
  }

  void _initializeListeners() {
    NotifySocketUpdate.controllerHome!.stream.asBroadcastStream().listen(
      (event) {
        liveRateReferenceDetail=[];
        referenceData = _liverateProvider.getReferenceData();
        // for (var item in event) {
        //   liveRateReferenceDetail.add(ReferenceDataRate.fromJson(item));
        // }

        liveRateReferenceDetail = _liverateProvider.getReferenceDataRate();
        liveRateReferenceDetailOld = liveRateReferenceDetail;

        Functions.checkConnectivity().then((isConnected) {
          List<ComexDataModel> comexData = [];
          List<ComexDataModel> futureData = [];
          List<ComexDataModel> nextData = [];
          if (isConnected) {
            setState(() {
              referenceFutureData = _liverateProvider.getFutureData();
              referenceComexData = _liverateProvider.getComexData();

              // referenceNextData = liveDataProvider.getNextData();
            });
            // Set Future and Next list based on Liverates and Reference
            for (var data in referenceData) {
              for (var rate in liveRateReferenceDetail) {
                if (rate.symbol.toLowerCase() == data.source!.toLowerCase()) {
                  bid  = rate.bid.toString();
                  ask  = rate.ask.toString();
                  high = rate.high.toString();
                  low  = rate.low.toString();
                } // Set bid, ask, high and low which matches the symbol of rate and source of data.
              }
              if (data.isDisplay! &&
                  (data.source == 'gold' || data.source == 'silver')) {
                futureData.add(
                  ComexDataModel(
                    symbolName: data.symbolName,
                    bid: bid.toString(),
                    ask: ask.toString(),
                    high: high.toString(),
                    low: low.toString(),
                    isDisplay: data.isDisplay,
                  ),
                );
              }
              else if(data.isDisplay! &&
                  (data.source == 'XAGUSD' ||
                      data.source == 'XAUUSD' ||
                      data.source == 'INRSpot')){
                comexData.add(
                  ComexDataModel(
                    symbolName: data.symbolName,
                    bid: bid.toString(),
                    ask: ask.toString(),
                    high: high.toString(),
                    low: low.toString(),
                    isDisplay: data.isDisplay,
                  ),
                );
              }
            }
            _liverateProvider.addFutureData(futureData);

            _liverateProvider.addComexData(comexData);

            // Set Comex list based on Liverates and Reference
            // for (var data in referenceData) {
            //   for (var rate in liveRateReferenceDetail) {
            //     if (rate.symbol.toLowerCase() == data.source!.toLowerCase()) {
            //       bid = rate.bid.toString();
            //       ask = rate.ask.toString();
            //       high = rate.high.toString();
            //       low = rate.low.toString();
            //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
            //   }
            //   if (data.isDisplay! &&
            //       (data.source == 'XAGUSD' ||
            //           data.source == 'XAUUSD' ||
            //           data.source == 'INRSpot')) {
            //     comexData.add(
            //       ComexDataModel(
            //         symbolName: data.symbolName,
            //         bid: bid.toString(),
            //         ask: ask.toString(),
            //         high: high.toString(),
            //         low: low.toString(),
            //         isDisplay: data.isDisplay,
            //       ),
            //     );
            //   }
            // }
            // _liverateProvider.addComexData(comexData);

            // Set Next list based on Liverates and Reference
            // for (var data in referenceData) {
            //   for (var rate in liveRateReferenceDetail) {
            //     if (rate.symbol.toLowerCase() == data.source!.toLowerCase()) {
            //       bid = rate.bid;
            //       ask = rate.ask;
            //       high = rate.high;
            //       low = rate.low;
            //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
            //   }
            //   if (data.isDisplay! &&
            //       (data.source == 'goldnext' || data.source == 'silvernext')) {
            //     nextData.add(
            //       ComexDataModel(
            //         symbolName: data.symbolName,
            //         bid: bid,
            //         ask: ask,
            //         high: high,
            //         low: low,
            //         isDisplay: data.isDisplay,
            //       ),
            //     );
            //   }
            // }
            // _liverateProvider.addNextData(nextData);

          } else {
            setState(() {
              referenceFutureData = _liverateProvider.getFutureData();
              referenceComexData = _liverateProvider.getComexData();

              // referenceNextData = liveDataProvider.getNextData();
            });
          }


          // if (isConnected) {
          //   setState(() {
          //     referenceFutureData = _liverateProvider.getFutureData();
          //     // referenceComexDataGold = [];
          //     // referenceComexDataSilver = [];
          //     referenceComexData = _liverateProvider.getComexData();
          //
          //
          //   });
          //   for (var data in referenceData) {
          //     var rate = liveRateReferenceDetail.firstWhere((rate) =>
          //         rate.symbol!.toLowerCase() == data.source!.toLowerCase());
          //
          //     if (rate != null) {
          //       var bid = rate.bid!.toString();
          //       var ask = rate.ask!.toString();
          //       var high = rate.high!.toString();
          //       var low = rate.low!.toString();
          //
          //       var comexModel = ComexDataModel(
          //         symbolName: data.symbolName,
          //         bid: bid,
          //         ask: ask,
          //         high: high,
          //         low: low,
          //         source: data.source,
          //         isDisplay: data.isDisplay,
          //       );
          //
          //       if (data.isDisplay! &&
          //           (data.source == 'XAUUSD' ||
          //               data.source == 'XAGUSD' ||
          //               data.source == 'INRSpot')) {
          //         comexData.add(comexModel);
          //       }
          //
          //       if (data.isDisplay! &&
          //           (data.source == 'gold' ||
          //               data.source == 'silver' ||
          //               data.source == 'silvernext' ||
          //               data.source == 'goldnext')) {
          //         futureData.add(comexModel);
          //       }
          //     }
          //   }
          //
          //   _liverateProvider.addComexData(comexData);
          //   _liverateProvider.addFutureData(futureData);
          //   // for (var data in referenceData) {
          //   //   for (var rate in liveRateReferenceDetail) {
          //   //     if (rate.symbol!.toLowerCase() == data.source!.toLowerCase()) {
          //   //       bid = rate.bid!.toString();
          //   //       ask = rate.ask!.toString();
          //   //       high = rate.high!.toString();
          //   //       low = rate.low!.toString();
          //   //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
          //   //   }
          //   //
          //   //   if (data.isDisplay! &&
          //   //       (data.source == 'XAUUSD' ||
          //   //           data.source == 'XAGUSD' ||
          //   //           // data.source == 'gold' ||
          //   //           // data.source == 'silver' ||
          //   //           // data.source == 'silvernext' ||
          //   //           // data.source == 'goldnext' ||
          //   //           data.source == 'INRSpot')) {
          //   //     comexData.add(
          //   //       ComexDataModel(
          //   //         symbolName: data.symbolName,
          //   //         bid: bid,
          //   //         ask: ask,
          //   //         high: high,
          //   //         low: low,
          //   //         source: data.source,
          //   //         isDisplay: data.isDisplay,
          //   //       ),
          //   //     );
          //   //   }
          //   // }
          //   // _liverateProvider.addComexData(comexData);
          //   // for (var data in referenceData) {
          //   //   for (var rate in liveRateReferenceDetail) {
          //   //     if (rate.symbol!.toLowerCase() == data.source!.toLowerCase()) {
          //   //       bid = rate.bid!.toString();
          //   //       ask = rate.ask!.toString();
          //   //       high = rate.high!.toString();
          //   //       low = rate.low!.toString();
          //   //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
          //   //   }
          //   //   if (data.isDisplay! &&
          //   //       (data.source == 'gold' ||
          //   //           data.source == 'silver' ||
          //   //           data.source == 'silvernext' ||
          //   //           data.source == 'goldnext')) {
          //   //     futureData.add(
          //   //       ComexDataModel(
          //   //         symbolName: data.symbolName,
          //   //         bid: bid,
          //   //         ask: ask,
          //   //         high: high,
          //   //         low: low,
          //   //         isDisplay: data.isDisplay,
          //   //       ),
          //   //     );
          //   //   }
          //   // }
          //   // _liverateProvider.addFutureData(futureData);
          //
          //   // Set Future and Next list based on Liverates and Reference
          //   // for (var data in referenceData) {
          //   //   for (var rate in liveRateReferenceDetail) {
          //   //     if (rate.symbol!.toLowerCase() == data.source!.toLowerCase()) {
          //   //       bid = rate.bid!.toString();
          //   //       ask = rate.ask!.toString();
          //   //       high = rate.high!.toString();
          //   //       low = rate.low!.toString();
          //   //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
          //   //   }
          //   //   if (data.isDisplay! &&
          //   //       (   data.source == 'gold' ||
          //   //           data.source == 'silver' ||
          //   //           data.source == 'silvernext' ||
          //   //           data.source == 'goldnext')) {
          //   //     futureData.add(
          //   //       ComexDataModel(
          //   //         symbolName: data.symbolName,
          //   //         bid: bid,
          //   //         ask: ask,
          //   //         high: high,
          //   //         low: low,
          //   //         isDisplay: data.isDisplay,
          //   //       ),
          //   //     );
          //   //   }
          //   // }
          //   // _liverateProvider.addFutureData(futureData);
          //
          //   // Set Next & Future list based on Liverates and Reference
          //   // for (var data in referenceData) {
          //   //   for (var rate in liveRateReferenceDetail) {
          //   //     if (rate.symbol!.toLowerCase() == data.source!.toLowerCase()) {
          //   //       bid = rate.bid!.toString();
          //   //       ask = rate.ask!.toString();
          //   //       high = rate.high!.toString();
          //   //       low = rate.low!.toString();
          //   //     } // Set bid, ask, high and low which matches the symbol of rate and source of data.
          //   //   }
          //   //   if (data.isDisplay! &&
          //   //       (data.source == 'goldnext' || data.source == 'silvernext')) {
          //   //     nextData.add(
          //   //       ComexDataModel(
          //   //         symbolName: data.symbolName,
          //   //         bid: bid,
          //   //         ask: ask,
          //   //         high: high,
          //   //         low: low,
          //   //         isDisplay: data.isDisplay,
          //   //       ),
          //   //     );
          //   //   }
          //   // }
          //   // _liverateProvider.addNextData(nextData);
          // } else {
          //   setState(() {
          //     referenceComexData = _liverateProvider.getComexData();
          //     referenceFutureData = _liverateProvider.getFutureData();
          //   });
          // }
        });


        clientHeadersDetail = _liverateProvider.getClientHeaderData();

        // // Asign Live Rate to Live Rate Old
        // liveRatesDetailOldMaster = liveRatesDetailMaster;
        // liveRatesDetailOldTrade = liveRatesDetailTrade;

        // loadData();
      },
    );
    NotifySocketUpdate.controllerMainData!.stream.asBroadcastStream().listen(
      (event) {
        Future.delayed(const Duration(seconds: 1), () {

          liveRatesDetailMaster = _liverateProvider.getLiveRateData();

          liveRatesDetailOldMaster = liveRatesDetailMaster;

          if (!streamController.isClosed) {
            streamController.sink.add(liveRatesDetailMaster);
          }
        });



      },
    );
    NotifySocketUpdate.dropDown!.stream.asBroadcastStream().listen(
      (event) {
        setState(() {
          dropDown = _liverateProvider.getDropDownData();
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabGoldSilverController.dispose();
    streamController.close();
    NotifySocketUpdate.controllerHome!.close();
    NotifySocketUpdate.controllerMainData!.close();
    NotifySocketUpdate.dropDown!.close();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  loadData() {
    // liveRatesDetailMaster = [];
    // liveRatesDetailGold = [];
    // liveRatesDetailSilver = [];
    // referenceComexDataGold = [];
    // referenceComexDataSilver = [];
    // liveRateReferenceDetail = [];
    // referenceInrData = [];
    // referenceData = [];
    // liveRatesDetailOldMaster = [];
    // liveRateReferenceDetailOld = [];
    // referenceComexDataOld = [];
    // referenceFutureDataOld = [];

    // Get Data From Providers..


  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: referenceComexData.isEmpty ||
                            referenceComexData.length > 3
                        ? 3
                        : referenceComexData.length,
                    crossAxisSpacing: size.width * .01,
                    mainAxisExtent: size.height * .12,
                  ),
                  itemBuilder: (builder, index) {
                    return buildComexContainers(size, index);
                  },
                  itemCount: referenceComexData.length,
                ),
              ),
              SizedBox(
                height: size.height * .01,
              ),
              Constants.isLogin
                  ? Container(
                      height: 35.0,
                      color: AppColors.hintColor,
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: size.width * .3,
                            child: const CustomText(
                              text: 'PRODUCT',
                              size: 15.0,
                              fontWeight: FontWeight.bold,
                              textColor: AppColors.textColor,
                              align: TextAlign.start,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Visibility(
                                  visible:
                                      clientHeadersDetail.buyRate != null &&
                                          clientHeadersDetail.buyRate!,
                                  child: SizedBox(
                                    width: size.width / 6,
                                    child: const CustomText(
                                      text: 'BUY',
                                      size: 15.0,
                                      fontWeight: FontWeight.bold,
                                      textColor: AppColors.textColor,
                                      align: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      clientHeadersDetail.sellRate != null &&
                                          clientHeadersDetail.sellRate!,
                                  child: SizedBox(
                                    width: size.width / 6,
                                    child: const CustomText(
                                      text: 'SELL',
                                      size: 15.0,
                                      fontWeight: FontWeight.bold,
                                      textColor: AppColors.textColor,
                                      align: TextAlign.center,
                                    ),
                                  ),
                                ),

                                // Visibility(
                                //   visible: isRateVisible,
                                //   child: SizedBox(
                                //     width: size.width / 7.5,
                                //     child: const CustomText(
                                //       text: 'RATE',
                                //       size: 12.0,
                                //       fontWeight: FontWeight.bold,
                                //       textColor: AppColors.defaultColor,
                                //     ),
                                //   ),
                                // ),
                                // Visibility(
                                //   visible: isDiffVisible,
                                //   child: SizedBox(
                                //     width: size.width / 6,
                                //     child: const CustomText(
                                //       text: 'DIFF',
                                //       size: 12.0,
                                //       fontWeight: FontWeight.bold,
                                //       textColor: AppColors.defaultColor,
                                //       align: TextAlign.center,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        clientHeadersDetail.rateDisplay != null &&
                                clientHeadersDetail.rateDisplay!
                            ? Container(
                                height: 35.0,
                                color: AppColors.hintColor,
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SizedBox(
                                      width: size.width * .3,
                                      child: const CustomText(
                                        text: 'PRODUCT',
                                        size: 15.0,
                                        fontWeight: FontWeight.bold,
                                        textColor: AppColors.textColor,
                                        align: TextAlign.start,
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Visibility(
                                            visible: clientHeadersDetail
                                                        .buyRate !=
                                                    null &&
                                                clientHeadersDetail.buyRate!,
                                            child: SizedBox(
                                              width: size.width / 6,
                                              child: const CustomText(
                                                text: 'BUY',
                                                size: 15.0,
                                                fontWeight: FontWeight.bold,
                                                textColor: AppColors.textColor,
                                                align: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Visibility(
                                            visible: clientHeadersDetail
                                                        .sellRate !=
                                                    null &&
                                                clientHeadersDetail.sellRate!,
                                            child: SizedBox(
                                              width: size.width / 6,
                                              child: const CustomText(
                                                text: 'SELL',
                                                size: 15.0,
                                                fontWeight: FontWeight.bold,
                                                textColor: AppColors.textColor,
                                                align: TextAlign.center,
                                              ),
                                            ),
                                          ),

                                          // Visibility(
                                          //   visible: isRateVisible,
                                          //   child: SizedBox(
                                          //     width: size.width / 7.5,
                                          //     child: const CustomText(
                                          //       text: 'RATE',
                                          //       size: 12.0,
                                          //       fontWeight: FontWeight.bold,
                                          //       textColor: AppColors.defaultColor,
                                          //     ),
                                          //   ),
                                          // ),
                                          // Visibility(
                                          //   visible: isDiffVisible,
                                          //   child: SizedBox(
                                          //     width: size.width / 6,
                                          //     child: const CustomText(
                                          //       text: 'DIFF',
                                          //       size: 12.0,
                                          //       fontWeight: FontWeight.bold,
                                          //       textColor: AppColors.defaultColor,
                                          //       align: TextAlign.center,
                                          //     ),
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : const CustomText(
                                text: 'Liverate Currently Not Available',
                                size: 16.0,
                                fontWeight: FontWeight.bold,
                                textColor: AppColors.primaryColor,
                                align: TextAlign.center,
                              ),
                      ],
                    ),
              Visibility(
                visible: Constants.isLogin
                    ? true
                    : clientHeadersDetail.rateDisplay != null &&
                        clientHeadersDetail.rateDisplay!,
                // visible: afterLoginView,
                child: Flexible(
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: liveRatesDetailMaster.length,
                    itemBuilder: (context, index) => buildProductContainer(
                      size,
                      index,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: size.height * .01,
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: referenceFutureData.isEmpty ||
                            referenceFutureData.length > 3
                        ? 3
                        : referenceFutureData.length,
                    crossAxisSpacing: size.width * .01,
                    mainAxisExtent: size.height * .12,
                  ),
                  itemBuilder: (builder, index) {
                    return buildFutureContainers(size, index);
                  },
                  itemCount: referenceFutureData.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFutureContainers(Size size, int index) {
    if (referenceFutureDataOldChange.isNotEmpty) {
      if (referenceFutureDataOldChange.length == referenceFutureData.length) {
        var oldAskRate = referenceFutureDataOldChange[index].ask!.isEmpty
            ? 0.0
            : double.parse(referenceFutureDataOldChange[index].ask!);
        var newAskRate = referenceFutureData[index].ask!.isEmpty
            ? 0.0
            : double.parse(referenceFutureData[index].ask!);

        setFutureAskLableColor(oldAskRate, newAskRate, referenceFutureData[index]);

        var oldBidRate = referenceFutureDataOldChange[index].bid!.isEmpty
            ? 0.0
            : double.parse(referenceFutureDataOldChange[index].bid!);
        var newBidRate = referenceFutureData[index].bid!.isEmpty
            ? 0.0
            : double.parse(referenceFutureData[index].bid!);

        setFutureBidLableColor(oldBidRate, newBidRate, referenceFutureData[index]);
      }
    }
    if (referenceFutureData.length - 1 == index) {
      referenceFutureDataOldChange = referenceFutureData;
    }

    return referenceFutureData.isEmpty
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                // height: size.height * .035,
                // width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.hintColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5.0),
                    topRight: Radius.circular(5.0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  textScaleFactor: 1.0,
                  referenceFutureData[index].symbolName ?? '',
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(5.0),
                      bottomLeft: Radius.circular(5.0),
                    ),
                  ),
                  // color: AppColors.primaryColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(right: 20.0),
                            child: Text(
                              textScaleFactor: 1.0,
                              'Buy',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                          Text(
                            textScaleFactor: 1.0,
                            'Sell',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0, right: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 30.0,
                              width: size.width / 4.5,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: referenceFutureData[index].bidBGColor,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                textScaleFactor: 1.0,
                                referenceFutureData[index].bid ?? '',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      referenceFutureData[index].bidTextColor,
                                ),
                              ),
                            ),
                            Container(
                              height: 30.0,
                              width: size.width / 4.5,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: referenceFutureData[index].askBGColor,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(7),
                                ),
                              ),
                              child: Text(
                                textScaleFactor: 1.0,
                                referenceFutureData[index].ask ?? '',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      referenceFutureData[index].askTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            textScaleFactor: 1.0,
                            'L: ${referenceFutureData[index].low!.isEmpty ? '' : referenceFutureData[index].low!}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          Text(
                            textScaleFactor: 1.0,
                            ' / H: ${referenceFutureData[index].high!.isEmpty ? '' : referenceFutureData[index].high!} ',
                            style: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  Widget buildComexContainers(Size size, int index) {
    if (referenceComexDataOldChange.isNotEmpty) {
      if (referenceComexDataOldChange.length == referenceComexData.length) {
        var oldAskRate = referenceComexDataOldChange[index].ask!.isEmpty
            ? 0.0
            : double.parse(referenceComexDataOldChange[index].ask!);
        var newAskRate = referenceComexData[index].ask!.isEmpty
            ? 0.0
            : double.parse(referenceComexData[index].ask!);

        setAskLableColor(oldAskRate, newAskRate, referenceComexData[index]);

        var oldBidRate = referenceComexDataOldChange[index].bid!.isEmpty
            ? 0.0
            : double.parse(referenceComexDataOldChange[index].bid!);
        var newBidRate = referenceComexData[index].bid!.isEmpty
            ? 0.0
            : double.parse(referenceComexData[index].bid!);

        setBidLableColor(oldBidRate, newBidRate, referenceComexData[index]);
      }
    }
    if (referenceComexData.length - 1 == index) {
      referenceComexDataOldChange = referenceComexData;
    }

    return referenceComexData.isEmpty
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                // height: size.height * .035,
                // width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.hintColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5.0),
                    topRight: Radius.circular(5.0),
                  ),
                  // gradient: LinearGradient(
                  //   stops: const [0.2, 0.9],
                  //   colors: AppColors.primaryGradientColor,
                  // ),
                ),
                alignment: Alignment.center,
                child: Text(
                  textScaleFactor: 1.0,
                  referenceComexData[index].symbolName ?? '',
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(5.0),
                      bottomLeft: Radius.circular(5.0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 30.0,
                        width: size.width / 4.5,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: referenceComexData[index].askBGColor,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(7),
                          ),
                        ),
                        child: Text(
                          textScaleFactor: 1.0,
                          referenceComexData[index].ask ?? '',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: referenceComexData[index].askTextColor,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            textScaleFactor: 1.0,
                            'L: ${referenceComexData[index].low!.isEmpty ? '' : referenceComexData[index].low!}',
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          Text(
                            textScaleFactor: 1.0,
                            ' / H: ${referenceComexData[index].high!.isEmpty ? '' : referenceComexData[index].high!} ',
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryTextColor,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  Widget buildProductContainer(Size size, int index) {
    if (liveRatesDetailOldChange.isNotEmpty) {
      if (liveRatesDetailOldChange.length == liveRatesDetailMaster.length) {
        if (liveRatesDetailOldChange[index].ask == '-' ||
            liveRatesDetailOldChange[index].ask == '--') {
          liveRatesDetailOldChange[index].askBGColor = AppColors.primaryColor;
          liveRatesDetailOldChange[index].askTextColor = AppColors.secondaryTextColor;
        } else {
          dynamic oldAskRate = liveRatesDetailOldChange[index].ask!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailOldChange[index].ask!);
          dynamic newAskRate = liveRatesDetailMaster[index].ask!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailMaster[index].ask!);

          setLabelColorsAskMainProduct(oldAskRate, newAskRate, liveRatesDetailMaster[index]);
        }

        if (liveRatesDetailOldChange[index].bid == '-' ||
            liveRatesDetailOldChange[index].bid == '--') {
          liveRatesDetailOldChange[index].bidBGColor = AppColors.primaryColor;
          liveRatesDetailOldChange[index].bidTextColor =
              AppColors.secondaryTextColor;
          // setLabelColorsMainProduct('--', '--', liveRatesDetailMaster[index]);
        } else {
          dynamic oldBidRate = liveRatesDetailOldChange[index].bid!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailOldChange[index].bid!);
          dynamic newBidRate = liveRatesDetailMaster[index].bid!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailMaster[index].bid!);

          setLabelColorsBidMainProduct(
              oldBidRate, newBidRate, liveRatesDetailMaster[index]);
        }
      }
    }

    if (liveRatesDetailMaster.length - 1 == index) {
      liveRatesDetailOldChange = liveRatesDetailMaster;
    }

    return liveRatesDetailMaster.isEmpty
        ? Container()
        : Constants.isLogin
            ? Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: GestureDetector(
                  onTap: () {
                    // globalIndex = index;
                    generateDropDownList(liveRatesDetailMaster[index].symbolId,
                        liveRatesDetailMaster[index].source);
                    showNewTradePopup(size, index);
                  },
                  child: Container(
                    // height: 50.0,
                    decoration: BoxDecoration(
                      border:
                          Border.all(width: 0.8, color: AppColors.primaryColor),
                      borderRadius: BorderRadius.circular(5.0),
                      color: AppColors.primaryColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 5.0, bottom: 5.0, left: 5.0),
                          child: Image.asset(
                            AppImagePath.greencolum,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: size.width * .3,
                                child: CustomText(
                                  text:
                                      '${liveRatesDetailMaster[index].symbol} ',
                                  size: 12.0,
                                  fontWeight: FontWeight.bold,
                                  textColor: AppColors.secondaryTextColor,
                                  align: TextAlign.start,
                                ),
                              ),
                              SizedBox(
                                width: size.width * .3,
                                child: CustomText(
                                  text:
                                      'Time-${liveRatesDetailMaster[index].time}',
                                  size: 9.0,
                                  fontWeight: FontWeight.bold,
                                  textColor: AppColors.hintColor,
                                  align: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                // width: size.width / 7,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Visibility(
                                      visible:
                                          clientHeadersDetail.buyRate != null &&
                                              clientHeadersDetail.buyRate!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: liveRatesDetailMaster[index]
                                                            .bid ==
                                                        '-' ||
                                                    liveRatesDetailMaster[index]
                                                            .bid ==
                                                        '--'
                                                ? AppColors.primaryColor
                                                : liveRatesDetailMaster[index]
                                                    .bidBGColor),
                                        padding: const EdgeInsets.all(3.0),
                                        child: CustomText(
                                            text:
                                                '${liveRatesDetailMaster[index].bid}',
                                            size: 12.0,
                                            fontWeight: FontWeight.bold,
                                            textColor:
                                                liveRatesDetailMaster[index]
                                                    .bidTextColor),
                                      ),
                                    ),
                                    Visibility(
                                      visible:
                                          clientHeadersDetail.lowRate != null &&
                                              clientHeadersDetail.lowRate!,
                                      child: CustomText(
                                        text:
                                            '${liveRatesDetailMaster[index].premiumBuy}',
                                        size: 10.0,
                                        fontWeight: FontWeight.normal,
                                        textColor: AppColors.defaultColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                // width: size.width / 7,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Visibility(
                                      visible: clientHeadersDetail.sellRate !=
                                              null &&
                                          clientHeadersDetail.sellRate!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          color: liveRatesDetailMaster[index]
                                                          .ask ==
                                                      '-' ||
                                                  liveRatesDetailMaster[index]
                                                          .ask ==
                                                      '--'
                                              ? AppColors.primaryColor
                                              : liveRatesDetailMaster[index]
                                                  .askBGColor,
                                        ),
                                        padding: const EdgeInsets.all(3.0),
                                        child: CustomText(
                                          text:
                                              '${liveRatesDetailMaster[index].ask}',
                                          size: 12.0,
                                          fontWeight: FontWeight.bold,
                                          textColor:
                                              liveRatesDetailMaster[index]
                                                  .askTextColor,
                                          align: TextAlign.start,
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: clientHeadersDetail.highRate !=
                                              null &&
                                          clientHeadersDetail.highRate!,
                                      child: CustomText(
                                        text:
                                            '${liveRatesDetailMaster[index].premium}',
                                        size: 10.0,
                                        textColor: AppColors.defaultColor,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: GestureDetector(
                  onTap: () {
                    // Navigator.of(context).pushNamed(
                    //   Login_Screen.routeName,
                    //   arguments: const Login_Screen(
                    //     isFromSplash: false,
                    //   ),
                    // )
                    //     .then((_) {
                    //   checkIsLogin();
                    // });
                  },
                  child: Container(
                    // height: 50.0,
                    decoration: BoxDecoration(
                      border:
                          Border.all(width: 0.8, color: AppColors.primaryColor),
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 5.0, bottom: 5.0, left: 5.0),
                          child: Image.asset(
                            AppImagePath.greencolum,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: size.width * .3,
                                child: CustomText(
                                  text:
                                      '${liveRatesDetailMaster[index].symbol} ',
                                  size: 12.0,
                                  fontWeight: FontWeight.bold,
                                  textColor: AppColors.secondaryTextColor,
                                  align: TextAlign.start,
                                ),
                              ),
                              SizedBox(
                                width: size.width * .3,
                                child: CustomText(
                                  text:
                                      'Time-${liveRatesDetailMaster[index].time}',
                                  size: 9.0,
                                  fontWeight: FontWeight.bold,
                                  textColor: AppColors.hintColor,
                                  align: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                // width: size.width / 7,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Visibility(
                                      visible:
                                          clientHeadersDetail.buyRate != null &&
                                              clientHeadersDetail.buyRate!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color: liveRatesDetailMaster[index]
                                                            .bid ==
                                                        '-' ||
                                                    liveRatesDetailMaster[index]
                                                            .bid ==
                                                        '--'
                                                ? AppColors.primaryColor
                                                : liveRatesDetailMaster[index]
                                                    .bidBGColor),
                                        padding: const EdgeInsets.all(3.0),
                                        child: CustomText(
                                            text:
                                                '${liveRatesDetailMaster[index].bid}',
                                            size: 12.0,
                                            fontWeight: FontWeight.bold,
                                            textColor:
                                                liveRatesDetailMaster[index]
                                                    .bidTextColor),
                                      ),
                                    ),
                                    Visibility(
                                      visible:
                                          clientHeadersDetail.lowRate != null &&
                                              clientHeadersDetail.lowRate!,
                                      child: CustomText(
                                        text:
                                            '${liveRatesDetailMaster[index].premiumBuy}',
                                        size: 10.0,
                                        fontWeight: FontWeight.normal,
                                        textColor: AppColors.defaultColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                // width: size.width / 7,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Visibility(
                                      visible: clientHeadersDetail.sellRate !=
                                              null &&
                                          clientHeadersDetail.sellRate!,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          color: liveRatesDetailMaster[index]
                                                          .ask ==
                                                      '-' ||
                                                  liveRatesDetailMaster[index]
                                                          .ask ==
                                                      '--'
                                              ? AppColors.primaryColor
                                              : liveRatesDetailMaster[index]
                                                  .askBGColor,
                                        ),
                                        padding: const EdgeInsets.all(3.0),
                                        child: CustomText(
                                          text:
                                              '${liveRatesDetailMaster[index].ask}',
                                          size: 12.0,
                                          fontWeight: FontWeight.bold,
                                          textColor:
                                              liveRatesDetailMaster[index]
                                                  .askTextColor,
                                          align: TextAlign.start,
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: clientHeadersDetail.highRate !=
                                              null &&
                                          clientHeadersDetail.highRate!,
                                      child: CustomText(
                                        text:
                                            '${liveRatesDetailMaster[index].premium}',
                                        size: 10.0,
                                        textColor: AppColors.defaultColor,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
  }

  Widget buildSellTradeContainer(
      Size size, int index, AsyncSnapshot<List<Liverate>> snapshot) {
    if (liveRatesDetailOldChange.isNotEmpty) {
      if (liveRatesDetailOldChange.length == liveRatesDetailMaster.length) {
        if (liveRatesDetailOldChange[index].bid == '-' ||
            liveRatesDetailOldChange[index].bid == '--') {
          // var oldAskRate = liveRatesDetailOldChange[index].ask!.isEmpty
          //     ? 0.0
          //     : double.parse(liveRatesDetailOldChange[index].ask!);
          // var newAskRate = liveRatesDetailMaster[index].ask!.isEmpty
          //     ? 0.0
          //     : double.parse(liveRatesDetailMaster[index].ask!);
          //
          // setLabelColors(oldAskRate, newAskRate, liveRatesDetailMaster[index]);
        } else {
          var oldBidRate = liveRatesDetailOldChange[index].bid!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailOldChange[index].bid!);
          var newBidRate = liveRatesDetailMaster[index].bid!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailMaster[index].bid!);

          setLabelTradeColors(
              oldBidRate, newBidRate, liveRatesDetailMaster[index]);
        }

        // var oldBidRate = liveRatesDetailOldChange[index].bid!.isEmpty
        //     ? 0.0
        //     : double.parse(liveRatesDetailOldChange[index].bid!);
        // var newBidRate = liveRatesDetail[index].bid!.isEmpty
        //     ? 0.0
        //     : double.parse(liveRatesDetail[index].bid!);
        //
        // setMainBidTradeLableColor(oldBidRate, newBidRate, liveRatesDetail[index]);
      }
    }
    liveRatesDetailOldChange = liveRatesDetailMaster;
    //  if (liveRatesDetail.length - 1 == index) {
    //   liveRatesDetailOldChange = liveRatesDetail;
    // }

    return Container(
      width: size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            width: 1.5, color: liveRatesDetailMaster[index].bidTradeBGColor),
      ),
      // width: size.width / 7,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomText(
                text: 'SELL',
                size: 16.0,
                fontWeight: FontWeight.bold,
                textColor: liveRatesDetailMaster[index].bidTradeBGColor),
            CustomText(
              text: '${liveRatesDetailMaster[index].bid} ',
              size: 16.0,
              fontWeight: FontWeight.bold,
              textColor: liveRatesDetailMaster[index].bidTradeBGColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBuyTradeContainer(
      Size size, int index, AsyncSnapshot<List<Liverate>> snapshot) {
    if (liveRatesDetailOldChange.isNotEmpty) {
      if (liveRatesDetailOldChange.length == liveRatesDetailMaster.length) {
        if (liveRatesDetailOldChange[index].ask == '-' ||
            liveRatesDetailOldChange[index].ask == '--') {
          // var oldAskRate = liveRatesDetailOldChange[index].ask!.isEmpty
          //     ? 0.0
          //     : double.parse(liveRatesDetailOldChange[index].ask!);
          // var newAskRate = liveRatesDetailMaster[index].ask!.isEmpty
          //     ? 0.0
          //     : double.parse(liveRatesDetailMaster[index].ask!);
          //
          // setLabelColors(oldAskRate, newAskRate, liveRatesDetailMaster[index]);
        } else {
          var oldAskRate = liveRatesDetailOldChange[index].ask!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailOldChange[index].ask!);
          var newAskRate = liveRatesDetailMaster[index].ask!.isEmpty
              ? 0.0
              : double.parse(liveRatesDetailMaster[index].ask!);

          setLabelTradeColors(
              oldAskRate, newAskRate, liveRatesDetailMaster[index]);
        }
      }
    }
    liveRatesDetailOldChange = liveRatesDetailMaster;
    //  if (liveRatesDetail.length - 1 == index) {
    //   liveRatesDetailOldChange = liveRatesDetail;
    // }

    return Container(
      width: size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            width: 1.5, color: liveRatesDetailMaster[index].bidTradeBGColor),
      ),
      // width: size.width / 7,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomText(
                text: 'BUY',
                size: 16.0,
                fontWeight: FontWeight.bold,
                textColor: liveRatesDetailMaster[index].bidTradeBGColor),
            CustomText(
              text: '${liveRatesDetailMaster[index].ask} ',
              size: 16.0,
              fontWeight: FontWeight.bold,
              textColor: liveRatesDetailMaster[index].bidTradeBGColor,
            ),
          ],
        ),
      ),
    );
  }

  void showNewTradePopup(Size size, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent.withOpacity(0.6),
      backgroundColor: AppColors.defaultColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return StreamBuilder<List<Liverate>>(
              stream: getLiveRatesStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Liverate>> snapshot) {
                return SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      children: [
                        Container(
                          height: size.height * 0.05,
                          width: size.width,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10)),
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CustomText(
                              text: '${liveRatesDetailMaster[index].symbol}',
                              textColor: AppColors.defaultColor,
                              size: 15.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 2, color: AppColors.primaryColor),
                                borderRadius: BorderRadius.circular(5)),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20.0, right: 20.0, top: 10.0),
                                  child: Container(
                                    height: size.height * 0.05,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(
                                        8.0,
                                      ),
                                    ),
                                    child: TabBar(
                                      onTap: (index) {
                                        if (index == 0) {
                                          setState(() {
                                            // getOrdersStatusFromIndex(index);
                                            isMarketSelected = true;
                                            // isLimitSelected = false;
                                          });
                                        } else {
                                          setState(() {
                                            // getOrdersStatusFromIndex(index);
                                            isMarketSelected = false;
                                            // isLimitSelected = true;
                                          });
                                        }
                                        debugPrint(isMarketSelected.toString());
                                      },
                                      controller: _tabController,
                                      indicator: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        color: AppColors.primaryColor,
                                      ),
                                      labelColor: Colors.white,
                                      unselectedLabelColor: Colors.black,
                                      tabs: const [
                                        Tab(
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            'Market',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                        ),
                                        // Tab(
                                        //   child: Text(
                                        //     'Limit',
                                        //     style: TextStyle(
                                        //         fontWeight: FontWeight.bold,
                                        //         fontSize: 15),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: size.height * 0.01,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, right: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Flexible(
                                          flex: 1,
                                          child: buildSellTradeContainer(
                                              size, index, snapshot)),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Flexible(
                                          flex: 1,
                                          child: buildBuyTradeContainer(
                                              size, index, snapshot)),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: items.isNotEmpty,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: 10.0, top: size.height * 0.02),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        CustomText(
                                          text: 'Quantity :',
                                          size: 14.0,
                                          fontWeight: FontWeight.bold,
                                          textColor: AppColors.textColor,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton2<String>(
                                            isExpanded: false,
                                            items:
                                                _addDividersAfterItems(items),
                                            value: quantity,
                                            onChanged: (String? value) {
                                              setState(() {
                                                quantity = value!;
                                              });
                                            },
                                            buttonStyleData: ButtonStyleData(
                                              height: 40,
                                              width: 120,
                                              padding: const EdgeInsets.only(
                                                  left: 8, right: 8),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: AppColors.primaryColor,
                                                ),
                                                color: AppColors.defaultColor,
                                              ),
                                              elevation: 2,
                                            ),
                                            iconStyleData: const IconStyleData(
                                              icon: Icon(
                                                Icons.arrow_drop_down_sharp,
                                              ),
                                              iconSize: 20,
                                              iconEnabledColor:
                                                  AppColors.textColor,
                                              iconDisabledColor: Colors.grey,
                                            ),
                                            dropdownStyleData:
                                                DropdownStyleData(
                                              maxHeight: 200,
                                              width: 120,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: AppColors.defaultColor,
                                              ),
                                              offset: const Offset(-0, 0),
                                              scrollbarTheme:
                                                  ScrollbarThemeData(
                                                radius:
                                                    const Radius.circular(8),
                                                thickness:
                                                    MaterialStateProperty.all(
                                                        3),
                                                thumbVisibility:
                                                    MaterialStateProperty.all(
                                                        true),
                                              ),
                                            ),
                                            menuItemStyleData:
                                                MenuItemStyleData(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              customHeights:
                                                  _getCustomItemsHeights(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      right: 10.0, top: size.height * 0.02),
                                  child: Visibility(
                                    visible: !isMarketSelected,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        CustomText(
                                          text: 'Price :',
                                          size: 14.0,
                                          fontWeight: FontWeight.bold,
                                          textColor: AppColors.textColor,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: TextFormField(
                                            cursorColor: AppColors.primaryColor,
                                            controller: _priceController,
                                            decoration:
                                                getInputBoxDecoration('Price'),
                                            keyboardType: TextInputType
                                                .numberWithOptions(),
                                            textInputAction:
                                                TextInputAction.done,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 8.0,
                                      right: 8.0,
                                      bottom: 10.0,
                                      top: size.height * 0.02),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          child: Container(
                                            margin: EdgeInsets.only(right: 5),
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppColors.red,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            alignment: Alignment.center,
                                            child: Stack(
                                              children: [
                                                Visibility(
                                                  visible: !isSellLoading,
                                                  child: CustomText(
                                                    text: 'Sell',
                                                    size: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                    textColor:
                                                        AppColors.defaultColor,
                                                    align: TextAlign.start,
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: isSellLoading,
                                                  child: SizedBox(
                                                    height: 20.0,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: AppColors
                                                          .defaultColor,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (!isMarketSelected &&
                                                _priceController.text.isEmpty) {
                                              setState(() {
                                                isBuySellSelected = false;
                                              });
                                              validateTrade(
                                                  liveRatesDetailMaster[index]
                                                      .symbolId!);
                                            } else {
                                              setState(() {
                                                isBuySellSelected = false;
                                                isSellLoading = true;
                                              });
                                              validateTrade(
                                                  liveRatesDetailMaster[index]
                                                      .symbolId!);
                                            }
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          child: Container(
                                            margin: EdgeInsets.only(left: 5),
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppColors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            alignment: Alignment.center,
                                            child: Stack(
                                              children: [
                                                Visibility(
                                                  visible: !isBuyLoading,
                                                  child: CustomText(
                                                    text: 'BUY',
                                                    size: 16.0,
                                                    fontWeight: FontWeight.bold,
                                                    textColor:
                                                        AppColors.defaultColor,
                                                    align: TextAlign.start,
                                                  ),
                                                ),
                                                Visibility(
                                                  visible: isBuyLoading,
                                                  child: SizedBox(
                                                    height: 20.0,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: AppColors
                                                          .defaultColor,
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                          onTap: () {
                                            if (!isMarketSelected &&
                                                _priceController.text.isEmpty) {
                                              setState(() {
                                                isBuySellSelected = true;
                                              });
                                              validateTrade(
                                                  liveRatesDetailMaster[index]
                                                      .symbolId!);
                                            } else {
                                              setState(() {
                                                isBuySellSelected = true;
                                                isBuyLoading = true;
                                              });
                                              validateTrade(
                                                  liveRatesDetailMaster[index]
                                                      .symbolId!);
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _tabController.animateTo(0,
          duration: Duration(milliseconds: 200), curve: Curves.easeIn);
      setState(() {
        isMarketSelected = true;
        _priceController.clear();
      });
    });
  }

  Stream<List<Liverate>> getLiveRatesStream() {
    return streamController.stream;
  }

  setAskLableColor(double oldRate, double newRate, model) {
    if (oldRate < newRate) {
      model.askBGColor = AppColors.green;
      model.askTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      model.askBGColor = AppColors.red;
      model.askTextColor = AppColors.defaultColor;
    }
    /*else if (oldRate == newRate) {
      model.askBGColor = AppColors.defaultBackgroundColor;
      model.askTextColor = AppColors.defaultTextColor;
    }*/
    else {
      model.askBGColor = AppColors.primaryColor;
      model.askTextColor = AppColors.defaultColor;
    }
  }

  setFutureAskLableColor(double oldRate, double newRate, model) {
    if (oldRate < newRate) {
      model.askBGColor = AppColors.green;
      model.askTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      model.askBGColor = AppColors.red;
      model.askTextColor = AppColors.defaultColor;
    }
    /*else if (oldRate == newRate) {
      model.askBGColor = AppColors.defaultBackgroundColor;
      model.askTextColor = AppColors.defaultTextColor;
    }*/
    else {
      model.askBGColor = AppColors.primaryColor;
      model.askTextColor = AppColors.defaultColor;
    }
  }


  setBidLableColor(double oldRate, double newRate, model) {
    if (oldRate < newRate) {
      model.bidBGColor = AppColors.green;
      model.bidTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      model.bidBGColor = AppColors.red;
      model.bidTextColor = AppColors.defaultColor;
    }
    /*else if (oldRate == newRate) {
      model.askBGColor = AppColors.defaultBackgroundColor;
      model.askTextColor = AppColors.defaultTextColor;
    }*/
    else {
      model.bidBGColor = AppColors.primaryColor;
      model.bidTextColor = AppColors.defaultColor;
    }
  }

  setFutureBidLableColor(double oldRate, double newRate, model) {
    if (oldRate < newRate) {
      model.bidBGColor = AppColors.green;
      model.bidTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      model.bidBGColor = AppColors.red;
      model.bidTextColor = AppColors.defaultColor;
    }
    /*else if (oldRate == newRate) {
      model.askBGColor = AppColors.defaultBackgroundColor;
      model.askTextColor = AppColors.defaultTextColor;
    }*/
    else {
      model.bidBGColor = AppColors.primaryColor;
      model.bidTextColor = AppColors.defaultColor;
    }
  }

  // void setLabelColors(double oldRate, double newRate, model) {
  //   if (oldRate < newRate) {
  //     model.askBGColor = AppColors.green;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.green;
  //     model.bidTextColor = AppColors.defaultColor;
  //   } else if (oldRate > newRate) {
  //     model.askBGColor = AppColors.red;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.red;
  //     model.bidTextColor = AppColors.defaultColor;
  //   }
  //   /*else if (oldRate == newRate) {
  //     model.askBGColor = AppColors.primaryColor;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.primaryColor;
  //     model.bidTextColor = AppColors.defaultColor;
  //   } */
  //   else {
  //     model.askBGColor = AppColors.primaryColor;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.primaryColor;
  //     model.bidTextColor = AppColors.defaultColor;
  //   }
  // }
  //
  // void setLabelFutureColors(dynamic oldRate, dynamic newRate, model) {
  //   if (oldRate < newRate) {
  //     model.askBGColor = AppColors.green;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.green;
  //     model.bidTextColor = AppColors.defaultColor;
  //   } else if (oldRate > newRate) {
  //     model.askBGColor = AppColors.red;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.red;
  //     model.bidTextColor = AppColors.defaultColor;
  //   }
  //   /*else if (oldRate == newRate) {
  //     model.askBGColor = AppColors.primaryColor;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.primaryColor;
  //     model.bidTextColor = AppColors.defaultColor;
  //   } */
  //   else {
  //     model.askBGColor = AppColors.primaryColor;
  //     model.askTextColor = AppColors.defaultColor;
  //     model.bidBGColor = AppColors.primaryColor;
  //     model.bidTextColor = AppColors.defaultColor;
  //   }
  // }

  void setLabelColorsBidMainProduct(dynamic oldRate, dynamic newRate, model) {
    if (oldRate < newRate) {
      // model.askBGColor = AppColors.green;
      // model.askTextColor = AppColors.defaultColor;
      model.bidBGColor = AppColors.green;
      model.bidTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      // model.askBGColor = AppColors.red;
      // model.askTextColor = AppColors.defaultColor;
      model.bidBGColor = AppColors.red;
      model.bidTextColor = AppColors.defaultColor;
    }
    /*  else if (oldRate == newRate) {
      model.askBGColor = AppColors.primaryColor;
      model.askTextColor = AppColors.secondaryTextColor;
      model.bidBGColor = AppColors.primaryColor;
      model.bidTextColor = AppColors.secondaryTextColor;
    } */
    else {
      // model.askBGColor = AppColors.primaryColor;
      // model.askTextColor = AppColors.secondaryTextColor;
      model.bidBGColor = AppColors.primaryColor;
      model.bidTextColor = AppColors.secondaryTextColor;
    }
  }
  void setLabelColorsAskMainProduct(dynamic oldRate, dynamic newRate, model) {
    if (oldRate < newRate) {
      model.askBGColor = AppColors.green;
      model.askTextColor = AppColors.defaultColor;
      // model.bidBGColor = AppColors.green;
      // model.bidTextColor = AppColors.defaultColor;
    } else if (oldRate > newRate) {
      model.askBGColor = AppColors.red;
      model.askTextColor = AppColors.defaultColor;
      // model.bidBGColor = AppColors.red;
      // model.bidTextColor = AppColors.defaultColor;
    }
    /*  else if (oldRate == newRate) {
      model.askBGColor = AppColors.primaryColor;
      model.askTextColor = AppColors.secondaryTextColor;
      model.bidBGColor = AppColors.primaryColor;
      model.bidTextColor = AppColors.secondaryTextColor;
    } */
    else {
      model.askBGColor = AppColors.primaryColor;
      model.askTextColor = AppColors.secondaryTextColor;
      // model.bidBGColor = AppColors.primaryColor;
      // model.bidTextColor = AppColors.secondaryTextColor;
    }
  }

  void setLabelTradeColors(dynamic oldRate, dynamic newRate, model) {
    if (oldRate < newRate) {
      model.bidTradeBGColor = AppColors.red;
    } else if (oldRate > newRate) {
      model.bidTradeBGColor = AppColors.green;
    } else if (oldRate == newRate) {
      model.bidTradeBGColor = AppColors.primaryColor;
    } else {
      model.bidTradeBGColor = AppColors.primaryColor;
    }
  }

  getInputBoxDecoration(String text) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.fromLTRB(10, 20, 20, 0),
      hintText: text,
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        borderSide: BorderSide(
          color: AppColors.primaryColor,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  List<double> _getCustomItemsHeights() {
    final List<double> itemsHeights = [];
    for (int i = 0; i < (items.length * 2) - 1; i++) {
      if (i.isEven) {
        itemsHeights.add(40);
      }
      if (i.isOdd) {
        itemsHeights.add(4);
      }
    }
    return itemsHeights;
  }

  List<DropdownMenuItem<String>> _addDividersAfterItems(List<String> items) {
    final List<DropdownMenuItem<String>> menuItems = [];
    for (final String item in items) {
      menuItems.addAll(
        [
          DropdownMenuItem<String>(
            value: item,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CustomText(
                text: item,
                size: 14.0,
                fontWeight: FontWeight.bold,
                textColor: item == quantity
                    ? AppColors.primaryColor
                    : AppColors.textColor,
              ),
            ),
          ),
          if (item != items.last)
            const DropdownMenuItem<String>(
              enabled: false,
              child: Divider(color: AppColors.hintColor),
            ),
        ],
      );
    }
    return menuItems;
  }

  Future<void> checkIsLogin() async {
    final bool loginStatus = await shared.getIsLogin();
    if (loginStatus) {
      setState(() {
        Constants.isLogin = true;
      });
      final loginData = await shared.getLoginData();
      if (loginData.isNotEmpty) {
        userData = LoginData.getJson(json.decode(loginData));
      }
    }
  }

  void callInsertOpenOrderDetailAPi(String quantity, bool isMarketSelected,
      bool isBuySellSelected, String price, String symbolId) {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        var objVariable = insertOpenOrderDetailRequestToJson(
            InsertOpenOrderDetailRequest(
                symbolId: symbolId,
                token: Constants.token,
                quantity: Functions.alphaNum(quantity),
                tradeFrom: Platform.isIOS ? 'Ios' : 'Android',
                tradeType: isMarketSelected && isBuySellSelected
                    ? '1'
                    : isMarketSelected && !isBuySellSelected
                        ? '2'
                        : !isMarketSelected && isBuySellSelected
                            ? '3'
                            : !isMarketSelected && !isBuySellSelected
                                ? '4'
                                : '',
                deviceToken: Constants.fcmToken,
                buyLimitPrice:
                    !isMarketSelected && isBuySellSelected ? price : '',
                sellLimitPrice:
                    !isMarketSelected && !isBuySellSelected ? price : ''));

        insertOpenOrderService.insertOpenOrderObj(objVariable).then((response) {
          if (response.data == '200') {
            Navigator.of(context).pop();
            setState(() {
              isBuyLoading = false;
              isSellLoading = false;
              Constants.tradeType = isMarketSelected && isBuySellSelected
                  ? '1'
                  : isMarketSelected && !isBuySellSelected
                      ? '2'
                      : !isMarketSelected && isBuySellSelected
                          ? '3'
                          : !isMarketSelected && !isBuySellSelected
                              ? '4'
                              : '';
            });

            // Functions.showToast('Login has been Successfully');
          } else {
            setState(() {
              isBuyLoading = false;
              isSellLoading = false;
            });
            // Functions.showToast('Login Fail');
          }
        });

        debugPrint(
            'insertOpen----------------------------------------$objVariable');
      } else {
        setState(() {
          isBuyLoading = false;
          isSellLoading = false;
        });
        Functions.showToast(Constants.noInternet);
      }
    });
  }

  generateDropDownList(String? symbolId, String? source) {
    if (int.tryParse(symbolId ?? "") != 0) {
      int selectedSymbolId = int.parse(symbolId!);
      var selectedItems =
          dropDown.where((item) => selectedSymbolId == item.symbolId);

      if (selectedItems.isNotEmpty) {
        final selectedItem = selectedItems.first;
        oneClick = selectedItem.oneClick;
        inTotal = selectedItem.inTotal;
        step = selectedItem.step;

        if (step == null || step <= 0) {
          step = oneClick;
        }

        if (oneClick != 0 && inTotal != 0 && step != 0) {
          setState(() {
            gmkg = (source?.toLowerCase() == 'gold' ||
                    source?.toLowerCase() == 'goldnext')
                ? 'gm'
                : 'Kg';
            items = List.generate(((inTotal - oneClick) ~/ step) + 1,
                (index) => '${oneClick + index * step} $gmkg');
            quantity = (items.isNotEmpty ? items[0] : null)!;
          });
        } else {
          setState(() {
            items.clear();
            quantity = '';
          });
        }
      } else {
        setState(() {
          items.clear();
          quantity = '';
        });
      }
    } else {
      setState(() {
        items.clear();
        quantity = '';
      });
    }
  }

  void validateTrade(String symbolId) {
    if (isMarketSelected && isBuySellSelected) {
      callInsertOpenOrderDetailAPi(quantity, isMarketSelected,
          isBuySellSelected, _priceController.text, symbolId);
    } else if (isMarketSelected && !isBuySellSelected) {
      callInsertOpenOrderDetailAPi(quantity, isMarketSelected,
          isBuySellSelected, _priceController.text, symbolId);
    } else if (!isMarketSelected && isBuySellSelected) {
      if (_priceController.text.isNotEmpty) {
        callInsertOpenOrderDetailAPi(quantity, isMarketSelected,
            isBuySellSelected, _priceController.text, symbolId);
      } else {
        return DialogUtil.showAlertDialog(
          context,
          title: Constants.alertAndCnfTitle,
          content: 'Please enter price',
          okBtnText: 'Ok',
          cancelBtnText: 'Cancel',
        );
      }
    } else if (!isMarketSelected && !isBuySellSelected) {
      if (_priceController.text.isNotEmpty) {
        callInsertOpenOrderDetailAPi(quantity, isMarketSelected,
            isBuySellSelected, _priceController.text, symbolId);
      } else {
        return DialogUtil.showAlertDialog(
          context,
          title: Constants.alertAndCnfTitle,
          content: 'Please enter price',
          okBtnText: 'Ok',
          cancelBtnText: 'Cancel',
        );
      }
    }
  }
}
