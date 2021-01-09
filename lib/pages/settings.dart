import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  SettingPage({Key key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDebugging = false;
  bool _autoFillPass = false;
  Map<String, String> _userInfo = {'id': '', 'pwd': ''};
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    _prefs.then((ins) {
      _isDebugging = ins.getBool('isDebugging') ?? false;
      _autoFillPass = ins.getBool('autoFillPass') ?? false;
      _userInfo['id'] = ins.getString('id');
      _userInfo['pwd'] = ins.getString('pwd');
      setState(() {}); // 重新渲染状态
    });
    super.initState();
  }

  void _updateDebugging(value) {
    setState(() {
      _isDebugging = value;
    });
    _prefs.then((ins) => ins.setBool('isDebugging', value));
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
    print(k + value);
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
        appBar: AppBar(
          title: Text("设置"),
        ),
        body: ListView(
          children: ListTile.divideTiles(
            context: context,
            tiles: [
              _buildListItem(
                onTap: () => _updateDebugging(!_isDebugging),
                iconData: Icons.developer_mode,
                title: '调试模式',
                subtitle: '此模式下不会发送打卡请求',
                trailing:
                    Switch(value: _isDebugging, onChanged: _updateDebugging),
              ),
              ExpansionTile(
                initiallyExpanded: _autoFillPass,
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
                iconData: Icons.system_update,
                title: '检查更新',
                subtitle: '当前版本： 0.1',
              ),
              _buildListItem(
                iconData: Icons.thumb_up,
                title: '搞得不错',
                subtitle: '如果节省了你生命中的几秒钟',
                trailing: Icon(Icons.open_in_new),
              ),
              _buildListItem(
                iconData: Icons.local_play,
                title: '项目主页',
                subtitle: '外面冷，快进妙♂妙屋来坐坐',
                trailing: Icon(Icons.open_in_new),
              ),
            ],
          ).toList(),
        ));
  }
}
