/// ArcGIS Maps SDK for JavaScript - Extent geometry
/// 
/// The minimum and maximum X and Y coordinates of a bounding box.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';

/// Extent geometry for ArcGIS JS API
@JS("esri.geometry.Extent")
extension type JsExtent._(JSObject _) implements JSObject {
  external JsPoint get center;
  external double get height;
  external double get width;
  external double get xmin;
  external double get ymin;
  external double get xmax;
  external double get ymax;
  external JSObject get spatialReference;
  external factory JsExtent(JSObject properties);
}