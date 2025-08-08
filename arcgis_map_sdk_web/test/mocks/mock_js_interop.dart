import 'dart:async';
import 'dart:js_interop';

/// Helper function to safely convert JS objects to Dart maps
dynamic _convertJsObjectToDart(dynamic jsObject) {
  if (jsObject == null) return null;
  
  try {
    // Try to call dartify if it exists
    if (jsObject is JSObject) {
      final dartified = jsObject.dartify();
      if (dartified is Map<Object?, Object?>) {
        return dartified.map((key, value) => MapEntry(
          key.toString(), 
          _convertJsObjectToDart(value),
        ));
      } else if (dartified is List<Object?>) {
        return dartified.map((item) => _convertJsObjectToDart(item)).toList();
      } else {
        return dartified;
      }
    } else {
      return jsObject;
    }
  } catch (e) {
    // If dartify fails, return a safe representation
    return jsObject.toString();
  }
}

/// Mock implementation of JsView for testing
@JSExport()
class FakeJsView {
  double _zoom = 2.0;
  final List<Map<String, dynamic>> _capturedCalls = [];
  final Map<String, dynamic> _properties = {};

  @JSExport('zoom')
  double get zoom => _zoom;

  @JSExport('zoom')
  set zoom(double value) {
    _zoom = value;
  }

  @JSExport('goTo')
  JSPromise<JSObject?> goTo(JSObject target, [JSObject? options]) {
    _capturedCalls.add({
      'method': 'goTo',
      'target': _convertJsObjectToDart(target),
      'options': _convertJsObjectToDart(options),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Simulate successful navigation
    return Future.value(null).toJS;
  }

  @JSExport('map')
  JSObject get map => _properties['map'] as JSObject? ?? createMockMap().jsify() as JSObject;

  // Utility methods for testing (not exported to JS)
  List<Map<String, dynamic>> getCapturedCalls() => List.from(_capturedCalls);

  Map<String, dynamic>? getLastCall() =>
      _capturedCalls.isEmpty ? null : _capturedCalls.last;

  Map<String, dynamic>? getLastCallForMethod(String method) {
    for (int i = _capturedCalls.length - 1; i >= 0; i--) {
      if (_capturedCalls[i]['method'] == method) {
        return _capturedCalls[i];
      }
    }
    return null;
  }

  void clearCapturedCalls() {
    _capturedCalls.clear();
  }

  void setProperty(String key, dynamic value) {
    _properties[key] = value;
  }

  Map<String, dynamic> createMockMap() => {
        'basemap': 'streets-navigation-vector',
        'layers': [],
      };
}

/// Mock implementation of JsMapViewEnhanced for testing
@JSExport()
class FakeJsMapViewEnhanced extends FakeJsView {
  @JSExport('takeScreenshot')
  JSPromise<JSObject> takeScreenshot([JSObject? options]) {
    final optionsMap = options?.dartify() as Map<Object?, Object?>?;
    _capturedCalls.add({
      'method': 'takeScreenshot',
      'options': optionsMap != null ? Map<String, dynamic>.from(optionsMap) : null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Return a mock screenshot result
    final result = {
      'dataUrl': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'width': 100,
      'height': 100,
    };
    return Future.value(result.jsify() as JSObject).toJS;
  }

  @JSExport('navigation')
  JSObject get navigation => {
        'enabled': true,
        'mouseWheelZoomEnabled': true,
        'browserTouchPanEnabled': true,
      }.jsify() as JSObject;

  @JSExport('padding')
  JSObject get padding => {
        'left': 0,
        'top': 0,
        'right': 0,
        'bottom': 0,
      }.jsify() as JSObject;

  @JSExport('padding')
  set padding(JSObject value) {
    final paddingMap = value.dartify() as Map<Object?, Object?>;
    _capturedCalls.add({
      'method': 'setPadding',
      'padding': Map<String, dynamic>.from(paddingMap),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    setProperty('padding', Map<String, dynamic>.from(paddingMap));
  }
}

/// Mock implementation of JsSceneViewEnhanced for testing
@JSExport()
class FakeJsSceneViewEnhanced extends FakeJsView {
  @JSExport('takeScreenshot')
  JSPromise<JSObject> takeScreenshot([JSObject? options]) {
    final optionsMap = options?.dartify() as Map<Object?, Object?>?;
    _capturedCalls.add({
      'method': 'takeScreenshot',
      'options': optionsMap != null ? Map<String, dynamic>.from(optionsMap) : null,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Return a mock screenshot result
    final result = {
      'dataUrl': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'width': 100,
      'height': 100,
    };
    return Future.value(result.jsify() as JSObject).toJS;
  }

  @JSExport('camera')
  JSObject get camera => {
        'position': {
          'longitude': -118.805,
          'latitude': 34.027,
          'z': 18161244,
        },
        'heading': 0,
        'tilt': 0.49,
      }.jsify() as JSObject;

  @JSExport('camera')
  set camera(JSObject value) {
    final cameraMap = value.dartify() as Map<Object?, Object?>;
    _capturedCalls.add({
      'method': 'setCamera',
      'camera': Map<String, dynamic>.from(cameraMap),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    setProperty('camera', Map<String, dynamic>.from(cameraMap));
  }

  @JSExport('navigation')
  JSObject get navigation => {
        'enabled': true,
        'mouseWheelZoomEnabled': true,
        'browserTouchPanEnabled': true,
      }.jsify() as JSObject;
}

/// Factory class for creating mock JS interop objects
class MockJsInteropFactory {
  static FakeJsView createMockView({bool isSceneView = false}) {
    return isSceneView
        ? FakeJsSceneViewEnhanced()
        : FakeJsMapViewEnhanced();
  }

  static JSObject createMockJsView({bool isSceneView = false}) {
    final fake = createMockView(isSceneView: isSceneView);
    return createJSInteropWrapper<FakeJsView>(fake);
  }
}