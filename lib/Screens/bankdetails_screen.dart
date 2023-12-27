// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:terminal_demo/Constants/images.dart';

import '../Constants/app_colors.dart';
import '../Constants/constant.dart';
import '../Functions.dart';
import '../Models/CommenRequestModel.dart';
import '../Services/bankdetails_service.dart';
import '../Widgets/custom_text.dart';

class BankDetail_Screen extends StatefulWidget {
  const BankDetail_Screen({super.key});

  @override
  State<BankDetail_Screen> createState() => _BankDetail_ScreenState();
}

class _BankDetail_ScreenState extends State<BankDetail_Screen> with AutomaticKeepAliveClientMixin<BankDetail_Screen>{

  @override
  bool get wantKeepAlive => true;

  bool isLoading = true;
  late List<BankList> bankList = [];
  BankService bankService = BankService();
  bool _isMounted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isMounted = true;

    callBankDetailsApi();
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
      child: bankList.isEmpty
          ?  Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: 'Bank Not Available',
                    textColor: AppColors.textColor,
                    size: 20.0,
                    fontWeight: FontWeight.normal,
                  ),
                  Visibility(
                    visible: isLoading,
                    child: SizedBox(
                      height: 15.0,
                      width: 15,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: bankList.length,
              itemBuilder: (builder, index) {
                return buildBankDetailContainer(size, bankList[index]);
              },
            ),
    );
  }

  Widget buildBankDetailContainer(Size size, BankList bankList) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: AppColors.defaultColor,
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: AppColors.primaryColor, width: 1.5),
        ),
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: size.height * .1,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    bankList.bankLogo!.isNotEmpty ? bankList.bankLogo! : '',
                fit: BoxFit.contain,
                errorWidget: (context, url, error) {
                  return Image.asset(AppImagePath.splashImage);
                },
                placeholder: (context, url) {
                  return const CupertinoActivityIndicator();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'Bank Name',
                      textColor: AppColors.textColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    SizedBox(height: 8),
                    CustomText(
                      text: 'Account Name',
                      textColor: AppColors.textColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    SizedBox(height: 8),
                    CustomText(
                      text: 'Account No',
                      textColor: AppColors.textColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    SizedBox(height: 8),
                    CustomText(
                      text: 'IFSC Code',
                      textColor: AppColors.textColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                    SizedBox(height: 8),
                    CustomText(
                      text: 'Branch Name',
                      textColor: AppColors.textColor,
                      size: 14.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomText(
                        text: ':: ${bankList.bankName}',
                        textColor: AppColors.textColor,
                        size: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: ':: ${bankList.accountName}',
                        textColor: AppColors.textColor,
                        size: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: ':: ${bankList.accountNo}',
                        textColor: AppColors.textColor,
                        size: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: ':: ${bankList.ifsc}',
                        textColor: AppColors.textColor,
                        size: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                      SizedBox(height: 8),
                      CustomText(
                        text: ':: ${bankList.branchName}',
                        textColor: AppColors.textColor,
                        size: 14.0,
                        fontWeight: FontWeight.normal,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void callBankDetailsApi() {
    Functions.checkConnectivity().then((isConnected) {
      if (isConnected) {
        bankService.bankDet(int.parse(Constants.clientId)).then((response) {
          if (response.data != '[]') {

            List<dynamic> dataList = jsonDecode(response.data!);
            if (_isMounted) {
              setState(() {
                isLoading = false;
                bankList =
                    dataList.map((item) => BankList.fromJson(item)).toList();
              });
            }
            // setState(() {
            //   isLoading = false;
            //   bankList =
            //       dataList.map((item) => BankList.fromJson(item)).toList();
            // });
            // Functions.showToast(response.data!);
          } else {
            if (_isMounted) {
              setState(() {
                bankList = [];
                isLoading = false;
              });
            }
            // setState(() {
            //   bankList = [];
            //   isLoading = false;
            // });
          }
        });
      } else {
        if (_isMounted) {
          setState(() {
            isLoading = false;
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
