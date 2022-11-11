import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/order_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetail extends StatefulWidget {
  final Order_Model? model;
  final Function? updateHome;

  const OrderDetail({
    Key? key,
    this.model,
    this.updateHome,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<String> statusList = [
    PLACED,
    PROCESSED,
    SHIPED,
    DELIVERD,
    CANCLED,
    RETURNED,
    WAITING
  ];
  bool? _isCancleable, _isReturnable, _isLoading = true;
  bool _isProgress = false;
  String? curStatus;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  TextEditingController? otpC;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.model!.itemList!.length; i++) {
      widget.model!.itemList![i].curSelected =
          widget.model!.itemList![i].status;
    }

    if (widget.model!.payMethod == "Bank Transfer") {
      statusList.removeWhere((element) => element == PLACED);
    }

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, TRY_AGAIN_INT_LBL),
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder: (BuildContext context) => super.widget,
                        ),
                      );
                    } else {
                      await buttonController!.reverse();
                      setState(
                        () {},
                      );
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    Order_Model model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;

    if (model.listStatus!.contains(PLACED)) {
      pDate = model.listDate![model.listStatus!.indexOf(PLACED)];

      if (pDate != "") {
        List d = pDate!.split(" ");
        pDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(PROCESSED)) {
      prDate = model.listDate![model.listStatus!.indexOf(PROCESSED)];
      if (prDate != "") {
        List d = prDate!.split(" ");
        prDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(SHIPED)) {
      sDate = model.listDate![model.listStatus!.indexOf(SHIPED)];
      if (sDate != "") {
        List d = sDate!.split(" ");
        sDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(DELIVERD)) {
      dDate = model.listDate![model.listStatus!.indexOf(DELIVERD)];
      if (dDate != "") {
        List d = dDate!.split(" ");
        dDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(CANCLED)) {
      cDate = model.listDate![model.listStatus!.indexOf(CANCLED)];
      if (cDate != "") {
        List d = cDate!.split(" ");
        cDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus!.contains(RETURNED)) {
      rDate = model.listDate![model.listStatus!.indexOf(RETURNED)];
      if (rDate != "") {
        List d = rDate!.split(" ");
        rDate = d[0] + "\n" + d[1];
      }
    }

    _isCancleable = model.isCancleable == "1" ? true : false;
    _isReturnable = model.isReturnable == "1" ? true : false;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: lightWhite,
      appBar: getAppBar(
        getTranslated(context, ORDER_DETAIL)!,
        context,
      ),
      body: _isNetworkAvail
          ? Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Card(
                                elevation: 0,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            getTranslated(
                                                    context, ORDER_ID_LBL)! +
                                                " - ${model.id!}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                  color: lightBlack2,
                                                ),
                                          ),
                                          Text(
                                            model.orderDate!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2!
                                                .copyWith(
                                                  color: lightBlack2,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        getTranslated(context, PAYMENT_MTHD)! +
                                            " - ${model.payMethod!}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                              color: lightBlack2,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              model.delDate!.isNotEmpty
                                  ? Card(
                                      elevation: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          getTranslated(
                                                  context, PREFER_DATE_TIME)! +
                                              ": ${model.delDate!} - ${model.delTime!}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(color: lightBlack2),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: model.itemList!.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, i) {
                                  OrderItem orderItem = model.itemList![i];
                                  return productItem(orderItem, model, i);
                                },
                              ),
                              shippingDetails(),
                              priceDetails(),
                              SizedBox(
                                height: 20,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                showCircularProgress(_isProgress, primary),
              ],
            )
          : noInternet(context),
    );
  }

  otpDialog(
    String? curSelected,
    String? otp,
    String? id,
    bool item,
    int index,
  ) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStater) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0.0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
              ),
            ),
            content: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 2.0),
                    child: Text(
                      getTranslated(context, OTP_LBL)!,
                      style:
                          Theme.of(this.context).textTheme.subtitle1!.copyWith(
                                color: fontColor,
                              ),
                    ),
                  ),
                  const Divider(color: lightBlack),
                  Form(
                    key: _formkey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context, FIELD_REQUIRED)!;
                              } else if (value.trim() != otp) {
                                return getTranslated(context, OTPERROR);
                              } else {
                                return null;
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              hintText: getTranslated(context, OTP_ENTER)!,
                              hintStyle: Theme.of(this.context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    color: lightBlack,
                                    fontWeight: FontWeight.normal,
                                  ),
                            ),
                            controller: otpC,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  getTranslated(context, CANCEL)!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: lightBlack,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(
                  getTranslated(context, SEND_LBL)!,
                  style: Theme.of(this.context).textTheme.subtitle2!.copyWith(
                        color: fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                onPressed: () {
                  final form = _formkey.currentState!;
                  if (form.validate()) {
                    form.save();
                    setState(
                      () {
                        Navigator.pop(context);
                      },
                    );
                    updateOrder(
                      curSelected,
                      id,
                      item,
                      index,
                      otp,
                    );
                  }
                },
              )
            ],
          );
        });
      },
    );
  }

  _launchMap(lat, lng) async {
    var url = '';

    if (Platform.isAndroid) {
      url =
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate";
    } else {
      url =
          "http://maps.apple.com/?saddr=&daddr=$lat,$lng&directionsmode=driving&dir_action=navigate";
    }
    await launch(url);
  }

  Widget priceDetails() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          15.0,
          0,
          15.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
              ),
              child: Text(
                getTranslated(context, PRICE_DETAIL)!,
                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      color: fontColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(
              color: lightBlack,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, PRICE_LBL)! + " :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "${getPriceFormat(context, double.parse(widget.model!.subTotal!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, DELIVERY_CHARGE_LBL)! + " :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "+ ${getPriceFormat(
                      context,
                      double.parse(widget.model!.delCharge!),
                    )!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, TAXPER)! +
                        " (${widget.model!.taxPer!}) :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "+ ${getPriceFormat(context, double.parse(widget.model!.taxAmt!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, PROMO_CODE_DIS_LBL)! + " :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "- ${getPriceFormat(context, double.parse(widget.model!.promoDis!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, WALLET_BAL)! + " :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "- ${getPriceFormat(context, double.parse(widget.model!.walBal!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
                top: 5.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, TOTAL_PRICE)! + " :",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  ),
                  Text(
                    "${getPriceFormat(context, double.parse(widget.model!.total!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack2,
                        ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getTranslated(context, PAYABLE)! + ": ",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    "${getPriceFormat(context, double.parse(widget.model!.payable!))!}",
                    style: Theme.of(context).textTheme.button!.copyWith(
                          color: lightBlack,
                          fontWeight: FontWeight.bold,
                        ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget shippingDetails() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          15.0,
          0,
          15.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 15.0,
              ),
              child: Row(
                children: [
                  Text(
                    getTranslated(context, SHIPPING_DETAIL)!,
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: fontColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  widget.model!.latitude != "" && widget.model!.longitude != ""
                      ? Container(
                          height: 30,
                          child: IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: fontColor,
                            ),
                            onPressed: () {
                              _launchMap(
                                widget.model!.latitude,
                                widget.model!.longitude,
                              );
                            },
                          ),
                        )
                      : Container()
                ],
              ),
            ),
            const Divider(
              color: lightBlack,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 15.0),
              child: Text(
                widget.model!.name!.isNotEmpty
                    ? " ${capitalize(widget.model!.orderRecipientName!)}"
                    : " ",
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15.0,
                vertical: 3,
              ),
              child: Text(
                capitalize(
                  widget.model!.address!,
                ),
                style: const TextStyle(
                  color: lightBlack2,
                ),
              ),
            ),
            InkWell(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 5,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.call,
                      size: 15,
                      color: fontColor,
                    ),
                    Text(
                      " ${widget.model!.mobile!}",
                      style: const TextStyle(
                        color: fontColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _launchCaller(widget.model!.mobile!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget sellerDetails(int index) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5.0, 0, 5.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: FadeInImage(
                fadeInDuration: const Duration(milliseconds: 150),
                image: NetworkImage(widget.model!.itemList![index].storeImage!),
                height: 50.0,
                width: 50.0,
                placeholder: placeHolder(50),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                    ),
                    child: Text(
                      widget.model!.itemList![index].storeName != "" &&
                              widget
                                  .model!.itemList![index].storeName!.isNotEmpty
                          ? "${capitalize(widget.model!.itemList![index].storeName!)}"
                          : " ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 1,
                        ),
                        child: Text(
                          capitalize(
                              widget.model!.itemList![index].sellerAddress!),
                          style: const TextStyle(
                            color: lightBlack2,
                          ),
                        ),
                      ),
                      Spacer(),
                      widget.model!.itemList![index].storeLatitude != "" &&
                              widget.model!.itemList![index].storeLongitude !=
                                  ""
                          ? Container(
                              height: 25,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.location_on,
                                  color: fontColor,
                                  size: 15,
                                ),
                                onPressed: () {
                                  _launchMap(
                                      widget.model!.itemList![index]
                                          .storeLatitude,
                                      widget.model!.itemList![index]
                                          .storeLongitude);
                                },
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15.0,
                        vertical: 1,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.call,
                            size: 15,
                            color: fontColor,
                          ),
                          Text(
                            " ${widget.model!.itemList![index].sellerMobileNumber!}",
                            style: const TextStyle(
                              color: fontColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      _launchCaller(
                        widget.model!.itemList![index].sellerMobileNumber!,
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget productItem(OrderItem orderItem, Order_Model model, int i) {
    List att = [], val = [];
    if (orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: FadeInImage(
                    fadeInDuration: const Duration(
                      milliseconds: 150,
                    ),
                    image: NetworkImage(orderItem.image!),
                    height: 90.0,
                    width: 90.0,
                    placeholder: placeHolder(90),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderItem.name ?? '',
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: lightBlack,
                                    fontWeight: FontWeight.normal,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        orderItem.attr_name!.isNotEmpty
                            ? ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: att.length,
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          att[index].trim() + ":",
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(color: lightBlack2),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 5.0),
                                        child: Text(
                                          val[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(color: lightBlack),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              )
                            : Container(),
                        Row(
                          children: [
                            Text(
                              getTranslated(context, QUANTITY_LBL)! + ":",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                    color: lightBlack2,
                                  ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: Text(
                                orderItem.qty!,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle2!
                                    .copyWith(
                                      color: lightBlack,
                                    ),
                              ),
                            )
                          ],
                        ),
                        Text(
                          "${getPriceFormat(context, double.parse(orderItem.price!))!}",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: fontColor,
                                  ),
                        ),
                        widget.model!.itemList!.length >= 1
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: DropdownButtonFormField(
                                        dropdownColor: lightWhite,
                                        isDense: true,
                                        iconEnabledColor: fontColor,
                                        //iconSize: 40,
                                        hint: Text(
                                          getTranslated(context, UpdateStatus)!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle2!
                                              .copyWith(
                                                color: fontColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        decoration: const InputDecoration(
                                          filled: true,
                                          isDense: true,
                                          fillColor: lightWhite,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 10,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: fontColor,
                                            ),
                                          ),
                                        ),
                                        value: orderItem.status,
                                        onChanged: (dynamic newValue) {
                                          setState(
                                            () {
                                              orderItem.curSelected = newValue;
                                            },
                                          );
                                        },
                                        items: statusList.map(
                                          (String st) {
                                            return DropdownMenuItem<String>(
                                              value: st,
                                              child: Text(
                                                () {
                                                  if (capitalize(st) ==
                                                      "Received") {
                                                    return getTranslated(
                                                        context, "received")!;
                                                  } else if (capitalize(st) ==
                                                      "Processed") {
                                                    return getTranslated(
                                                        context, "processed")!;
                                                  } else if (capitalize(st) ==
                                                      "Shipped") {
                                                    return getTranslated(
                                                        context, "shipped")!;
                                                  } else if (capitalize(st) ==
                                                      "Delivered") {
                                                    return getTranslated(
                                                        context, "delivered")!;
                                                  } else if (capitalize(st) ==
                                                      "Returned") {
                                                    return getTranslated(
                                                        context, "returned")!;
                                                  } else if (capitalize(st) ==
                                                      "Cancelled") {
                                                    return getTranslated(
                                                        context, "cancelled")!;
                                                  }
                                                  return capitalize(st);
                                                }(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle2!
                                                    .copyWith(
                                                      color: fontColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: RawMaterialButton(
                                        constraints:
                                            const BoxConstraints.expand(
                                          width: 42,
                                          height: 42,
                                        ),
                                        onPressed: () {
                                          if (orderItem.item_otp != "" &&
                                              orderItem.item_otp!.isNotEmpty &&
                                              orderItem.item_otp != "0" &&
                                              orderItem.curSelected ==
                                                  DELIVERD) {
                                            otpDialog(
                                              orderItem.curSelected,
                                              orderItem.item_otp,
                                              model.id,
                                              true,
                                              i,
                                            );
                                          } else {
                                            updateOrder(
                                              orderItem.curSelected,
                                              model.id,
                                              true,
                                              i,
                                              orderItem.item_otp,
                                            );
                                          }
                                        },
                                        elevation: 2.0,
                                        fillColor: fontColor,
                                        padding: const EdgeInsets.only(left: 5),
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.send,
                                            size: 20,
                                            color: white,
                                          ),
                                        ),
                                        shape: const CircleBorder(),
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                )
              ],
            ),
            ExpansionTile(
              children: [
                sellerDetails(i),
              ],
              title: Text(
                getTranslated(context, SELLER_DETAILS)!,
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> updateOrder(
    String? status,
    String? id,
    bool item,
    int index,
    String? otp,
  ) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        setState(
          () {
            _isProgress = true;
          },
        );
        var parameter = {
          ORDERID: id,
          STATUS: status,
          DEL_BOY_ID: CUR_USERID,
          OTP: otp == 0 ? "" : otp,
        };

        if (item) parameter[ORDERITEMID] = widget.model!.itemList![index].id;

        Response response = await post(
          updateOrderItemApi,
          body: parameter,
          headers: headers,
        ).timeout(
          Duration(seconds: timeOut),
        );

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];
        setsnackbar(msg, context);
        if (!error) {
          if (item) {
            widget.model!.itemList![index].status = status;
          } else {
            widget.model!.activeStatus = status;
          }
        }

        setState(
          () {
            _isProgress = false;
          },
        );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
      }
    } else {
      setState(
        () {
          _isNetworkAvail = false;
        },
      );
    }
  }

  void _launchCaller(String phoneNumber) async {
    var url = "tel:$phoneNumber";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      setsnackbar('Could not launch $url', context);
      throw 'Could not launch $url';
    }
  }
}
