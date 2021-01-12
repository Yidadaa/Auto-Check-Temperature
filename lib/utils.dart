import 'dart:convert';

import 'package:dio/dio.dart';

final String giteeUpdateURL =
    'https://gitee.com/yidadaa/Auto-Check-Temperature/raw/main/assets/version.json';
final String githubUpdateURL =
    'https://raw.githubusercontent.com/Yidadaa/Auto-Check-Temperature/main/assets/version.json';

Future<Response> checkUpdateWith(String url) async {
  Response ret;
  try {
    ret = await Dio().get(giteeUpdateURL);
  } catch (e) {
    ret = null;
  }
  return ret;
}

Future<Map> checkUpdate() async {
  List<Response> checkResults = await Future.wait(
      [checkUpdateWith(giteeUpdateURL), checkUpdateWith(githubUpdateURL)]);
  if (checkResults.every((element) => element == null)) {
    return null;
  }
  Response rawVersionInfo =
      checkResults.firstWhere((element) => element != null);

  Map version = jsonDecode(rawVersionInfo.data);
  return version;
}
