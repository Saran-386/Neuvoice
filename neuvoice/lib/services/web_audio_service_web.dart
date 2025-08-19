@JS()
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:html' as html; // Import dart:html for globalThis
import 'package:flutter/foundation.dart';
import 'package:js/js_util.dart' show allowInterop;
import 'package:js/js_util.dart'
    as js_util; // Import js_util for JS interop helpers

/// Service for capturing audio in a Flutter Web app using Web Audio API.
class WebAudioServiceWeb {
  late final JSObject _audioContext;
  JSObject? _processorNode;
  final StreamController<Float32List> _audioStreamController =
      StreamController.broadcast();

  Stream<Float32List> get audioStream => _audioStreamController.stream;

  Future<void> init() async {
    _audioContext = _createAudioContext();
    if (kDebugMode) {
      print('🎙️ WebAudio context created');
    }
  }

  JSObject _createAudioContext() {
    // Get the JS 'window' object
    final jsWindow = js_util.getProperty(html.window, 'window') as JSObject;
    // Get the AudioContext constructor function
    final audioCtxCtor =
        js_util.getProperty(jsWindow, 'AudioContext') as JSFunction;
    // Call constructor to create AudioContext instance
    return js_util.callConstructor(audioCtxCtor, const []) as JSObject;
  }

  Future<void> start({int bufferSize = 4096}) async {
    final nav = js_util.getProperty(html.window, 'navigator') as JSObject;
    final mediaDevices = js_util.getProperty(nav, 'mediaDevices') as JSObject;
    final getUserMedia =
        js_util.getProperty(mediaDevices, 'getUserMedia') as JSFunction;

    final constraints = <String, bool>{'audio': true};
    // Convert Dart Map to JS object
    final jsConstraints = js_util.jsify(constraints) as JSObject;

    // Request microphone access
    final promise = js_util
        .callMethod<JSPromise>(mediaDevices, 'getUserMedia', [jsConstraints]);
    final stream = await js_util.promiseToFuture<JSObject>(promise);

    // Create ScriptProcessorNode
    final processorCtor = js_util.getProperty(
        _audioContext, 'createScriptProcessor') as JSFunction;
    _processorNode = js_util.callMethod(
        _audioContext, 'createScriptProcessor', [bufferSize, 1, 1]) as JSObject;

    void onAudioProcess(JSObject event) {
      final inputBuffer = js_util.getProperty(event, 'inputBuffer') as JSObject;
      final channelDataFn =
          js_util.getProperty(inputBuffer, 'getChannelData') as JSFunction;
      final channelData =
          js_util.callMethod<Float32List>(inputBuffer, 'getChannelData', [0]);
      _audioStreamController.add(channelData);
    }

    // Set onaudioprocess event handler
    js_util.setProperty(
        _processorNode!, 'onaudioprocess', allowInterop(onAudioProcess));

    // Connect nodes: connect the microphone stream to the processor node
    final sources =
        js_util.callMethod(_audioContext, 'createMediaStreamSource', [stream])
            as JSObject;
    js_util.callMethod(sources, 'connect', [_processorNode!]);
    js_util.callMethod(_processorNode!, 'connect',
        [js_util.getProperty(_audioContext, 'destination') as JSObject]);
  }

  void stop() {
    if (_processorNode != null) {
      js_util.callMethod(_processorNode!, 'disconnect', []);
      _processorNode = null;
    }
    if (kDebugMode) {
      print('🛑 WebAudio stopped');
    }
  }
}
