import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

final logoutURL =
    "http://idas.uestc.edu.cn/authserver/logout?service=http://eportal.uestc.edu.cn/new/index.html";

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  WebViewController _webViewController;

  final indexURL =
      'http://eportal.uestc.edu.cn/jkdkapp/sys/lwReportEpidemicStu/*default/index.do?client=mobile';
  Uri uri;
  int state = -1; // -1: 未登录 0 已登录 1 已打卡
  String jsContent;

  JavascriptChannel _jsChannel(BuildContext context) => JavascriptChannel(
      name: 'NMSL',
      onMessageReceived: (JavascriptMessage msg) async {
        print(msg.message);
      });

  Future<String> getCookie() async {
    return _webViewController.evaluateJavascript('document.cookie;');
  }

  void handleNavigation(String uriString) async {
    uri = Uri.parse(uriString);
    print("[host] " + uri.host);
    print("[page] " + uriString);
    print("[path] " + uriString.split('#').last);

    switch (uri.host) {
      case "idas.uestc.edu.cn":
        print("请登录");
        break;

      case "eportal.uestc.edu.cn":
        print("登录成功");
        // 注入 js 内容
        rootBundle
            .loadString('lib/js/fuck.js')
            .then((value) => _webViewController.evaluateJavascript(value));
        setState(() {
          state = 0;
        });
        break;
      default:
    }
  }

  void logout() {
    _webViewController.loadUrl(logoutURL);
    print("logging out");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text("打你🐎的卡"),
          actions: [
            IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => _webViewController.goBack()),
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => _webViewController.loadUrl(indexURL)),
            IconButton(
                icon: Icon(Icons.accessible_forward),
                onPressed: () {
                  print('do something');
                  _webViewController
                      .evaluateJavascript('NMSL.postMessage("?")');
                  _webViewController.evaluateJavascript(
                      'fuckTemp(1).then(res => console.log(JSON.stringify(res)))');
                  _webViewController.evaluateJavascript(
                      'fuckDailyReport().then(res => console.log("ojbk"))');
                }),
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => print('do something')),
          ],
        ),
        body: WebView(
          initialUrl: indexURL,
          javascriptMode: JavascriptMode.unrestricted,
          onPageFinished: handleNavigation,
          onWebViewCreated: (controller) {
            _webViewController = controller;
          },
          javascriptChannels: <JavascriptChannel>[_jsChannel(context)].toSet(),
        ));
  }
}
