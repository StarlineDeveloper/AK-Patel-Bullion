import 'dart:ui';

import '../Constants/app_colors.dart';

class ComexDataModel {
  String? symbolName;
  String? bid;
  String? ask;
  String? high;
  String? low;
  String? source;
  bool? isDisplay;
  Color askBGColor;
  Color askTextColor;
  Color bidBGColor;
  Color bidTextColor;

  ComexDataModel({
    this.symbolName,
    this.bid,
    this.ask,
    this.high,
    this.low,
    this.source,
    this.isDisplay,
    this.askBGColor = AppColors.primaryColor,
    this.askTextColor = AppColors.defaultColor,
    this.bidBGColor = AppColors.primaryColor,
    this.bidTextColor = AppColors.defaultColor,
  });
}
