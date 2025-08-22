/// ArcGIS Maps SDK for JavaScript - Polygon geometry
/// 
/// An array of rings where each ring is an array of points.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Polygon.html
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/geometry.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';

/// Polygon geometry for ArcGIS JS API
@JS("esri.geometry.Polygon")
extension type JsPolygon._(JSObject _) implements JsGeometry {
  external factory JsPolygon(JSObject properties);
  external JSArray<JSArray<JSArray<JSNumber>>> get rings;
  external set rings(JSArray<JSArray<JSArray<JSNumber>>> value);
  external bool contains(JsPoint point);
}