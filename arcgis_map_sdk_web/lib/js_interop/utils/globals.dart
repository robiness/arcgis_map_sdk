/// ArcGIS Maps SDK for JavaScript - Global utilities
/// 
/// Global functions and utilities for the ArcGIS JS API.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri.html
import 'dart:js_interop';

/// Global functions and utilities
@JS("JSON.stringify")
external String jsonStringify(JSAny value);

@JS('window._arcgisModulesReady')
external JSAny? get arcgisModulesReady;

/// Global ArcGIS CDN loader exposed by `<script src="https://js.arcgis.com/4.x/">`
/// since version 4.32. Provides a Promise-based [JsArcgisLoader.importModules]
/// for resolving module exports without inline JS.
///
/// @see https://developers.arcgis.com/javascript/latest/get-started-cdn/
@JS(r'window.$arcgis')
external JsArcgisLoader? get arcgisLoader;

extension type JsArcgisLoader._(JSObject _) implements JSObject {
  @JS('import')
  external JSPromise<JSArray<JSObject>> importModules(JSArray<JSString> paths);
}

@JS('esri')
external JSObject get esri;

@JS('esriConfig')
external JSObject get esriConfig;

@JS('Object.defineProperty')
external void defineProperty(JSObject obj, String name, JSObject descriptor);

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