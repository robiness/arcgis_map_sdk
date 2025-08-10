import 'dart:js_interop';

@JS('esri.layers.GraphicsLayer')
extension type JsGraphicsLayer._(JSObject _) implements JSObject {
  external factory JsGraphicsLayer(JSObject properties);
}
