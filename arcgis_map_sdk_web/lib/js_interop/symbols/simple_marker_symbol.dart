/// ArcGIS Maps SDK for JavaScript - SimpleMarkerSymbol
///
/// A symbol used to visualize points.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-symbols-SimpleMarkerSymbol.html
library;

import 'dart:js_interop';

/// Simple marker symbol for point visualization
@JS("esri.symbols.SimpleMarkerSymbol")
extension type JsSimpleMarkerSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleMarkerSymbol(JSObject properties);
  external String get type;
  external String get style;
  external set style(String value);
  external double get size;
  external set size(double value);
  external JSObject get color;
  external set color(JSObject value);
}
