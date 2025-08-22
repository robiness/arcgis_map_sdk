import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/js_graphic.dart';

import '../arcgis_map.dart';
import '../definitions.dart';

/// Graphics Layer with complete API
@JS("esri.layers.GraphicsLayer")
extension type JsGraphicsLayer._(JSObject _) implements JsLayer {
  external factory JsGraphicsLayer(JSObject properties);

  external String get id;
  external set id(String value);
  external String get title;
  external set title(String value);
  external String get type;
  external bool get visible;
  external set visible(bool value);
  external double get opacity;
  external set opacity(double value);

  // Graphics management
  external JsCollection<JsGraphic> get graphics;
  external void add(JsGraphic graphic);
  external void addMany(JSArray<JsGraphic> graphics);
  external JsGraphic? remove(JsGraphic graphic);
  external JSArray<JsGraphic> removeMany(JSArray<JsGraphic> graphics);
  external void removeAll();

  // Elevation
  external JSObject? get elevationInfo;
  external set elevationInfo(JSObject? value);

  // Loading and lifecycle
  external String get loadStatus;
  external JSPromise<JSObject> load();
  external void destroy();
}
