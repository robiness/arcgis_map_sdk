import 'dart:js_interop';

@JS('esri.views.SceneView')
extension type SceneView._(JSObject _) implements JSObject {
  external factory SceneView(JSObject properties);

  external JSObject get camera;
  external set camera(JSObject camera);
}
