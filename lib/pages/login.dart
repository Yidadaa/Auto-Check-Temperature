import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

final logoutURL =
    "http://idas.uestc.edu.cn/authserver/logout?service=http://eportal.uestc.edu.cn/new/index.html";

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  WebViewController _webViewController;

  final indexURL =
      'http://eportal.uestc.edu.cn/jkdkapp/sys/lwReportEpidemicStu/*default/index.do?client=mobile';
  Uri uri;
  int state = -1; // -1: 未登录; 0: 已登录; >= 1 && < 4: 体温打卡; 4: 每日报平安
  String jsContent;
  double loadingStatus = 0;
  bool isDebugging = true;
  bool showingSnack = false;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  JavascriptChannel _jsChannel(BuildContext context) => JavascriptChannel(
      name: 'NMSL',
      onMessageReceived: (JavascriptMessage msg) async {
        print(msg.message);
        if (msg.message.startsWith('status')) {
          String statusString = msg.message.split(':')[1];
          setState(() {
            state = int.parse(statusString);
          });
        }
      });

  Future<String> getCookie() async {
    return _webViewController.evaluateJavascript('document.cookie;');
  }

  void showSnack(String text) {
    if (showingSnack) return;
    showingSnack = true;
    _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Row(
      children: [
        Icon(Icons.info),
        Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(text),
        )
      ],
    )));
    Timer(Duration(seconds: 4), () {
      setState(() {
        showingSnack = false;
      });
    });
  }

  void handleNavigation(String uriString) async {
    uri = Uri.parse(uriString);
    print("[host] " + uri.host);
    print("[page] " + uriString);
    print("[path] " + uriString.split('#').last);

    switch (uri.host) {
      case "idas.uestc.edu.cn":
        showSnack("请先登录，以获取 Cookie。");
        setState(() {
          loadingStatus += 0.5;
          state = -1;
        });
        fillPass();
        break;

      case "eportal.uestc.edu.cn":
        if (state != 0) showSnack("登录成功，现在可以开冲了。");
        // 注入 js 内容
        rootBundle
            .loadString('lib/js/fuck.js')
            .then((value) => _webViewController.evaluateJavascript(value));
        setState(() {
          state = 0;
          loadingStatus += 0.5;
        });
        break;
      default:
    }
  }

  void logout() {
    _webViewController.loadUrl(logoutURL);
    print("logging out");
  }

  void run() {
    if (state < 0) {
      return showSnack('请先登录');
    }
    _webViewController.evaluateJavascript('fuckAll($isDebugging)');
  }

  void fillPass() async {
    var ins = await _prefs;
    bool autoFillPass = ins.getBool('autoFillPass');
    if (!autoFillPass) return;
    String id = ins.getString('id');
    String pwd = ins.getString('pwd');
    String jsCMD = '''
      document.getElementById('mobileUsername').value = '$id';
      document.getElementById('mobilePassword').value = '$pwd';
      NMSL.postMessage('[fill] done.');
    ''';
    _webViewController.evaluateJavascript(jsCMD);
  }

  void loadData() {
    _prefs.then((pf) {
      isDebugging = pf.getBool('isDebugging');
      print('debug: $isDebugging');
      setState(() {
        loadingStatus += 0.5;
      });
    });
  }

  void showStatusDialog() {
    showModalBottomSheet(
      context: _scaffoldKey.currentContext,
      builder: (context) {
        return ListView(
          children: [
            ListTile(
              leading: Container(
                child: CircularProgressIndicator(
                  value: null,
                ),
                height: 20,
                width: 20,
              ),
              title: Text('hello'),
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          title: Text("打你🐎的卡 $state"),
          actions: [
            IconButton(icon: Icon(Icons.logout), onPressed: logout),
            IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => _webViewController.goBack()),
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _webViewController.loadUrl(indexURL)),
            IconButton(icon: Icon(Icons.accessible_forward), onPressed: run),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  return showStatusDialog();
                  Navigator.pushNamed(context, '/settings')
                      .whenComplete(loadData);
                }),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: loadingStatus,
            ),
            Expanded(
                child: WebView(
              initialUrl: indexURL,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: handleNavigation,
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              javascriptChannels:
                  <JavascriptChannel>[_jsChannel(context)].toSet(),
            ))
          ],
        ));
  }
}
