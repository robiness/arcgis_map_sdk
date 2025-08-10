import 'dart:js_interop';

@JS('esri.Map')
extension type EsriMap._(JSObject _) implements JSObject {
  external factory EsriMap(JSObject properties);
}

@JS('esri.views.MapView')
extension type MapView._(JSObject _) implements JSObject {
  external factory MapView(JSObject properties);

  external EsriMap get map;
  external set map(EsriMap map);

  external double get zoom;
  external set zoom(double zoom);

  external JSObject get center;
  external set center(JSObject center);
}
