import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:terminal_demo/Constants/constant.dart';
import 'package:terminal_demo/Functions.dart';
import 'package:terminal_demo/Models/CommenRequestModel.dart';
import '../Constants/notify_socket_update.dart';
import '../Models/logindata.dart';
import '../Models/client_header.dart';
import '../Models/liverate.dart';
import '../Models/reference_data.dart';
import '../Models/reference_data_rate.dart';
import '../Providers/liverate_provider.dart';
import '../Utils/shared.dart';

class SocketService {
  static getLiveRateData(BuildContext context) async {
    Shared shared = Shared();
    bool isLogin = false;

    final provider = Provider.of<LiverateProvider>(context, listen: false);

    Socket socket = io(
        Constants.socketUrl,
        OptionBuilder().setTransports(
            ['websocket']).build()); // Set socket url for connection
    socket.disconnect();
    debugPrint('Disconnect-----------------------------------');
    socket.connect();
    debugPrint('Connect-----------------------------------');
    socket.onConnect((_) async {
      socket.emit('Client', [Constants.projectName]);
      socket.emit('room', [Constants.projectName]);
      debugPrint('Client-Emit------------------------------------------------');

      shared.getIsLogin().then((login) async {
        if (login) {
          final loginData = await shared.getLoginData();
          if (loginData.isNotEmpty) {
            final userData = LoginData.getJson(json.decode(loginData));
            socket.emit(
                "End_Client", "${Constants.projectName}_${userData.loginId}");
            debugPrint(
                'End_Client-Emit------------------------------------------------');
          }
        }
      });
      debugPrint('onConnect-----------------------------------------------------');
    });

    socket.on('ClientHeaderDetails', (response) {
      if (response['MessageType'] == 'Header') {
        var responseData = jsonDecode(response["Data"]);
        List<ClientHeaderData> listData = [];
        for (var data in responseData) {
          final clientHeaderData = ClientHeaderData.fromJson(data);
          listData.add(clientHeaderData);
        }
        provider.addClientHeaderData(listData);
        _addToControllerIfNotClosed(
            listData, NotifySocketUpdate.controllerClientData);
        _addToControllerIfNotClosed(
            listData, NotifySocketUpdate.controllerHome);
      }
    });

    socket.on('ClientData', (response) {
      var responseData = jsonDecode(response);
      List<ReferenceData> listData = [];
      for (var data in responseData) {
        final liveRate = ReferenceData.fromJson(data);
        listData.add(liveRate);
      }
      provider.addReferenceData(listData);
      // debugPrint('ClientData' + responseData.toString());
    });

    socket.on('Liverate', (liverateResponse) {
      // List<Map<String, dynamic>> rawData=liverateResponse;
      List<ReferenceDataRate> referenceDataRate = [];
      // List<dynamic> refList = [];
      // refList=liverateResponse.map((data) => ReferenceDataRate.fromJson(data)).toList();
      // // referenceDataRate=liverateResponse.map((data) => ReferenceDataRate.fromJson(data)).toList();
      //
      // referenceDataRate.addAll(refList as Iterable<ReferenceDataRate>);

      for (var item in liverateResponse) {
        referenceDataRate.add(ReferenceDataRate.fromJson(item));
      }
      provider.addReferenceDataRate(referenceDataRate);
      _addToControllerIfNotClosed(
          liverateResponse, NotifySocketUpdate.controllerRefrence);
    });

    socket.on('message', (messageResponse) async {
      List<Liverate> liveRate = [];
      isLogin = await shared.getIsLogin();
      var responseData = messageResponse['Rate'];

      if (isLogin) {
        List<GroupDetailsBuySell> premiData = provider.getPremiumData();
        List<GroupDetailsDropDown> groupSymbolId = provider.getDropDownData();
        for (var item in responseData) {
          if (item['IsDisplayTerminal'] == 'True') {
            for (var items in groupSymbolId) {
              if (items.symbolId == int.parse(item['SymbolId'])) {
                if (premiData.isNotEmpty) {
                  final source = item['Source'].toLowerCase();
                  dynamic goldBuyPremium = premiData[0].goldBuyPremium ?? 0;
                  dynamic goldSellPremium = premiData[0].goldSellPremium ?? 0;
                  dynamic silverBuyPremium = premiData[0].silverBuyPremium ?? 0;
                  dynamic silverSellPremium =
                      premiData[0].silverSellPremium ?? 0;
                  //group filter premium buy sell
                  dynamic buyPremium = items.buyPremium;
                  dynamic sellPremium = items.sellPremium;
                  // dynamic premSell = !Functions.isNumeric(item['Premium'])
                  //          ? '--'
                  //          : (Functions.isDecimal(item['Premium'])
                  //             ? double.parse(item['Premium'])
                  //             : int.parse(item['Premium'])) +
                  //             sellPremium +
                  //             goldSellPremium;
                  // dynamic premBuy = !Functions.isNumeric(item['PremiumBuy'])
                  //     ? '--'
                  //     : (Functions.isDecimal(item['PremiumBuy'])
                  //             ? double.parse(item['PremiumBuy'])
                  //             : int.parse(item['PremiumBuy'])) +
                  //         buyPremium +
                  //         goldBuyPremium;

                  dynamic bid, ask, high, low, premSell, premBuy;

                  if (source == 'gold' || source == 'goldnext') {
                    bid = !Functions.isNumeric(item['Bid'])
                        ? '--'
                        : (Functions.isDecimal(item['Bid'])
                                ? double.parse(item['Bid'])
                                : int.parse(item['Bid'])) +
                            goldBuyPremium +
                            buyPremium;
                    ask = !Functions.isNumeric(item['Ask'])
                        ? '--'
                        : (Functions.isDecimal(item['Ask'])
                                ? double.parse(item['Ask'])
                                : int.parse(item['Ask'])) +
                            goldSellPremium +
                            sellPremium;
                    high = !Functions.isNumeric(item['High'])
                        ? '--'
                        : (Functions.isDecimal(item['High'])
                                ? double.parse(item['High'])
                                : int.parse(item['High'])) +
                            goldSellPremium +
                            sellPremium;
                    low = !Functions.isNumeric(item['Low'])
                        ? '--'
                        : (Functions.isDecimal(item['Low'])
                                ? double.parse(item['Low'])
                                : int.parse(item['Low'])) +
                            goldBuyPremium +
                            buyPremium;

                    premSell = !Functions.isNumeric(item['Premium'])
                        ? '--'
                        : (Functions.isDecimal(item['Premium'])
                                ? double.parse(item['Premium'])
                                : int.parse(item['Premium'])) +
                            sellPremium +
                            goldSellPremium;
                    premBuy = !Functions.isNumeric(item['PremiumBuy'])
                        ? '--'
                        : (Functions.isDecimal(item['PremiumBuy'])
                                ? double.parse(item['PremiumBuy'])
                                : int.parse(item['PremiumBuy'])) +
                            buyPremium +
                            goldBuyPremium;
                  } else {
                    bid = !Functions.isNumeric(item['Bid'])
                        ? '--'
                        : (Functions.isDecimal(item['Bid'])
                                ? double.parse(item['Bid'])
                                : int.parse(item['Bid'])) +
                            silverBuyPremium +
                            buyPremium;
                    ask = !Functions.isNumeric(item['Ask'])
                        ? '--'
                        : (Functions.isDecimal(item['Ask'])
                                ? double.parse(item['Ask'])
                                : int.parse(item['Ask'])) +
                            silverSellPremium +
                            sellPremium;
                    high = !Functions.isNumeric(item['High'])
                        ? '--'
                        : (Functions.isDecimal(item['High'])
                                ? double.parse(item['High'])
                                : int.parse(item['High'])) +
                            silverSellPremium +
                            sellPremium;
                    low = !Functions.isNumeric(item['Low'])
                        ? '--'
                        : (Functions.isDecimal(item['Low'])
                                ? double.parse(item['Low'])
                                : int.parse(item['Low'])) +
                            silverBuyPremium +
                            sellPremium;
                    premSell = !Functions.isNumeric(item['Premium'])
                        ? '--'
                        : (Functions.isDecimal(item['Premium'])
                                ? double.parse(item['Premium'])
                                : int.parse(item['Premium'])) +
                            sellPremium +
                            silverSellPremium;
                    premBuy = !Functions.isNumeric(item['PremiumBuy'])
                        ? '--'
                        : (Functions.isDecimal(item['PremiumBuy'])
                                ? double.parse(item['PremiumBuy'])
                                : int.parse(item['PremiumBuy'])) +
                            buyPremium +
                            silverBuyPremium;
                  }
                  liveRate.add(Liverate(
                    symbolId: item['SymbolId'],
                    symbol: item["Symbol"],
                    source: item["Source"],
                    client: item["Client"],
                    stock: item["Stock"],
                    isDisplay: item["IsDisplay"],
                    isDisplayTrading: item["IsDisplayTrading"],
                    isDisplayTerminal: item["IsDisplayTerminal"],
                    grams: item["Grams"],
                    cityId: item["cityId"],
                    isDisplayWidget: item["IsDisplayWidget"],
                    description: item["Description"],
                    displayRateType: item["DisplayRateType"],
                    symbolType: item["SymbolType"],
                    premium: premSell.toString(),
                    premiumBuy: premBuy.toString(),
                    time: item["Time"],
                    mcxBid: item["McxBid"],
                    mcxAsk: item["McxAsk"],
                    diff: item["Diff"],
                    bid: bid.toString(),
                    ask: ask.toString(),
                    purity: item["Purity"],
                    high: high.toString(),
                    low: low.toString(),
                  ));
                }
              }
            }
          }
        }
        provider.addLiveRateData(liveRate);
      } else {
        for (var item in responseData) {
          if (item['IsDisplay'] == 'True') {
            liveRate.add(Liverate.fromJson(item));
          }
        }
        provider.addLiveRateData(liveRate);
      }
      _addToControllerIfNotClosed(
          liveRate, NotifySocketUpdate.controllerMainData);
    });

    socket.on('Accountdetails', (accountdetails) {
      debugPrint('Account-details-------------------------------------');

      ProfileDetails account = ProfileDetails.fromJson(accountdetails);
      if (account.status == false) {
        shared.setIsLogin(false);
        Constants.isLogin = false;
      } else {
        Constants.loginName = account.name!;
        provider.addAccountData(account);
        _addToControllerIfNotClosed(
            accountdetails, NotifySocketUpdate.controllerAccountDetails);
      }
    });

    socket.on('Orders', (orders) {
      _addToControllerIfNotClosed(
          orders, NotifySocketUpdate.controllerOrderDetails);

      debugPrint('Orders-------------------------------------------' + orders);
    });

    socket.on('GroupDetails', (groupDetails) {
      for (var item in groupDetails) {
        if (item is List) {
          List<GroupDetailsBuySell> premiumData = [];
          List<GroupDetailsDropDown> dropDown = [];
          for (var item in groupDetails[0]) {
            premiumData.add(GroupDetailsBuySell.fromJson(item));
          }
          for (var item in groupDetails[1]) {
            dropDown.add(GroupDetailsDropDown.fromJson(item));
          }

          socket.emit("GroupDetails",
              "${Constants.projectName}_${premiumData[0].groupName!}");

          provider.addPremiumData(premiumData);
          provider.addDropDownData(dropDown);
          _addToControllerIfNotClosed(
              groupDetails[1], NotifySocketUpdate.dropDown);
        } else if (item is Map) {
          provider.addPremiumData([]);
          provider.addDropDownData([]);
          debugPrint('Map');
        }
      }

      debugPrint(
          "GroupDetails-----------------------------------$groupDetails");
    });

    socket.on('checklogin', (isLogin) {
      if (isLogin == false) {
        shared.setIsLogin(false);
        Constants.isLogin = false;
      }
    });

    // socket.on('coinrate', (response) {
    //   List<Coins> coinData = [];
    //   if (response['CoinRate']!=null) {
    //     for (var item in response['CoinRate']) {
    //       coinData.add(Coins.fromJson(item));
    //     }
    //   }
    //   provider.addCoinData(coinData);
    //   _addToControllerIfNotClosed(coinData, NotifySocketUpdate.controllerCoin);
    //   debugPrint('coinrate' + response.toString());
    // });

    socket.onConnectError((err) => debugPrint('$err'));
    socket.onError((err) {
      debugPrint('$err');
    });
  }

  static void _addToControllerIfNotClosed<T>(
      T data, StreamController<T>? controller) {
    if (controller != null && !controller.isClosed) {
      controller.sink.add(data);
    }
  }
}
