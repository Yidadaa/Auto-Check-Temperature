import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  SettingPage({Key key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isDebugging = false;
  bool autoFillPass = false;
  Map<String, String> userInfo = {'id': '', 'pwd': ''};
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    _prefs.then((ins) {
      isDebugging = ins.getBool('isDebugging') ?? false;
      autoFillPass = ins.getBool('autoFillPass') ?? false;
      userInfo['id'] = ins.getString('id');
      userInfo['pwd'] = ins.getString('pwd');
      setState(() {}); // 重新渲染状态
    });
    super.initState();
  }

  void updateDebugging(value) {
    setState(() {
      isDebugging = value;
    });
    _prefs.then((ins) => ins.setBool('isDebugging', value));
  }

  void updateAutoFill(value) {
    setState(() {
      autoFillPass = value;
    });
    _prefs.then((ins) => ins.setBool('autoFillPass', value));
  }

  void updateText(k, value) async {
    var _prefs = await this._prefs;
    userInfo[k] = value;
    await _prefs.setString(k, value);
    print(k + value);
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
              InkWell(
                onTap: () {
                  updateDebugging(!isDebugging);
                },
                child: ListTile(
                  leading: Icon(Icons.developer_mode),
                  title: Text('调试模式'),
                  subtitle: Text('调试模式下，不会发送最终的打卡请求'),
                  trailing:
                      Switch(value: isDebugging, onChanged: updateDebugging),
                ),
              ),
              ExpansionTile(
                initiallyExpanded: autoFillPass,
                leading: Icon(Icons.ballot),
                title: Text('自动填充账号密码'),
                subtitle: Text('账号密码会被保存在本地'),
                children: [
                  ListTile(
                      leading: Text(''),
                      title: TextField(
                        controller: TextEditingController()
                          ..text = userInfo['id'],
                        onChanged: (value) => updateText('id', value),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            isDense: true, labelText: '学号', hintText: '信息门户学号'),
                      )),
                  ListTile(
                      leading: Text(''),
                      title: TextField(
                        controller: TextEditingController()
                          ..text = userInfo['pwd'],
                        onChanged: (value) => updateText('pwd', value),
                        obscureText: true,
                        decoration: InputDecoration(
                            isDense: true, labelText: '密码', hintText: '信息门户密码'),
                      )),
                  InkWell(
                    onTap: () {
                      updateAutoFill(!autoFillPass);
                    },
                    child: ListTile(
                        leading: Text(''),
                        title: Text('启用该功能'),
                        trailing: Switch(
                          value: autoFillPass,
                          onChanged: updateAutoFill,
                        )),
                  )
                ],
              ),
              ListTile(
                leading: Icon(Icons.system_update),
                title: Text('检查更新'),
                subtitle: Text('当前版本： 0.1'),
              ),
              ListTile(
                leading: Icon(Icons.thumb_up),
                title: Text('搞得不错'),
                subtitle: Text('如果这个应用节省了你生命中的几秒钟的话'),
                trailing: Icon(Icons.open_in_new),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('项目主页'),
                subtitle: Text('作者的妙♂妙屋，快进来坐坐'),
                trailing: Icon(Icons.open_in_new),
              )
            ],
          ).toList(),
        ));
  }
}
