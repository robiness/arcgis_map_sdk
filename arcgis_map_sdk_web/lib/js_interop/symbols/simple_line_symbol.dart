/// ArcGIS Maps SDK for JavaScript - SimpleLineSymbol
/// 
/// A symbol used to visualize polylines.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-symbols-SimpleLineSymbol.html
import 'dart:js_interop';

/// Simple line symbol for polyline visualization
@JS("esri.symbols.SimpleLineSymbol")
extension type JsSimpleLineSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleLineSymbol(JSObject properties);
  external String get type;
  external String get style;
  external set style(String value);
  external double get width;
  external set width(double value);
  external JSObject get color;
  external set color(JSObject value);
}