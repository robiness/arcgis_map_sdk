/// ArcGIS Maps SDK for JavaScript - Global utilities
/// 
/// Global functions and utilities for the ArcGIS JS API.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri.html
import 'dart:js_interop';

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