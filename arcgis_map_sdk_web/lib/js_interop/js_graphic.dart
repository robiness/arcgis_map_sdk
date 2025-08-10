import 'dart:js_interop';

@JS('esri.Graphic')
extension type JsGraphic._(JSObject _) implements JSObject {
  external factory JsGraphic(JSObject properties);

  external JSObject get symbol;
  external set symbol(JSObject symbol);
}
