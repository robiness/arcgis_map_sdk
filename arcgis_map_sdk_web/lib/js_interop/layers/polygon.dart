import 'dart:js_interop';

@JS('esri/geometry/Polygon')
class Polygon {
  external Polygon(JSObject properties);

  external bool contains(JSObject point);
}

@JS('esri/geometry/Point')
class Point {
  external Point(JSObject properties);

  external num get latitude;
  external set latitude(num value);

  external num get longitude;
  external set longitude(num value);
}
