/// ArcGIS Maps SDK for JavaScript - Point geometry
/// 
/// A location defined by X, Y, and optionally Z coordinates.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Point.html
import 'dart:js_interop';

/// Point geometry for ArcGIS JS API
@JS("esri.geometry.Point")
extension type JsPoint._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
  external double? get z;
  external factory JsPoint(JSObject properties);
}