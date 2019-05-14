import 'package:flutter_aria2/flutter_aria2.dart';

//Future<void> main(List<String> args) async {
Future<void> main() async {
  final _aria2 = await FlutterAria2().open('ws://127.0.0.1:6800/jsonrpc', 'passu');
  final resp = _aria2.invokeRpc('aria2.tellActive');
  print(resp);
}