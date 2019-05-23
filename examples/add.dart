import 'package:flutter_aria2/flutter_aria2.dart';

//Future<void> main(List<String> args) async {
Future<void> main() async {
  final _aria2 = await FlutterAria2().open('ws://127.0.0.1:6800/jsonrpc', 'passu');
  // https://pock.pigigaldi.com/download.php?file=pock_0_4_6_eket.zip
  // https://wz.win10cjb.com/19.4/win10_64/DEEP_Win10x64_201904.rar
  final dw = [['https://pock.pigigaldi.com/download.php?file=pock_0_4_6_eket.zip']];
  final gid = await _aria2.invokeRpc('aria2.addUri', params: dw);
  print(gid);
  final resp = await _aria2.invokeRpc('aria2.tellStatus', params: [gid]);
  print(resp);
}