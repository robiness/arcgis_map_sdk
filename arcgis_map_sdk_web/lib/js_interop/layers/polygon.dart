import 'dart:js_interop';

@JS('esri.geometry.Polygon')
extension type Polygon._(JSObject _) implements JSObject {
  external factory Polygon(JSObject properties);

  external bool contains(JSObject point);
}

@JS('esri.geometry.Point')
extension type Point._(JSObject _) implements JSObject {
  external factory Point(JSObject properties);

  external double get latitude;
  external set latitude(double value);

  external double get longitude;
  external set longitude(double value);
}
