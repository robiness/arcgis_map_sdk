/// ArcGIS Maps SDK for JavaScript - Handle and event handling
///
/// Event handling utilities for the ArcGIS JS API.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Handles.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';

/// Event handling
@JS()
extension type JsHandle._(JSObject _) implements JSObject {
  external void remove();
}

/// Hit test results
@JS()
extension type JsHitTestResult._(JSObject _) implements JSObject {
  external JSArray<JsHitTestResultItem>? get results;
}

/// Hit test result item
@JS()
extension type JsHitTestResultItem._(JSObject _) implements JSObject {
  external JSObject? get graphic;
  external JsPoint get point;
}
