/// ArcGIS Maps SDK for JavaScript - SceneView classes
///
/// Contains 3D scene view implementations for the ArcGIS JS API.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-views-SceneView.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/arcgis_map.dart';
import 'package:arcgis_map_sdk_web/js_interop/core/handles.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/camera.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/extent.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';

/// SceneView (3D) with complete API
@JS("esri.views.SceneView")
extension type JsSceneView._(JSObject _) implements JsView {
  external factory JsSceneView(JSObject properties);

  // Core properties
  external JsEsriMap get map;
  external set map(JsEsriMap value);
  external JSObject? get container;
  external set container(JSObject? value);
  external JsExtent? get extent;
  external JsPoint get center;
  external double get zoom;
  external double get scale;
  external JSObject get padding;
  external set padding(JSObject value);

  // 3D specific
  external JsCamera get camera;
  external set camera(JsCamera value);
  external String get viewingMode;
  external set viewingMode(String value);

  // UI and interaction
  external JsDefaultUI get ui;
  external JSObject? get popup;
  external set popup(JSObject? value);

  // Navigation and viewpoint
  external JsViewpoint get viewpoint;
  external set viewpoint(JsViewpoint value);
  external JSPromise<JSObject?> goTo(JSObject target, [JSObject? options]);

  // Hit testing and events
  external JSPromise<JsHitTestResult> hitTest(JSObject event, [JSObject? options]);
  external JsHandle on(JSAny event, JSFunction handler);

  // Export and screenshot
  external JSPromise<JSObject> takeScreenshot([JSObject? options]);

  // Navigation controls
  external JsNavigation get navigation;

  // Environment (lighting, atmosphere)
  external JsEnvironment get environment;
  external set environment(JsEnvironment value);
}

/// Environment settings for SceneView
@JS("esri.views.SceneView.Environment")
extension type JsEnvironment._(JSObject _) implements JSObject {
  external JSObject get lighting;
  external set lighting(JSObject value);
  external JSObject get atmosphere;
  external set atmosphere(JSObject value);
  external JSObject? get background;
  external set background(JSObject? value);
}
