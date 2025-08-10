import 'dart:js_interop';

@JS('esri/layers/FeatureLayer')
class JsFeatureLayer {
  external JsFeatureLayer(JSObject properties);
}
