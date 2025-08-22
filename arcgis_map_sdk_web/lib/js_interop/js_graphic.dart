/// ArcGIS Maps SDK for JavaScript - Graphic class
/// 
/// Contains the Graphic class for displaying graphics on the map.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/geometry/geometry.dart';

/// Graphics with complete API
@JS("esri.Graphic")
extension type JsGraphic._(JSObject _) implements JSObject {
  external JsGeometry? get geometry;
  external set geometry(JsGeometry? value);
  external JSObject? get attributes;
  external set attributes(JSObject? value);
  external JSObject? get symbol;
  external set symbol(JSObject? value);
  external JSObject? get popupTemplate;
  external set popupTemplate(JSObject? value);
  external JsGraphic clone();
  external JSObject toJSON();
  external factory JsGraphic(JSObject properties);
}
