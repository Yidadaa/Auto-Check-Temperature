import 'dart:async';
import 'dart:convert';

import 'package:auto_check_temperature/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatefulWidget {
  SettingPage({Key key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDebugging = false;
  bool _autoFillPass = false;
  bool _isCheckingUpdate = false;
  bool _showIntroCard = false;
  int _year = DateTime.now().year;
  Map<String, String> _userInfo = {'id': '', 'pwd': ''};
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String _localVersion;

  @override
  void initState() {
    _prefs.then((ins) {
      _isDebugging = ins.getBool('isDebugging') ?? false;
      _autoFillPass = ins.getBool('autoFillPass') ?? false;
      _showIntroCard = ins.getBool('showIntroCard') ?? false;
      _userInfo['id'] = ins.getString('id');
      _userInfo['pwd'] = ins.getString('pwd');
      _loadLocalVersion();
      setState(() {}); // 重新渲染状态
    });
    super.initState();
  }

  void _loadLocalVersion() {
    rootBundle.loadString('assets/version.json').then((res) {
      setState(() {
        Map lVersion = jsonDecode(res);
        if (lVersion != null) _localVersion = lVersion['ver'];
      });
    });
  }

  void _updateIntroCard(value) {
    setState(() {
      _showIntroCard = value;
    });
    _prefs.then((ins) => ins.setBool('showIntroCard', value));
  }

  void _updateDebugging(value) {
    setState(() {
      _isDebugging = value;
    });
    _prefs.then((ins) => ins.setBool('isDebugging', value));
    if (value) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('调试模式下不会发送打卡请求。'),
        duration: Duration(seconds: 1),
      ));
    }
  }

  void _updateAutoFill(value) {
    setState(() {
      _autoFillPass = value;
    });
    _prefs.then((ins) => ins.setBool('autoFillPass', value));
  }

  void _updateText(k, value) async {
    var _prefs = await this._prefs;
    _userInfo[k] = value;
    await _prefs.setString(k, value);
  }

  void _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    Map versionInfo = await checkUpdate();

    if (versionInfo != null && versionInfo.containsKey('ver')) {
      String latestVersion = versionInfo['ver'];
      if (latestVersion == _localVersion)
        _scaffoldKey.currentState
            .showSnackBar(SnackBar(content: Text('已经是最新版本。')));
      else
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text('发现新版本：$latestVersion，请前往主页更新。')));
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  void _contactMe() {
    final Uri mailUri =
        Uri(scheme: 'mailto', path: 'yidadaa@qq.com', queryParameters: {
      'subject': '[体温应用反馈]一句话描述你的需求',
      'body': '{version:$_localVersion}<br><br>请详细描述你遇到的问题或者想要提出的建议，最好提供截图。'
    });
    launch(mailUri.toString());
  }

  Widget _buildBubble(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(15)),
      child: Container(
        padding: EdgeInsets.all(10),
        color: Colors.black12.withOpacity(.05),
        child: Text(text),
      ),
    );
  }

  Widget _buildDeveloper() {
    return Container(
        padding: EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: Image.asset(
                  'assets/images/developer.jpg',
                  width: 50,
                  height: 50,
                )),
            Expanded(
                child: Padding(
              padding: EdgeInsets.only(left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text(
                      '修仙写代码的开发者',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  _buildBubble(
                      '大家好，众所周知，学校的信息系统从来都是以浪费生命为己任，能用一个界面搞定的体温打卡绝对要想办法让我们一天点三次，“每日报平安”和班委人工打卡的双重机制更是令重度脑淤血患者直呼内行。'),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: _buildBubble(
                        '在像个哈批一样点了快一年的屏幕之后，👴意识到这种打卡可能要没完没了了，所以就浪费了四天的生命整了个这玩意儿出来，希望可以帮到大家。'),
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: _buildBubble(
                          '如果你觉得这个活整得还行，可以使用下面的链接鼓励一下开发者，遇到 bug 可以使用邮箱进行反馈，祝大家都能省下宝贵的几秒钟。')),
                ],
              ),
            ))
          ],
        ));
  }

  void _showDonateDialog() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
        ),
        backgroundColor: Colors.white,
        builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(children: [
              Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.black12,
                    )),
              ),
              Expanded(
                  child: ListView(
                children: [
                  Column(
                    children: [
                      _buildDeveloper(),
                      Divider(),
                      _buildListItem(
                          title: '一趟单程 396 (2 * 💰)',
                          subtitle: '请作者去建设巷恰小吃',
                          iconData: Icons.directions_bus,
                          trailing: Icon(Icons.open_in_new),
                          onTap: () => launch(
                              'https://qr.alipay.com/fkx19323d0sibaj4qy8xm52')),
                      _buildListItem(
                          title: '一瓶快乐水 (3.5 * 💰)',
                          subtitle: '恰什么小吃，肥宅水不香吗',
                          iconData: Icons.fastfood,
                          trailing: Icon(Icons.open_in_new),
                          onTap: () => launch(
                              'https://qr.alipay.com/fkx12451wztqnsv7gxyxxb5')),
                      _buildListItem(
                          title: '一盒烤冷面 (9 * 💰)',
                          subtitle: '不会真的有人喜欢当肥宅吧',
                          iconData: Icons.store_mall_directory,
                          trailing: Icon(Icons.open_in_new),
                          onTap: () => launch(
                              'https://qr.alipay.com/fkx10872yq7vh8lbmmgqp72')),
                      _buildListItem(
                          title: '👴有的是钱 (∞ * 💰)',
                          subtitle: '👴要闭着眼睛按零',
                          iconData: Icons.local_atm,
                          trailing: Icon(Icons.open_in_new),
                          onTap: () => launch(
                              'https://qr.alipay.com/fkx12171cwhhbzwv462buc6'))
                    ],
                  ),
                ],
              ))
            ])));
  }

  Widget _buildCopyRight() {
    return InkWell(
      onTap: () => launch('https://www.github.com/Yidadaa'),
      child: Container(
          height: 100,
          child: Center(
              child: Opacity(
            opacity: .2,
            child: Text('© $_year Yda 💘 Yrn. All Rights Reserved.'),
          ))),
    );
  }

  Widget _buildListItem(
      {IconData iconData,
      String title,
      String subtitle,
      Widget trailing,
      Function onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: ListTile(
          leading: Icon(
            iconData,
            size: 40,
          ),
          title: title != null ? Text(title) : null,
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: trailing),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("设置"),
          elevation: 0,
        ),
        resizeToAvoidBottomInset: false, // Yidadaa: 避免 resize 引起的键盘卡顿
        body: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              _buildListItem(
                onTap: () => _updateDebugging(!_isDebugging),
                iconData: Icons.developer_mode,
                title: '调试模式',
                subtitle: '同学请不要乱点这个选项',
                trailing:
                    Switch(value: _isDebugging, onChanged: _updateDebugging),
              ),
              if (_isDebugging)
                _buildListItem(
                  onTap: () => _updateIntroCard(!_showIntroCard),
                  iconData: Icons.pages,
                  title: '引导卡片',
                  subtitle: '开启后会在首页展示使用引导',
                  trailing: Switch(
                      value: _showIntroCard, onChanged: _updateIntroCard),
                ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: Opacity(
                  opacity: .87,
                  child: Icon(Icons.ballot, size: 40),
                ),
                title: Text('自动填充账号密码'),
                subtitle: Opacity(
                  opacity: 0.54,
                  child: Text(
                    '账号密码会被保存在本地',
                  ),
                ),
                children: [
                  ListTile(
                      leading: Text(''),
                      title: TextField(
                        controller: TextEditingController()
                          ..text = _userInfo['id'],
                        onChanged: (value) => _updateText('id', value),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            isDense: true, labelText: '学号', hintText: '信息门户学号'),
                      )),
                  ListTile(
                      leading: Text(''),
                      title: TextField(
                        controller: TextEditingController()
                          ..text = _userInfo['pwd'],
                        onChanged: (value) => _updateText('pwd', value),
                        obscureText: true,
                        decoration: InputDecoration(
                            isDense: true, labelText: '密码', hintText: '信息门户密码'),
                      )),
                  InkWell(
                    onTap: () {
                      _updateAutoFill(!_autoFillPass);
                    },
                    child: ListTile(
                        leading: Text(''),
                        title: Text('启用该功能'),
                        trailing: Switch(
                          value: _autoFillPass,
                          onChanged: _updateAutoFill,
                        )),
                  )
                ],
              ),
              _buildListItem(
                  onTap: _checkUpdate,
                  iconData: Icons.system_update,
                  title: '检查更新',
                  subtitle: '当前版本：$_localVersion',
                  trailing: _isCheckingUpdate
                      ? Container(
                          height: 18,
                          width: 21,
                          padding: EdgeInsets.only(right: 3),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                          ),
                        )
                      : null),
              _buildListItem(
                  iconData: Icons.thumb_up,
                  title: '针不戳',
                  subtitle: '这个应用针不戳，好活，赏了',
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    _showDonateDialog();
                    // launch('https://qr.alipay.com/fkx12171cwhhbzwv462buc6');
                  }),
              _buildListItem(
                  iconData: Icons.local_play,
                  title: '项目主页',
                  subtitle: '来看看作者又整了什么新活',
                  trailing: Icon(Icons.open_in_new),
                  onTap: () {
                    launch('https://github.com/Yidadaa/Auto-Check-Temperature');
                  }),
              _buildListItem(
                  iconData: Icons.mail,
                  title: '和开发者对线',
                  subtitle: 'Bug 竟是我自己.jpg',
                  trailing: Icon(Icons.open_in_new),
                  onTap: _contactMe),
              _buildListItem(
                  iconData: Icons.logout,
                  title: '退出登录',
                  subtitle: '将会清除登录信息',
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context).pop('logout');
                  }),
              _buildCopyRight()
            ],
          ).toList(),
        ));
  }
}
