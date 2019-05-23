# flutter_aria2

Use "JSON-RPC 2.0" to connect Aria2.

### Dependencies

- [json_rpc_2](https://pub.dev/packages/json_rpc_2)
- [web_socket_channel](https://pub.dev/packages/web_socket_channel)

### Getting Started

```dart
final _aria2 = await FlutterAria2().open('ws://127.0.0.1:6800/jsonrpc', 'passu');

// aria2.tellActive
final resp = await _aria2.invokeRpc('aria2.tellActive');

// aria2.addUri
final gid = await _aria2.invokeRpc('aria2.addUri', params: [['https://cdimage.debian.org/debian-cd/current/amd64/bt-dvd/debian-9.9.0-amd64-DVD-1.iso.torrent']]);
```
