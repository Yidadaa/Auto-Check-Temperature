import 'dart:async';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    _prefs.then((ins) {
      _isDebugging = ins.getBool('isDebugging') ?? false;
      _autoFillPass = ins.getBool('autoFillPass') ?? false;
      _showIntroCard = ins.getBool('showIntroCard') ?? false;
      _userInfo['id'] = ins.getString('id');
      _userInfo['pwd'] = ins.getString('pwd');
      setState(() {}); // 重新渲染状态
    });
    super.initState();
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
    Timer(Duration(seconds: 1), () {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text('已经是最新版本。')));
      setState(() {
        _isCheckingUpdate = false;
      });
    });
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
          title: Text(title),
          subtitle: Text(subtitle),
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
                subtitle: '小朋友不要点这个选项',
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
                  subtitle: '当前版本： 0.1',
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
                  title: '搞得不错',
                  subtitle: '如果节省了你生命中的几秒钟',
                  trailing: Icon(Icons.open_in_new),
                  onTap: () {
                    launch('https://qr.alipay.com/fkx12171cwhhbzwv462buc6');
                  }),
              _buildListItem(
                  iconData: Icons.local_play,
                  title: '项目主页',
                  subtitle: '来看看有什么新动态',
                  trailing: Icon(Icons.open_in_new),
                  onTap: () {
                    launch('https://github.com/Yidadaa/Auto-Check-Temperature');
                  }),
              _buildListItem(
                  iconData: Icons.info_outline,
                  title: '版权信息 © $_year',
                  subtitle: 'Zyf 💘 Yrn. All rights reserved.',
                  trailing: Icon(Icons.open_in_new),
                  onTap: () {
                    launch('https://www.github.com/Yidadaa');
                  }),
              _buildListItem(
                  iconData: Icons.logout,
                  title: '退出登录',
                  subtitle: '将会清除登录信息',
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context).pop('logout');
                  }),
            ],
          ).toList(),
        ));
  }
}
