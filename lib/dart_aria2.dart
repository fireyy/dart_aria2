library flutter_aria2;
import 'dart:async';

import 'src/aria2.dart';
export 'src/aria2.dart';

const Duration _kDartVmConnectionTimeout = Duration(seconds: 9);

class DartAria2 {
  DartAria2();

  Aria2 _aria2;

  Future<Aria2> open(String url, String secret, {
    Duration timeout = _kDartVmConnectionTimeout,
  }) async {
    _aria2 = await Aria2.connect(Uri.parse(url), secret, timeout: timeout);
    return _aria2;
  }

  Future close() => _aria2.stop();
}