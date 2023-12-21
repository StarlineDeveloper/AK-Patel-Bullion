// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';

class DialogUtil {
  static final DialogUtil _instance = DialogUtil.internal();

  DialogUtil.internal();

  factory DialogUtil() => _instance;

  static void showAlertDialog(BuildContext context,
      {required String content,
      required String title,
      required String okBtnText,
      required String cancelBtnText,
      Function? okBtnFunction}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        var size = MediaQuery.of(context).size;
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0)), //this right here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: size.width * 0.11,
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
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                          color: AppColors.defaultColor)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(content,
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
                    child: Text(okBtnText,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                            color: AppColors.defaultColor)),
                  ),
                  onTap: () {
                    // okBtnFunction!();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showConfirmDialog(BuildContext context,
      {required String title,
      required String content,
      required okBtnText,
      required cancelBtnText,
      required Function okBtnFunctionConfirm,
      required bool isVisible}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        var size = MediaQuery.of(context).size;
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)), //this right here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: size.width * 0.11,
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
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                          color: AppColors.defaultColor)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(content,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15.0,
                        color: AppColors.textColor)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        child: Container(
                          margin: EdgeInsets.only(right: 5),
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          alignment: Alignment.center,
                          child: Stack(children: [
                            Visibility(
                              visible: !isVisible,
                              child: Text(okBtnText,
                                  style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 15.0,
                                      color: AppColors.defaultColor)),
                            ),
                            Visibility(
                              visible: isVisible,
                              child: SizedBox(
                                height: 20.0,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.defaultColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ]),
                        ),
                        onTap: () {
                          okBtnFunctionConfirm();
                        },
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        child: Container(
                          margin: EdgeInsets.only(left: 5),
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: Alignment.center,
                          child: Text(cancelBtnText,
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 15.0,
                                  color: AppColors.defaultColor)),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
