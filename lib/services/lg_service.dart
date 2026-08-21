import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'tv_service.dart';

/// LG webOS TV control via WebSocket (SSAP protocol on port 3000).
///
/// Pairing handshake:
///   1. Connect to `ws://{ip}:3000`
///   2. Send a registration payload (with client‑key if previously paired).
///   3. If no client‑key, the TV shows a pairing prompt – user clicks "Accept".
///   4. The TV responds with a `client-key` to store for future connections.
class LGService extends TVService {
  WebSocketChannel? _channel;
  WebSocketChannel? _pointerChannel;
  StreamSubscription? _sub;
  StreamSubscription? _pointerSub;
  Future<WebSocketChannel?>? _pointerChannelFuture;
  Completer<String?>? _pointerSocketPath;
  String? _pointerRequestId;
  bool _connected = false;
  int _commandId = 0;

  LGService(super.device);

  @override
  bool get isConnected => _connected;

  // LG WebOS supports app launching, input source switching, and menu navigation.
  @override
  bool get supportsAppLaunching => true;
  @override
  bool get supportsSourceControl => true;
  @override
  bool get supportsMenuNavigation => true;

  @override
  Future<bool> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://${device.ip}:${device.port}'),
      );
      await _channel!.ready;

      // Send SSAP registration handshake.
      _channel!.sink.add(
        jsonEncode(_buildRegistrationPayload(device.pairingToken)),
      );

      // Wait for the TV to send back 'registered'.
      // The TV shows a pairing prompt — user must accept it on the TV screen.
      final completer = Completer<bool>();

      _sub = _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final type = data['type'] as String?;
            if (type == 'registered') {
              final payload = data['payload'] as Map<String, dynamic>?;
              if (payload != null && payload.containsKey('client-key')) {
                device.pairingToken = payload['client-key'] as String;
              }
              _setConnected(true);
              if (!completer.isCompleted) completer.complete(true);
            } else if (type == 'error') {
              if (!completer.isCompleted) completer.complete(false);
            }

            if (data['id'] == _pointerRequestId) {
              final payload = data['payload'] as Map<String, dynamic>?;
              final socketPath = payload?['socketPath'] as String?;
              if (_pointerSocketPath case final pending?
                  when !pending.isCompleted) {
                pending.complete(socketPath);
              }
            }
          } catch (_) {}
        },
        onError: (_) {
          _setConnected(false);
          _completePointerRequest(null);
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          _setConnected(false);
          _completePointerRequest(null);
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      // Give user up to 30 s to accept the pairing prompt on the TV.
      final ok = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _setConnected(false);
          return false;
        },
      );

      if (!ok) await disconnect();
      return ok;
    } catch (_) {
      _setConnected(false);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _setConnected(false);
    _completePointerRequest(null);
    await _pointerSub?.cancel();
    _pointerSub = null;
    await _pointerChannel?.sink.close();
    _pointerChannel = null;
    _pointerChannelFuture = null;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  Future<void> sendKey(RemoteKey key) async {
    if (!_connected || _channel == null) return;

    _commandId++;

    // App launches use ssap://system.launcher/launch with an app ID payload.
    final appId = _getAppId(key);
    if (appId != null) {
      final msg = jsonEncode({
        'id': 'command_$_commandId',
        'type': 'request',
        'uri': 'ssap://system.launcher/launch',
        'payload': {'id': appId},
      });
      _channel!.sink.add(msg);
      return;
    }

    final buttonName = _mapKeyToButtonName(key);
    if (buttonName != null) {
      final pointer = await _ensurePointerChannel();
      pointer?.sink.add('type:button\nname:$buttonName\n\n');
      return;
    }

    final uri = _mapKeyToUri(key);
    if (uri == null) return;

    final msg = jsonEncode({
      'id': 'command_$_commandId',
      'type': 'request',
      'uri': uri,
    });
    _channel!.sink.add(msg);
  }

  Future<WebSocketChannel?> _ensurePointerChannel() {
    final existing = _pointerChannel;
    if (existing != null) return Future.value(existing);

    return _pointerChannelFuture ??= _openPointerChannel().whenComplete(() {
      _pointerChannelFuture = null;
    });
  }

  Future<WebSocketChannel?> _openPointerChannel() async {
    final controlChannel = _channel;
    if (!_connected || controlChannel == null) return null;

    _commandId++;
    final requestId = 'pointer_socket_$_commandId';
    final pathCompleter = Completer<String?>();
    _pointerRequestId = requestId;
    _pointerSocketPath = pathCompleter;

    controlChannel.sink.add(
      jsonEncode({
        'id': requestId,
        'type': 'request',
        'uri': 'ssap://com.webos.service.networkinput/getPointerInputSocket',
      }),
    );

    final socketPath = await pathCompleter.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
    if (identical(_pointerSocketPath, pathCompleter)) {
      _pointerSocketPath = null;
      _pointerRequestId = null;
    }
    if (socketPath == null || !_connected) return null;

    try {
      final pointer = WebSocketChannel.connect(Uri.parse(socketPath));
      await pointer.ready;
      _pointerChannel = pointer;
      _pointerSub = pointer.stream.listen(
        (_) {},
        onError: (_) => _clearPointerChannel(pointer),
        onDone: () => _clearPointerChannel(pointer),
      );
      return pointer;
    } catch (_) {
      return null;
    }
  }

  void _clearPointerChannel(WebSocketChannel pointer) {
    if (!identical(_pointerChannel, pointer)) return;
    _pointerChannel = null;
    _pointerSub = null;
  }

  void _completePointerRequest(String? socketPath) {
    final pending = _pointerSocketPath;
    if (pending != null && !pending.isCompleted) pending.complete(socketPath);
    _pointerSocketPath = null;
    _pointerRequestId = null;
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    onConnectionStateChanged?.call();
  }

  /// Returns the LG webOS app ID for keys that launch apps, null otherwise.
  String? _getAppId(RemoteKey key) {
    const map = {
      RemoteKey.netflix: 'netflix',
      RemoteKey.youtube: 'youtube.leanback.v4',
      RemoteKey.prime: 'amazon',
      RemoteKey.disneyPlus: 'com.disney.disneyplus-prod',
      RemoteKey.source: 'com.webos.app.inputpicker',
    };
    return map[key];
  }

  String? _mapKeyToUri(RemoteKey key) {
    const map = {
      RemoteKey.power: 'ssap://system/turnOff',
      RemoteKey.volumeUp: 'ssap://audio/volumeUp',
      RemoteKey.volumeDown: 'ssap://audio/volumeDown',
      RemoteKey.channelUp: 'ssap://tv/channelUp',
      RemoteKey.channelDown: 'ssap://tv/channelDown',
      RemoteKey.play: 'ssap://media.controls/play',
      RemoteKey.pause: 'ssap://media.controls/pause',
      RemoteKey.stop: 'ssap://media.controls/stop',
      RemoteKey.rewind: 'ssap://media.controls/rewind',
      RemoteKey.fastForward: 'ssap://media.controls/fastForward',
    };

    return map[key];
  }

  String? _mapKeyToButtonName(RemoteKey key) {
    const map = {
      RemoteKey.up: 'UP',
      RemoteKey.down: 'DOWN',
      RemoteKey.left: 'LEFT',
      RemoteKey.right: 'RIGHT',
      RemoteKey.enter: 'ENTER',
      RemoteKey.back: 'BACK',
      RemoteKey.home: 'HOME',
      RemoteKey.menu: 'MENU',
      RemoteKey.mute: 'MUTE',
      RemoteKey.num0: '0',
      RemoteKey.num1: '1',
      RemoteKey.num2: '2',
      RemoteKey.num3: '3',
      RemoteKey.num4: '4',
      RemoteKey.num5: '5',
      RemoteKey.num6: '6',
      RemoteKey.num7: '7',
      RemoteKey.num8: '8',
      RemoteKey.num9: '9',
    };
    return map[key];
  }

  Map<String, dynamic> _buildRegistrationPayload(String? clientKey) {
    return {
      'type': 'register',
      'id': 'register_0',
      'payload': {
        'forcePairing': false,
        'pairingType': 'PROMPT',
        if (clientKey != null) 'client-key': clientKey,
        'manifest': {
          'manifestVersion': 1,
          'appVersion': '1.0.0',
          'signed': {
            'created': '20240101',
            'appId': 'com.universalremote',
            'vendorId': 'com.universalremote',
          },
          'permissions': [
            'LAUNCH',
            'LAUNCH_WEBAPP',
            'APP_TO_APP',
            'CLOSE',
            'TEST_OPEN',
            'TEST_PROTECTED',
            'CONTROL_AUDIO',
            'CONTROL_DISPLAY',
            'CONTROL_INPUT_JOYSTICK',
            'CONTROL_INPUT_MEDIA_RECORDING',
            'CONTROL_INPUT_MEDIA_PLAYBACK',
            'CONTROL_INPUT_TV',
            'CONTROL_POWER',
            'READ_APP_STATUS',
            'READ_CURRENT_CHANNEL',
            'READ_INPUT_DEVICE_LIST',
            'READ_NETWORK_STATE',
            'READ_RUNNING_APPS',
            'READ_TV_CHANNEL_LIST',
            'WRITE_NOTIFICATION_TOAST',
            'CONTROL_INPUT_TEXT',
            'CONTROL_MOUSE_AND_KEYBOARD',
            'READ_INSTALLED_APPS',
            'READ_LGE_TV_INPUT_EVENTS',
            'READ_TV_CURRENT_TIME',
          ],
        },
      },
    };
  }
}
