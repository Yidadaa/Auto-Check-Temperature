import 'package:dio/dio.dart';

final String giteeUpdateURL =
    'https://gitee.com/yidadaa/Auto-Check-Temperature/raw/main/README.md';
final String githubUpdateURL =
    'https://raw.githubusercontent.com/Yidadaa/Auto-Check-Temperature/main/pubspec.yaml';

Future<Response> checkUpdateWith(String url) async {
  Response ret;
  try {
    ret = await Dio().get(giteeUpdateURL);
  } catch (e) {
    ret = null;
  }
  return ret;
}

Future<Response> checkUpdate() async {
  List<Response> checkResults = await Future.wait(
      [checkUpdateWith(giteeUpdateURL), checkUpdateWith(githubUpdateURL)]);
  if (checkResults.every((element) => element == null)) {
    return null;
  }
  return checkResults.firstWhere((element) => element != null);
}
