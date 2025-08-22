import 'dart:js_interop';
import '../arcgis_map.dart';

/// Scene Layer with complete API
@JS("esri.layers.SceneLayer")
extension type JsSceneLayer._(JSObject _) implements JsLayer {
  external factory JsSceneLayer(JSObject properties);
  
  external String get id;
  external set id(String value);
  external String get title;
  external set title(String value);
  external String get type;
  external String get url;
  external set url(String value);
  external bool get visible;
  external set visible(bool value);
  external double get opacity;
  external set opacity(double value);
  
  // 3D specific
  external JSObject? get elevationInfo;
  external set elevationInfo(JSObject? value);
  external JSObject? get popupTemplate;
  external set popupTemplate(JSObject? value);
  
  // Loading and lifecycle
  external String get loadStatus;
  external JSPromise<JSObject> load();
  external void destroy();
}

/// Global constructor helpers for layers
@JS('window.SceneLayer')
external JSFunction? get sceneLayerConstructor;

@JS('window.SceneLayer')
external JsSceneLayer createSceneLayer(JSObject options);

@JS('window.GraphicsLayer')
external JSFunction? get graphicsLayerConstructor;

@JS('window.FeatureLayer')
external JSFunction? get featureLayerConstructor;