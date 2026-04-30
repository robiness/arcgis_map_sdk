/// ArcGIS Maps SDK for JavaScript - Base Geometry class
///
/// Contains the base Geometry class for all geometry types.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Geometry.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/extent.dart';

/// Base geometry interface
@JS("esri.geometry.Geometry")
extension type JsGeometry._(JSObject _) implements JSObject {
  /// Geometry kind discriminator: 'point', 'polyline', 'polygon', etc.
  external String get type;
  external JsExtent? get extent;
}
