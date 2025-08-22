/// ArcGIS Maps SDK for JavaScript - SimpleFillSymbol
/// 
/// A symbol used to visualize polygons.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-symbols-SimpleFillSymbol.html
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/symbols/simple_line_symbol.dart';

/// Simple fill symbol for polygon visualization
@JS("esri.symbols.SimpleFillSymbol")
extension type JsSimpleFillSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleFillSymbol(JSObject properties);
  external String get type;
  external String get style;
  external set style(String value);
  external JSObject get color;
  external set color(JSObject value);
  external JsSimpleLineSymbol? get outline;
  external set outline(JsSimpleLineSymbol? value);
}