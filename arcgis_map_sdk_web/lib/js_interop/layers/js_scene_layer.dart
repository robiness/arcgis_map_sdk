import 'dart:js_interop';

@JS('esri.layers.SceneLayer')
extension type JsSceneLayer._(JSObject _) implements JSObject {
  external factory JsSceneLayer(JSObject properties);
}
