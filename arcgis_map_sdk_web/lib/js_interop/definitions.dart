import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/js_graphic.dart';

/// Core geometry types for ArcGIS JS API
@JS("esri.geometry.Point")
extension type JsPoint._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
  external double? get z;
  external factory JsPoint(JSObject properties);
}

@JS("esri.geometry.Extent")
extension type JsExtent._(JSObject _) implements JSObject {
  external JsPoint get center;
  external double get height;
  external double get width;
  external double get xmin;
  external double get ymin;
  external double get xmax;
  external double get ymax;
  external factory JsExtent(JSObject properties);
}

@JS("esri.geometry.Geometry")
extension type JsGeometry._(JSObject _) implements JSObject {
  external JsExtent? get extent;
}

@JS("esri.geometry.Polygon")
extension type JsPolygon._(JSObject _) implements JsGeometry {
  external factory JsPolygon(JSObject properties);
  external JSArray<JSArray<JSArray<JSNumber>>> get rings;
  external set rings(JSArray<JSArray<JSArray<JSNumber>>> value);
  external bool contains(JsPoint point);
}

@JS("esri.geometry.Polyline")
extension type JsPolyline._(JSObject _) implements JsGeometry {
  external factory JsPolyline(JSObject properties);
  external JSArray<JSArray<JSArray<JSNumber>>> get paths;
  external set paths(JSArray<JSArray<JSArray<JSNumber>>> value);
}

/// Camera types for 3D views
@JS("esri.Camera")
extension type JsCamera._(JSObject _) implements JSObject {
  external JsPoint get position;
  external set position(JsPoint value);
  external double get heading;
  external set heading(double value);
  external double get tilt;
  external set tilt(double value);
  external double get fov;
  external set fov(double value);
  external JsPoint get point;
  external factory JsCamera(JSObject properties);
}

/// Viewpoint for camera positioning
@JS("esri.Viewpoint")
extension type JsViewpoint._(JSObject _) implements JSObject {
  external factory JsViewpoint(JSObject properties);
  external JsCamera get camera;
  external set camera(JsCamera value);
  external double get rotation;
  external set rotation(double value);
  external double get scale;
  external set scale(double value);
  external JsGeometry get targetGeometry;
  external set targetGeometry(JsGeometry value);
}

/// Event handling
@JS()
extension type JsHandle._(JSObject _) implements JSObject {
  external void remove();
}

/// Collection type for graphics and layers
@JS("esri.core.Collection")
extension type JsCollection<T extends JSAny?>._(JSObject _)
    implements JSObject {
  external int get length;
  external T? getItemAt(int index);
  external void add(T item, [int? index]);
  external T? remove(T item);
  external void removeAll();
  external JSArray<T> toArray();
  external T? find(JSFunction callback);
  external JsCollection<T>? filter(JSFunction callback);
  external int findIndex(JSFunction callback);
  external void forEach(JSFunction callback);
  external void removeAt(int index);
  external void removeMany(JsCollection<T>? items);
  external void addMany(JSArray<T> items, [int? index]);
}

@JS()
extension type JsAttributes._(JSObject _) implements JSObject {
  external String? get id;
  external String? get name;
}

/// Hit test results
@JS()
extension type JsHitTestResult._(JSObject _) implements JSObject {
  external JSArray<JsHitTestResultItem>? get results;
}

@JS()
extension type JsHitTestResultItem._(JSObject _) implements JSObject {
  external JsGraphic? get graphic;
  external JsPoint get point;
}

/// Feature set for queries
@JS("esri.rest.support.FeatureSet")
extension type JsFeatureSet._(JSObject _) implements JSObject {
  external JsCollection<JsGraphic>? get features;
}

/// Edit results for feature layer operations
@JS()
extension type JsEditsResult._(JSObject _) implements JSObject {
  external JSObject get addFeatureResults;
  external JSObject get updateFeatureResults;
  external JSObject get deleteFeatureResults;
}

/// Symbol types
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

/// Global functions and utilities
@JS("JSON.stringify")
external String jsonStringify(JSAny value);

@JS('require')
external JSFunction get require;

@JS('require.config')
external void requireConfig(JSObject config);

@JS('window._arcgisModulesReady')
external JSAny? get arcgisModulesReady;

@JS('esri')
external JSObject get esri;

@JS('esriConfig')
external JSObject get esriConfig;

@JS('Object.defineProperty')
external void defineProperty(JSObject obj, String name, JSObject descriptor);

@JS('Function')
external JSFunction createFunction(JSString code);

@JS('window')
external JSObject get window;

@JS('Reflect.get')
external JSAny? getProperty(JSObject obj, JSString key);

@JS('Reflect.set')
external void setProperty(JSObject obj, JSString key, JSAny? value);

/// Helper extension for JSObject property access
extension JSObjectExtensions on JSObject {
  JSAny? operator [](String key) {
    return getProperty(this, key.toJS);
  }

  void operator []=(String key, JSAny? value) {
    setProperty(this, key.toJS, value);
  }
}
