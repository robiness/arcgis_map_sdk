import 'dart:js_interop';

@JS('esri/views/SceneView')
class SceneView {
  external SceneView(JSObject properties);

  external JSObject get camera;
  external set camera(JSObject camera);
}
