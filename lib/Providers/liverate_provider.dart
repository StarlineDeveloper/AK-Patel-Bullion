import 'package:flutter/material.dart';
import 'package:terminal_demo/Models/CommenRequestModel.dart';
import '../Models/client_header.dart';
import '../Models/comex_data_model.dart';
import '../Models/liverate.dart';
import '../Models/reference_data.dart';
import '../Models/reference_data_rate.dart';

// class LiverateProvider extends ChangeNotifier {
//   List<ClientHeaderData> clientHeaderData = [];
//   List<ReferenceData> referenceData = [];
//   List<ReferenceDataRate> referenceDataRate = [];
//   List<ComexDataModel> comexData = [];
//   List<ComexDataModel> futureData = [];
//   List<Liverate> liveRates = [];
//   List<Liverate> liveRatesTerminal = [];
//   List<OpenOrderElement> openOrder = [];
//   List<OpenOrderElement> penOrder = [];
//   List<OpenOrderElement> reqOrder = [];
//   List<OpenOrderElement> closerder = [];
//   List<OpenOrderElement> deleteOrder = [];
//   List<GroupDetailsBuySell> groopDetailBuySell = [];
//   List<GroupDetailsDropDown> groopDetailDropDown = [];
//   ProfileDetails accountDetails = ProfileDetails();
//
//   List<ClientHeaderData> get clientHeaderDataList => clientHeaderData;
//
//   List<ReferenceData> get referenceDataList => referenceData;
//
//   List<OpenOrderElement> get openOrderList => openOrder;
//
//   List<OpenOrderElement> get penOrderList => penOrder;
//
//   List<OpenOrderElement> get reqOrderList => reqOrder;
//
//   String get bannerImage => clientHeaderData[0].bannerApp1 ?? '';
//
//   List<Liverate> get liveRatesList => liveRates;
//
//   List<Liverate> get liveRatesListTerminal => liveRatesTerminal;
//
//   List<GroupDetailsBuySell> get grpBuySell => groopDetailBuySell;
//
// //Live rate bullion add and get
//   void addLiveRateData(List<Liverate> data) {
//     liveRates = [];
//     liveRates = data;
//     notifyListeners();
//   }
//
//   List<Liverate> getLiveRateData() {
//     return liveRates.isEmpty ? [] : liveRates;
//   }
//
// //Live rate terminal add and get
// //   void addLiveRateTerminalData(List<Liverate> data) {
// //     liveRatesTerminal = [];
// //     liveRatesTerminal = data;
// //     notifyListeners();
// //   }
// //
// //   List<Liverate> getLiveRateTerminalData() {
// //     return liveRatesTerminal.isEmpty ? [] : liveRatesTerminal;
// //   }
//
// //ClientHeaderData add and get
//   void addClientHeaderData(List<ClientHeaderData> data) {
//     clientHeaderData = [];
//     clientHeaderData = data;
//     notifyListeners();
//   }
//
//   ClientHeaderData getClientHeaderData() {
//     return clientHeaderData.isEmpty
//         ? ClientHeaderData()
//         : clientHeaderData.first;
//   }
//
// //Account details get and add
//   void addAccountData(ProfileDetails data) {
//     accountDetails = ProfileDetails();
//     accountDetails = data;
//     notifyListeners();
//   }
//
//   ProfileDetails getAccountData() {
//     return accountDetails ?? ProfileDetails();
//   }
//
//   void replaceData(List<ClientHeaderData> data) {
//     clientHeaderData = data;
//     notifyListeners();
//   }
//
// //ReferenceData add and get
//   void addReferenceData(List<ReferenceData> data) {
//     referenceData = [];
//     referenceData = data;
//     notifyListeners();
//   }
//
//   List<ReferenceData> getReferenceData() {
//     return referenceData.isEmpty ? [] : referenceData;
//   }
//
//   void replaceReferenceData(List<ReferenceData> data) {
//     referenceData = data;
//     notifyListeners();
//   }
//
//   void addReferenceDataRate(List<ReferenceDataRate> data) {
//     referenceDataRate = [];
//     referenceDataRate = data;
//     notifyListeners();
//   }
//
// //ReferenceDataRate add and get
//   List<ReferenceDataRate> getReferenceDataRate() {
//     return referenceDataRate.isEmpty ? [] : referenceDataRate;
//   }
//
//   void replaceReferenceDataRate(List<ReferenceDataRate> data) {
//     referenceDataRate = data;
//     notifyListeners();
//   }
//
// //ComexData add and get
//   void addComexData(List<ComexDataModel> data) {
//     comexData = [];
//     comexData = data;
//     notifyListeners();
//   }
//
//   List<ComexDataModel> getComexData() {
//     return comexData.isEmpty ? [] : comexData;
//   }
//
// //FutureData add and get
//   void addFutureData(List<ComexDataModel> data) {
//     futureData = [];
//     futureData = data;
//     notifyListeners();
//   }
//
//   List<ComexDataModel> getFutureData() {
//     return futureData.isEmpty ? [] : futureData;
//   }
//
//   //Open Order add and get
//   void addOpenOrder(List<OpenOrderElement> data) {
//     openOrder = [];
//     openOrder = data;
//     notifyListeners();
//   }
//
//   List<OpenOrderElement> getOpenOrder() {
//     return openOrder.isEmpty ? [] : openOrder;
//   }
//
//   //Pending Order add and get
//   void addPendingOrder(List<OpenOrderElement> data) {
//     penOrder = [];
//     penOrder = data;
//     notifyListeners();
//   }
//
//   List<OpenOrderElement> getPendingOrder() {
//     return penOrder.isEmpty ? [] : penOrder;
//   }
//
//   //Request Order add and get
//   void addRequestOrder(List<OpenOrderElement> data) {
//     reqOrder = [];
//     reqOrder = data;
//     notifyListeners();
//   }
//
//   List<OpenOrderElement> getRequestOrder() {
//     return reqOrder.isEmpty ? [] : reqOrder;
//   }
//
//   //Close Order add and get
//   void addCloseOrder(List<OpenOrderElement> data) {
//     closerder = [];
//     closerder = data;
//     notifyListeners();
//   }
//
//   List<OpenOrderElement> getCloseOrder() {
//     return closerder.isEmpty ? [] : closerder;
//   }
//
//   //Delete Order add and get
//   void addDeleteOrder(List<OpenOrderElement> data) {
//     deleteOrder = [];
//     deleteOrder = data;
//     notifyListeners();
//   }
//
//   List<OpenOrderElement> getDeleteOrder() {
//     return deleteOrder.isEmpty ? [] : deleteOrder;
//   }
//
//   //group details buy sell
//   void addPremiumData(List<GroupDetailsBuySell> data) {
//     groopDetailBuySell = [];
//     groopDetailBuySell = data;
//     notifyListeners();
//   }
//
//   List<GroupDetailsBuySell> getPremiumData() {
//     return groopDetailBuySell.isEmpty ? [] : groopDetailBuySell;
//   }
//
//   //drop down List
//   void addDropDownData(List<GroupDetailsDropDown> data) {
//     groopDetailDropDown = [];
//     groopDetailDropDown = data;
//     notifyListeners();
//   }
//
//   List<GroupDetailsDropDown> getDropDownData() {
//     return groopDetailDropDown.isEmpty ? [] : groopDetailDropDown;
//   }
// }
class LiverateProvider extends ChangeNotifier {
  // Lists for data storage
  List<ClientHeaderData> clientHeaderData = [];
  List<ReferenceData> referenceData = [];
  List<ReferenceDataRate> referenceDataRate = [];
  List<ComexDataModel> comexData = [];
  List<ComexDataModel> futureData = [];
  List<ComexDataModel> nextData = [];
  List<Liverate> liveRates = [];
  List<Liverate> liveRatesTerminal = [];
  List<OpenOrderElement> openOrder = [];
  List<OpenOrderElement> penOrder = [];
  List<OpenOrderElement> reqOrder = [];
  List<OpenOrderElement> closerder = [];
  List<OpenOrderElement> deleteOrder = [];
  List<GroupDetailsBuySell> groopDetailBuySell = [];
  List<Coins>  coins= [];
  List<GroupDetailsDropDown> groopDetailDropDown = [];
  ProfileDetails accountDetails = ProfileDetails();

  // Getters for data lists
  List<ClientHeaderData> get clientHeaderDataList => clientHeaderData;
  List<ReferenceData> get referenceDataList => referenceData;
  List<OpenOrderElement> get openOrderList => openOrder;
  List<OpenOrderElement> get penOrderList => penOrder;
  List<OpenOrderElement> get reqOrderList => reqOrder;
  String? get bannerImage => clientHeaderData.isNotEmpty ? clientHeaderData[0].bannerApp1 : '';

  List<Liverate> get liveRatesList => liveRates;
  List<Liverate> get liveRatesListTerminal => liveRatesTerminal;
  List<GroupDetailsBuySell> get grpBuySell => groopDetailBuySell;
  List<Coins> get coinData => coins;

  // Generic function to add data to lists
  void addDataToList<T>(List<T> list, List<T> data) {
    list.clear();
    list.addAll(data);
    notifyListeners();
  }

  // Generic function to get data from lists
  List<T> getDataFromList<T>(List<T> list) {
    return list.isEmpty ? [] : List<T>.from(list);
  }

  // Add and get live rate data
  void addLiveRateData(List<Liverate> data) {
    addDataToList(liveRates, data);
  }

  List<Liverate> getLiveRateData() {
    return getDataFromList(liveRates);
  }

  // Add and get client header data
  void addClientHeaderData(List<ClientHeaderData> data) {
    addDataToList(clientHeaderData, data);
  }

  ClientHeaderData getClientHeaderData() {
    return clientHeaderData.isNotEmpty ? clientHeaderData.first : ClientHeaderData();
  }

  // Add and get account details
  void addAccountData(ProfileDetails data) {
    accountDetails = ProfileDetails();
    accountDetails = data;
    notifyListeners();
  }

  ProfileDetails getAccountData() {
    return accountDetails ?? ProfileDetails();
  }

  // Add and get reference data
  void addReferenceData(List<ReferenceData> data) {
    addDataToList(referenceData, data);
  }

  List<ReferenceData> getReferenceData() {
    return getDataFromList(referenceData);
  }

  // Add and get reference data rate
  void addReferenceDataRate(List<ReferenceDataRate> data) {
    addDataToList(referenceDataRate, data);
  }

  List<ReferenceDataRate> getReferenceDataRate() {
    return getDataFromList(referenceDataRate);
  }

  // Add and get Comex data
  void addComexData(List<ComexDataModel> data) {
    addDataToList(comexData, data);
  }

  List<ComexDataModel> getComexData() {
    return getDataFromList(comexData);
  }

  // Add and get future data
  void addFutureData(List<ComexDataModel> data) {
    addDataToList(futureData, data);
  }

  List<ComexDataModel> getFutureData() {
    return getDataFromList(futureData);
  }
  // Add and get Next data
  void addNextData(List<ComexDataModel> data) {
    addDataToList(nextData, data);
  }

  List<ComexDataModel> getNextData() {
    return getDataFromList(nextData);
  }

  // Add and get open order data
  void addOpenOrder(List<OpenOrderElement> data) {
    addDataToList(openOrder, data);
  }

  List<OpenOrderElement> getOpenOrder() {
    return getDataFromList(openOrder);
  }

  // Add and get pending order data
  void addPendingOrder(List<OpenOrderElement> data) {
    addDataToList(penOrder, data);
  }

  List<OpenOrderElement> getPendingOrder() {
    return getDataFromList(penOrder);
  }

  // Add and get request order data
  void addRequestOrder(List<OpenOrderElement> data) {
    addDataToList(reqOrder, data);
  }

  List<OpenOrderElement> getRequestOrder() {
    return getDataFromList(reqOrder);
  }

  // Add and get close order data
  void addCloseOrder(List<OpenOrderElement> data) {
    addDataToList(closerder, data);
  }

  List<OpenOrderElement> getCloseOrder() {
    return getDataFromList(closerder);
  }

  // Add and get delete order data
  void addDeleteOrder(List<OpenOrderElement> data) {
    addDataToList(deleteOrder, data);
  }

  List<OpenOrderElement> getDeleteOrder() {
    return getDataFromList(deleteOrder);
  }

  // Add and get premium data
  void addPremiumData(List<GroupDetailsBuySell> data) {
    addDataToList(groopDetailBuySell, data);
  }

  List<GroupDetailsBuySell> getPremiumData() {
    return getDataFromList(groopDetailBuySell);
  }

  // Add and get drop-down data
  void addDropDownData(List<GroupDetailsDropDown> data) {
    addDataToList(groopDetailDropDown, data);
  }

  List<GroupDetailsDropDown> getDropDownData() {
    return getDataFromList(groopDetailDropDown);
  }
  // Add and get coin data
  void addCoinData(List<Coins> data) {
    addDataToList(coins, data);
  }

  List<Coins> getCoinData() {
    return getDataFromList(coins);
  }

}

