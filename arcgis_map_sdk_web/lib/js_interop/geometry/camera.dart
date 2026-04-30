/// ArcGIS Maps SDK for JavaScript - Camera and Viewpoint
///
/// Camera positioning and viewpoint classes for 3D views.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-Camera.html
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-Viewpoint.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/geometry.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';

/// Camera types for 3D views
@JS("esri.Camera")
extension type JsCamera._(JSObject _) implements JSObject {
  external JsPoint get position;
  external set position(JsPoint value);
  external double get heading;
  external set heading(double value);
  external double get tilt;
  external set tilt(double value);
  external double get fov;
  external set fov(double value);
  external JsPoint get point;
  external factory JsCamera(JSObject properties);
}

/// Viewpoint for camera positioning
@JS("esri.Viewpoint")
extension type JsViewpoint._(JSObject _) implements JSObject {
  external factory JsViewpoint(JSObject properties);
  external JsCamera get camera;
  external set camera(JsCamera value);
  external double get rotation;
  external set rotation(double value);
  external double get scale;
  external set scale(double value);
  external JsGeometry get targetGeometry;
  external set targetGeometry(JsGeometry value);
}
