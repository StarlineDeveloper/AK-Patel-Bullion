// To parse this JSON data, do
//
//     final liverate = liverateFromJson(jsonString);

import 'dart:convert';

import 'package:flutter/material.dart';

import '../Constants/app_colors.dart';

Liverate liverateFromJson(String str) => Liverate.fromJson(json.decode(str));

String liverateToJson(Liverate data) => json.encode(data.toJson());

class Liverate {
  Liverate({
    this.symbolId,
    this.symbol,
    this.source,
    this.client,
    this.stock,
    this.isDisplay,
    this.isDisplayTrading,
    this.isDisplayTerminal,
    this.grams,
    this.cityId,
    this.isDisplayWidget,
    this.description,
    this.displayRateType,
    this.symbolType,
    this.premium,
    this.premiumBuy,
    this.time,
    this.mcxBid,
    this.mcxAsk,
    this.diff,
    this.bid,
    this.ask,
    this.purity,
    this.high,
    this.low,
    this.askBGColor = AppColors.defaultColor,
    this.askTextColor = AppColors.secondaryTextColor,
    this.bidBGColor = AppColors.defaultColor,
    this.bidTextColor = AppColors.secondaryTextColor,
    this.askTradeBGColor = AppColors.primaryColor,
    this.askTradeTextColor = AppColors.textColor,
    this.bidTradeBGColor = AppColors.primaryColor,
    this.bidTradeTextColor = AppColors.textColor,
  });

  String? symbolId;
  String? symbol;
  String? source;
  String? client;
  String? stock;
  String? isDisplay;
  dynamic isDisplayTrading;
  dynamic isDisplayTerminal;
  String? grams;
  String? cityId;
  dynamic isDisplayWidget;
  String? description;
  String? displayRateType;
  String? symbolType;
  String? premium;
  String? premiumBuy;
  String? time;
  String? mcxBid;
  String? mcxAsk;
  dynamic diff;
  dynamic bid;
  dynamic ask;
  String? purity;
  dynamic high;
  dynamic low;
  Color askBGColor;
  Color askTextColor;
  Color bidBGColor;
  Color bidTextColor;
  Color askTradeBGColor;
  Color askTradeTextColor;
  Color bidTradeBGColor;
  Color bidTradeTextColor;

  factory Liverate.fromJson(Map<String, dynamic> json) => Liverate(
        symbolId: json["SymbolId"],
        symbol: json["Symbol"],
        source: json["Source"],
        client: json["Client"],
        stock: json["Stock"],
        isDisplay: json["IsDisplay"],
        isDisplayTrading: json["IsDisplayTrading"],
        isDisplayTerminal: json["IsDisplayTerminal"],
        grams: json["Grams"],
        cityId: json["cityId"],
        isDisplayWidget: json["IsDisplayWidget"],
        description: json["Description"],
        displayRateType: json["DisplayRateType"],
        symbolType: json["SymbolType"],
        premium: json["Premium"],
        premiumBuy: json["PremiumBuy"],
        time: json["Time"],
        mcxBid: json["McxBid"],
        mcxAsk: json["McxAsk"],
        diff: json["Diff"],
        bid: json["Bid"],
        ask: json["Ask"],
        purity: json["Purity"],
        high: json["High"],
        low: json["Low"],
      );

  Map<String, dynamic> toJson() => {
        "SymbolId": symbolId,
        "Symbol": symbol,
        "Source": source,
        "Client": client,
        "Stock": stock,
        "IsDisplay": isDisplay,
        "IsDisplayTrading": isDisplayTrading,
        "IsDisplayTerminal": isDisplayTerminal,
        "Grams": grams,
        "cityId": cityId,
        "IsDisplayWidget": isDisplayWidget,
        "Description": description,
        "DisplayRateType": displayRateType,
        "SymbolType": symbolType,
        "Premium": premium,
        "PremiumBuy": premiumBuy,
        "Time": time,
        "McxBid": mcxBid,
        "McxAsk": mcxAsk,
        "Diff": diff,
        "Bid": bid,
        "Ask": ask,
        "Purity": purity,
        "High": high,
        "Low": low,
      };
}
