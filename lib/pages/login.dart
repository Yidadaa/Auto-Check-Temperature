import 'dart:async';
import 'dart:core';

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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  WebViewController _webViewController;

  final _indexURL =
      'http://eportal.uestc.edu.cn/jkdkapp/sys/lwReportEpidemicStu/*default/index.do?client=mobile';
  Uri _uri;
  int _state = -1; // -1: 未登录; 0: 已登录; >= 1 && < 4: 体温打卡; 4: 每日报平安
  double _loadingStatus = 0;
  bool _isDebugging = true;
  bool _showingSnack = false;
  bool _needRefresh = false;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  AnimationController _animationController;
  Animation<double> _animation;
  Function _setModelState = (Function func) {};

  JavascriptChannel _jsChannel(BuildContext context) => JavascriptChannel(
      name: 'NMSL',
      onMessageReceived: (JavascriptMessage msg) async {
        print(msg.message);
        // 同步打卡状态
        if (msg.message.startsWith('status')) {
          String statusString = msg.message.split(':')[1];
          int newStateVal = int.parse(statusString);
          Timer(Duration(milliseconds: 600 + newStateVal * 100), () {
            setState(() {
              _state = newStateVal;
            });
            _setModelState(() {}); // 更新 ModalBottomSheet 的状态
          });
        }
      });

  @override
  void initState() {
    _loadData();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 3000), vsync: this)
          ..repeat(min: 0, max: 0.3, reverse: true);
    _animation = CurvedAnimation(
        parent: _animationController, curve: Curves.elasticInOut);
    super.initState();
  }

  // 展示一个 snackbar
  void _showSnack(String text) {
    if (_showingSnack) return;
    _showingSnack = true;
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(Icons.info),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(text),
          )
        ],
      ),
      action: SnackBarAction(
        label: '知道了',
        onPressed: () {
          _scaffoldKey.currentState.hideCurrentSnackBar();
        },
      ),
    ));
    Timer(Duration(seconds: 5), () {
      setState(() {
        _showingSnack = false;
      });
    });
  }

  // 监听 webview 导航事件
  void _handleNavigation(String uriString) async {
    Uri currentUri = Uri.parse(uriString);
    print("[host] " + currentUri.host);
    print("[page] " + uriString);
    print("[path] " + uriString.split('#').last);

    switch (currentUri.host) {
      case "idas.uestc.edu.cn":
        if (_needRefresh) {
          _needRefresh = false;
          Timer(Duration(milliseconds: 500), () {
            _refresh();
          });
        }
        _showSnack("请先登录，以获取 Cookie。");
        setState(() {
          _loadingStatus += 0.5;
          _state = -1;
        });
        _fillPass();
        break;

      case "eportal.uestc.edu.cn":
        if (_state != 0 && currentUri.host != _uri.host)
          _showSnack("登录成功，现在可以开冲了。");
        // 注入 js 内容
        rootBundle
            .loadString('lib/js/fuck.js')
            .then((value) => _webViewController.evaluateJavascript(value));
        setState(() {
          _state = 0;
          _loadingStatus += 0.5;
        });
        break;
      default:
    }

    _uri = currentUri;
  }

  // 退出登录
  void _logout() {
    _webViewController.loadUrl(logoutURL);
    setState(() {
      _loadingStatus = 0;
      _needRefresh = true;
    });
  }

  // 开始自动打卡
  void _run() {
    if (_state < 0) {
      return _showSnack('请先登录');
    }
    setState(() {
      _state = 0;
    });
    _webViewController.evaluateJavascript('fuckAll($_isDebugging)');
    _showStatusDialog();
  }

  // 重载页面
  void _refresh() {
    _webViewController.loadUrl(_indexURL);
  }

  // 自动填充密码
  void _fillPass() async {
    var ins = await _prefs;
    bool autoFillPass = ins.getBool('autoFillPass') ?? false;
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

  void _loadData() {
    _prefs.then((pf) {
      _isDebugging = pf.getBool('isDebugging') ?? false;
      print('debug: $_isDebugging');
      setState(() {
        _loadingStatus += 0.5;
      });
    });
  }

  // 构建加载提示卡片
  Widget _buildCard(
      String leadingText, String title, String subTitle, bool loading) {
    return Card(
        child: ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      leading: RotationTransition(
        turns: _animation,
        child: Text(
          leadingText,
          style: TextStyle(fontSize: 40),
        ),
      ),
      title: Text(title),
      subtitle: Text(subTitle),
      trailing: loading
          ? Container(
              child: CircularProgressIndicator(
                value: null,
                strokeWidth: 2,
              ),
              height: 20,
              width: 20,
            )
          : Icon(
              Icons.done_all_rounded,
              color: Colors.green,
            ),
    ));
  }

  // 构建状态面板内容
  Widget _buildStatusContent() {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildCard('😆', '上报早上体温', '早上的体温为 36 ℃', _state < 1),
        _buildCard('😫', '上报中午体温', '中午的体温为 36 ℃', _state < 2),
        _buildCard('😝', '上报晚上体温', '晚上的体温为 36 ℃', _state < 3),
        _buildCard('🥱', '每日报平安', '好家伙，全让你给冲完了😅', _state < 4),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: RaisedButton.icon(
                  disabledColor: Colors.black12,
                  color: Colors.blueGrey,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 30),
                  onPressed: _state == 4
                      ? () {
                          Navigator.of(context, rootNavigator: true).pop();
                          _refresh();
                        }
                      : null,
                  icon: Icon(
                    Icons.hotel,
                    color: _state < 4 ? Colors.white54 : Colors.white,
                  ),
                  label: Text(
                    '彳亍，我完事儿了',
                    style: TextStyle(
                      color: _state < 4 ? Colors.white54 : Colors.white,
                    ),
                  ),
                )))
      ],
    );
  }

  // 弹出状态面板
  void _showStatusDialog() async {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            _setModelState = setModalState;
            return _buildStatusContent();
          });
        });
  }

  // 构建弹出菜单的入口
  PopupMenuItem _buildPopupMenuItem(
      IconData iconData, String text, Function onTap) {
    return PopupMenuItem(
      value: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: Colors.black,
            size: 25,
          ),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(text),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        title: Text("打你🐎的卡"),
        actions: [
          IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => _webViewController.goBack()),
          IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
          PopupMenuButton(
            itemBuilder: (_context) {
              var itemList = [
                _buildPopupMenuItem(Icons.logout, '退出登录', _logout),
                _buildPopupMenuItem(Icons.settings, '设置', () {
                  Navigator.pushNamed(context, '/settings')
                      .whenComplete(_loadData);
                }),
              ];
              if (_isDebugging)
                itemList.insert(
                    0,
                    _buildPopupMenuItem(
                        Icons.developer_board, '调试弹窗', _showStatusDialog));
              return itemList;
            },
            onSelected: (callback) {
              callback();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _loadingStatus,
          ),
          Expanded(
              child: WebView(
            initialUrl: _indexURL,
            javascriptMode: JavascriptMode.unrestricted,
            onPageFinished: _handleNavigation,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            javascriptChannels:
                <JavascriptChannel>[_jsChannel(context)].toSet(),
          ))
        ],
      ),
      floatingActionButton: _state >= 0
          ? FloatingActionButton.extended(
              icon: Icon(Icons.accessible_forward),
              onPressed: _run,
              label: Text('一键开冲'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomSheet: Padding(
        padding: EdgeInsets.only(top: 100),
      ),
    );
  }
}
