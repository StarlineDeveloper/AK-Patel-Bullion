// ignore_for_file: camel_case_types, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terminal_demo/Constants/constant.dart';
import 'package:terminal_demo/Services/update_service.dart';

import '../Constants/app_colors.dart';
import '../Functions.dart';
import '../Models/CommenRequestModel.dart';
import '../Widgets/custom_text.dart';

class Update_Screen extends StatefulWidget {
  const Update_Screen({super.key});

  @override
  State<Update_Screen> createState() => _Update_ScreenState();
}

class _Update_ScreenState extends State<Update_Screen> {
  String selectedFromDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String selectedToDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  bool isLoading = false;
  bool isLoadingProg = true;
  late List<UpdateList> updateList = [];
  UpdateService updateService = UpdateService();
  bool _isMounted = false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;

    callUpdateApi();
  }
  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
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
                            selectedFromDate =
                                DateFormat('dd/MM/yyyy').format(selectedDate);
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
                        selectedFromDate,
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
                            selectedToDate =
                                DateFormat('dd/MM/yyyy').format(selectedDate);
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
                        selectedToDate,
                        style: const TextStyle(
                            color: AppColors.textColor, fontSize: 13.0),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      debugPrint(
                          "startDate->$selectedFromDate/endDate->$selectedToDate");
                      setState(() {
                        isLoading = true;
                      });
                      callUpdateApi();
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
                            visible: !isLoading,
                            child: CustomText(
                              text: 'Search',
                              size: 15.0,
                              fontWeight: FontWeight.bold,
                              textColor: AppColors.defaultColor,
                              align: TextAlign.start,
                            ),
                          ),
                          Visibility(
                            visible: isLoading,
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
              )),
          const Divider(
            color: AppColors.primaryColor,
            thickness: 1,
          ),
          Expanded(
            child: updateList.isEmpty
                ?  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        CustomText(
                          text: 'Updates Not Available',
                          textColor: AppColors.textColor,
                          size: 20.0,
                          fontWeight: FontWeight.normal,
                        ),
                        Visibility(
                          visible: isLoadingProg,
                          child: SizedBox(
                            height: 15.0,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: updateList.length,
                    itemBuilder: (builder, index) {
                      return buildUpdateContainer(size, updateList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  buildUpdateContainer(Size size, UpdateList updateList) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          border: Border.all(
            color: AppColors.defaultColor,
          ),
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
        ),
        child: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      text: updateList.day.toString(),
                      textColor: AppColors.defaultColor,
                      size: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text: "${updateList.month} ${updateList.year}",
                      textColor: AppColors.defaultColor,
                      size: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ), //Container
            ),
            Container(
              color: AppColors.defaultColor,
              height: 60,
              width: 1.5,
            ),
            // Flexible(
            //   flex: 1,
            //   fit: FlexFit.loose,
            //   child:  Padding(
            //     padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            //     child: VerticalDivider(
            //       color: AppColors.defaultColor,
            //       thickness: 1,
            //
            //     ),
            //   ),//Container
            // ),
            Flexible(
              flex: 3,
              fit: FlexFit.loose,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: updateList.description!.isNotEmpty
                          ? updateList.description!
                          : '',
                      textColor: AppColors.defaultColor,
                      size: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 10),
                    CustomText(
                      text: updateList.time!.isNotEmpty ? updateList.time! : '',
                      textColor: AppColors.defaultColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    SizedBox(height: 10),
                    CustomText(
                      text: updateList.sortnews!.isNotEmpty
                          ? updateList.sortnews!
                          : '',
                      textColor: AppColors.defaultColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ],
                ),
              ), //Container
            )
          ],
        ),
      ),
    );
  }

  void callUpdateApi() {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        var objVariable = updateToJson(UpdateRequest(
            startDate: selectedFromDate,
            endDate: selectedToDate,
            client: Constants.clientId));
        updateService.update(objVariable).then((response) {
          if (response.data != '[]') {
            List<dynamic> dataList = jsonDecode(response.data!);
            if (_isMounted) {
              setState(() {
                isLoading = false;
                isLoadingProg=false;
                updateList =
                    dataList.map((item) => UpdateList.fromJson(item)).toList();
              });
            }
            // setState(() {
            //   isLoading = false;
            //   updateList =
            //       dataList.map((item) => UpdateList.fromJson(item)).toList();
            // });
          } else {
            if (_isMounted) {
              setState(() {
                updateList =[];
                isLoading = false;
                isLoadingProg=false;

              });
            }
            // setState(() {
            //   updateList =[];
            //   isLoading = false;
            // });
          }
        });
      } else {
        if (_isMounted) {
          setState(() {
            // updateList =[];
            isLoading = false;
            isLoadingProg=false;

          });
        }
        // setState(() {
        //   isLoading = false;
        // });
        Functions.showToast(Constants.noInternet);
      }
    });
  }
}
