/// ArcGIS Maps SDK for JavaScript - Polyline geometry
///
/// An array of paths where each path is an array of points.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Polyline.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/geometry.dart';

/// Polyline geometry for ArcGIS JS API
@JS("esri.geometry.Polyline")
extension type JsPolyline._(JSObject _) implements JsGeometry {
  external factory JsPolyline(JSObject properties);
  external JSArray<JSArray<JSArray<JSNumber>>> get paths;
  external set paths(JSArray<JSArray<JSArray<JSNumber>>> value);
}
