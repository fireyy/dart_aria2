import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

import './common/logging.dart';

const Duration _kConnectTimeout = Duration(seconds: 9);

const Duration _kReconnectAttemptInterval = Duration(seconds: 3);

const Duration _kRpcTimeout = Duration(seconds: 5);

final Logger _log = Logger('Aria2');

/// Signature of an asynchronous function for establishing a JSON RPC-2
/// connection to a [Uri].
typedef RpcPeerConnectionFunction = Future<json_rpc.Peer> Function(
  Uri uri, String secret, {
  Duration timeout,
});

/// [Aria2] uses this function to connect to the Aria2 Server.
///
/// This function can be assigned to a different one in the event that a
/// custom connection function is needed.
RpcPeerConnectionFunction aria2ServiceConnectionFunction = _waitAndConnect;


void _unhandledJsonRpcError(dynamic error, dynamic stack) {
  _log.fine('Error in internalimplementation of JSON RPC.\n$error\n$stack');
}

/// Attempts to connect to a Aria2 Server service.
///
/// Gives up after `timeout` has elapsed.
Future<json_rpc.Peer> _waitAndConnect(
  Uri uri, String secret, {
  Duration timeout = _kConnectTimeout,
}) async {
  final Stopwatch timer = Stopwatch()..start();

  Future<json_rpc.Peer> attemptConnection(Uri uri) async {
    WebSocket socket;
    json_rpc.Peer peer;
    try {
      socket = await WebSocket.connect(uri.toString()).timeout(timeout);
      peer = json_rpc.Peer(IOWebSocketChannel(socket).cast(), onUnhandledError: _unhandledJsonRpcError)..listen();
      return peer;
    } on HttpException catch (e) {
      // This is a fine warning as this most likely means the port is stale.
      _log.fine('$e: ${e.message}');
      await peer?.close();
      await socket?.close();
      rethrow;
    } catch (e) {
      _log.fine('Aria2 Server connection failed $e: ${e.message}');
      // Other unknown errors will be handled with reconnects.
      await peer?.close();
      await socket?.close();
      if (timer.elapsed < timeout) {
        _log.info('Attempting to reconnect');
        await Future<void>.delayed(_kReconnectAttemptInterval);
        return attemptConnection(uri);
      } else {
        _log.warning('Connection to Aria2 Server timed out at '
            '${uri.toString()}');
        rethrow;
      }
    }
  }

  return attemptConnection(uri);
}

/// Restores the Aria2 server connection function to the default implementation.
void restoreAria2ServiceConnectionFunction() {
  aria2ServiceConnectionFunction = _waitAndConnect;
}

/// An error raised when a malformed RPC response is received from the Aria2 Server.
///
/// A more detailed description of the error is found within the [message]
/// field.
class RpcFormatError extends Error {
  /// Basic constructor outlining the reason for the format error.
  RpcFormatError(this.message);

  /// The reason for format error.
  final String message;

  @override
  String toString() {
    return '$RpcFormatError: $message\n${super.stackTrace}';
  }
}

/// Handles JSON RPC-2 communication with a Aria2 Server service.
///
/// Either wraps existing RPC calls to the Aria2 Server service, or runs raw RPC
/// function calls via [invokeRpc].
class Aria2 {
  Aria2._(this._peer, this.uri, this.secret);

  final json_rpc.Peer _peer;

  /// The URI through which this DartVM instance is connected.
  final Uri uri;

  final String secret;

  /// Attempts to connect to the given [Uri].
  ///
  /// Throws an error if unable to connect.
  static Future<Aria2> connect(
    Uri uri, String secret, {
    Duration timeout = _kConnectTimeout,
  }) async {
    // if (uri.scheme == 'http') {
    //   uri = uri.replace(scheme: 'ws', path: '/ws');
    // }
    final json_rpc.Peer peer =
        await aria2ServiceConnectionFunction(uri, secret, timeout: timeout);
    if (peer == null) {
      return null;
    }
    return Aria2._(peer, uri, secret);
  }

  /// Invokes a raw JSON RPC command with the VM service.
  ///
  /// When `timeout` is set and reached, throws a [TimeoutException].
  ///
  /// If the function returns, it is with a parsed JSON response.
  Future<List<dynamic>> invokeRpc(
    String function, {
    Map<String, dynamic> params,
    Duration timeout = _kRpcTimeout,
  }) async {
    final args = params ?? <String, dynamic>{};
    args['token'] = '$secret';
    print(args);
    final List<dynamic> result = await _peer
      .sendRequest(function, args)
      .timeout(timeout, onTimeout: () {
        throw TimeoutException(
          'Peer connection timed out during RPC call',
          timeout,
        );
      });
    return result;
  }

  /// Disconnects from the Aria2 Server Service.
  ///
  /// After this function completes this object is no longer usable.
  Future<void> stop() async {
    await _peer?.close();
  }
}