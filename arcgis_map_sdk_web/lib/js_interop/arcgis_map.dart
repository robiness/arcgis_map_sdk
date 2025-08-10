import 'dart:js_interop';

@JS('esri/Map')
class EsriMap {
  external EsriMap(JSObject properties);
}

@JS('esri/views/MapView')
class MapView {
  external MapView(JSObject properties);

  external EsriMap get map;
  external set map(EsriMap map);

  external JSNumber get zoom;
  external set zoom(JSNumber zoom);

  external JSObject get center;
  external set center(JSObject center);
}
