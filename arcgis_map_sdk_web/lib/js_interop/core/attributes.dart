/// ArcGIS Maps SDK for JavaScript - Attributes
///
/// Attribute handling for features and graphics.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-support-Field.html
library;

import 'dart:js_interop';

/// Attributes for graphics and features
@JS()
extension type JsAttributes._(JSObject _) implements JSObject {
  external String? get id;
  external String? get name;
}
