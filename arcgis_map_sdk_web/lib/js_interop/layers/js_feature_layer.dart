import 'dart:js_interop';

@JS('esri.layers.FeatureLayer')
extension type JsFeatureLayer._(JSObject _) implements JSObject {
  external factory JsFeatureLayer(JSObject properties);
}
