import 'dart:async';
import 'dart:convert';
import 'package:deliveryboy_multivendor/Helper/Session.dart';
import 'package:deliveryboy_multivendor/Helper/app_btn.dart';
import 'package:deliveryboy_multivendor/Helper/color.dart';
import 'package:deliveryboy_multivendor/Helper/constant.dart';
import 'package:deliveryboy_multivendor/Helper/sim_btn.dart';
import 'package:deliveryboy_multivendor/Helper/string.dart';
import 'package:deliveryboy_multivendor/Model/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class WalletHistory extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return StateWallet();
  }
}

List<TransactionModel> tranList = [];
int offset = 0;
int total = 0;
bool isLoadingmore = true;
bool _isLoading = true;

class StateWallet extends State<WalletHistory> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];
  TextEditingController? amtC, bankDetailC;

  @override
  void initState() {
    super.initState();
    getTransaction();
    controller.addListener(_scrollListener);
    buttonController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: Interval(
          0.0,
          0.150,
        ),
      ),
    );
    amtC = TextEditingController();
    bankDetailC = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightWhite,
      key: _scaffoldKey,
      appBar: getAppBar(
        getTranslated(context, WALLET)!,
        context,
      ),
      body: _isNetworkAvail
          ? _isLoading
              ? shimmer()
              : RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                          ),
                          child: Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                18.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: fontColor,
                                      ),
                                      Text(
                                        " " + CURBAL_LBL,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2!
                                            .copyWith(
                                              color: fontColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    getPriceFormat(
                                      context,
                                      double.parse(CUR_BALANCE),
                                    )!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline6!
                                        .copyWith(
                                          color: fontColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  SimBtn(
                                    size: 0.8,
                                    title:
                                        getTranslated(context, WITHDRAW_MONEY)!,
                                    onBtnSelected: () {
                                      _showDialog();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        tranList.length == 0
                            ? Center(
                                child: Text(
                                  getTranslated(context, noItem)!,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: (offset < total)
                                    ? tranList.length + 1
                                    : tranList.length,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return (index == tranList.length &&
                                          isLoadingmore)
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : listItem(index);
                                },
                              ),
                      ],
                    ),
                  ),
                )
          : noInternet(context),
    );
  }

  Future<Null> sendRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          AMOUNT: amtC!.text.toString(),
          PAYMENT_ADD: bankDetailC!.text.toString()
        };

        Response response =
            await post(sendWithReqApi, body: parameter, headers: headers)
                .timeout(
          Duration(seconds: timeOut),
        );

        var getdata = json.decode(response.body);
        bool error = getdata["error"];
        String msg = getdata["message"];

        if (!error) {
          CUR_BALANCE = double.parse(getdata["data"]).toStringAsFixed(2);
        }
        if (mounted)
          setState(
            () {},
          );
        setsnackbar(msg, context);
      } on TimeoutException catch (_) {
        setsnackbar(somethingMSg, context);
        setState(
          () {
            _isLoading = false;
          },
        );
      }
    } else {
      if (mounted)
        setState(
          () {
            _isNetworkAvail = false;
            _isLoading = false;
          },
        );
    }

    return null;
  }

  getAppBar(
    String title,
    BuildContext context,
  ) {
    return AppBar(
      leading: Builder(
        builder: (BuildContext context) {
          return Container(
            margin: EdgeInsets.all(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: primary,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          color: primary,
        ),
      ),
      backgroundColor: white,
      actions: [
        Container(
          margin: EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              return filterDialog();
            },
            child: Padding(
              padding: const EdgeInsets.all(
                4.0,
              ),
              child: Icon(
                Icons.filter_alt_outlined,
                color: primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void filterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ButtonBarTheme(
          data: ButtonBarThemeData(
            alignment: MainAxisAlignment.center,
          ),
          child: AlertDialog(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  5.0,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.all(
              0.0,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: 19.0,
                    bottom: 16.0,
                  ),
                  child: Text(
                    getTranslated(context, FILTER_BY)!,
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
                Divider(
                  color: lightBlack,
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, SHOW_TRANS)!,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: lightBlack,
                        ),
                  ),
                  onPressed: () {
                    tranList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                      },
                    );
                    getTransaction();
                    Navigator.pop(context, 'option 1');
                  },
                ),
                Divider(color: lightBlack),
                TextButton(
                  child: Text(
                    getTranslated(context, SHOW_REQ)!,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: lightBlack,
                        ),
                  ),
                  onPressed: () {
                    tranList.clear();
                    offset = 0;
                    total = 0;
                    setState(
                      () {
                        _isLoading = true;
                      },
                    );
                    getRequest();
                    Navigator.pop(context, 'option 1');
                  },
                ),
                Divider(
                  color: white,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  _showDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: RoundedRectangleBorder(
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
                      padding: EdgeInsets.fromLTRB(
                        20.0,
                        20.0,
                        0,
                        2.0,
                      ),
                      child: Text(
                        getTranslated(context, SEND_REQUEST)!,
                        style: Theme.of(this.context)
                            .textTheme
                            .subtitle1!
                            .copyWith(
                              color: fontColor,
                            ),
                      ),
                    ),
                    Divider(
                      color: lightBlack,
                    ),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              validator: (val) => validateField(val, context),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText:
                                    getTranslated(context, WITHDRWAL_AMT)!,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: amtC,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              20.0,
                              0,
                              20.0,
                              0,
                            ),
                            child: TextFormField(
                              validator: (val) => validateField(val, context),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                hintText: BANK_DETAIL,
                                hintStyle: Theme.of(this.context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                      color: lightBlack,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                              controller: bankDetailC,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                      sendRequest();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  listItem(int index) {
    Color back;
    if (tranList[index].status == "success" ||
        tranList[index].status == ACCEPTED) {
      back = Colors.green;
    } else if (tranList[index].status == PENDING)
      back = Colors.orange;
    else
      back = Colors.red;
    return Card(
      elevation: 0,
      margin: EdgeInsets.all(5.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    getTranslated(context, AMT_LBL)! +
                        " : " +
                        getPriceFormat(
                          context,
                          double.parse(
                            tranList[index].amt!,
                          ),
                        )!,
                    style: TextStyle(
                      color: fontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    tranList[index].date!,
                  ),
                ],
              ),
              Divider(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    getTranslated(context, ID_LBL)! +
                        " : " +
                        tranList[index].id!,
                  ),
                  Spacer(),
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: back,
                      borderRadius: BorderRadius.all(
                        const Radius.circular(
                          4.0,
                        ),
                      ),
                    ),
                    child: Text(
                      capitalize(
                        tranList[index].status!,
                      ),
                      style: TextStyle(
                        color: white,
                      ),
                    ),
                  )
                ],
              ),
              tranList[index].opnBal != "" &&
                      tranList[index].opnBal != null &&
                      tranList[index].opnBal!.isNotEmpty
                  ? Text(
                      getTranslated(context, OPNBL_LBL)! +
                          " : " +
                          tranList[index].opnBal!,
                    )
                  : Container(),
              tranList[index].clsBal != "" &&
                      tranList[index].clsBal != null &&
                      tranList[index].clsBal!.isNotEmpty
                  ? Text(
                      CLBL_LBL + " : " + tranList[index].clsBal!,
                    )
                  : Container(),
              tranList[index].msg != "" &&
                      tranList[index].msg != null &&
                      tranList[index].msg!.isNotEmpty
                  ? Text(
                      MSG_LBL + " : " + tranList[index].msg!,
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playAnimation() async {
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
              title: getTranslated(context, TRY_AGAIN_INT_LBL)!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      getTransaction();
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

  Future<Null> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
            await post(getFundTransferApi, headers: headers, body: parameter)
                .timeout(
          Duration(
            seconds: timeOut,
          ),
        );

        if (response.statusCode == 200) {
          var getdata = json.decode(
            response.body,
          );
          bool error = getdata["error"];
          if (!error) {
            total = int.parse(
              getdata["total"],
            );

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted)
          setState(
            () {
              _isLoading = false;
            },
          );
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
        setState(
          () {
            _isLoading = false;
            isLoadingmore = false;
          },
        );
      }
    } else
      setState(
        () {
          _isNetworkAvail = false;
        },
      );

    return null;
  }

  Future<void> getRequest() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: CUR_USERID,
        };

        Response response =
            await post(getWithReqApi, headers: headers, body: parameter)
                .timeout(Duration(seconds: timeOut));

        if (response.statusCode == 200) {
          var getdata = json.decode(response.body);
          bool error = getdata["error"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map(
                    (data) => TransactionModel.fromReqJson(data),
                  )
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            isLoadingmore = false;
          }
        }
        if (mounted)
          setState(() {
            _isLoading = false;
          });
      } on TimeoutException catch (_) {
        setsnackbar(getTranslated(context, somethingMSg)!, context);
        setState(
          () {
            _isLoading = false;
            isLoadingmore = false;
          },
        );
      }
    } else
      setState(
        () {
          _isNetworkAvail = false;
        },
      );

    return null;
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    setState(
      () {
        _isLoading = true;
      },
    );
    offset = 0;
    total = 0;
    tranList.clear();
    return getTransaction();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (this.mounted) {
        setState(
          () {
            isLoadingmore = true;

            if (offset < total) getTransaction();
          },
        );
      }
    }
  }
}
