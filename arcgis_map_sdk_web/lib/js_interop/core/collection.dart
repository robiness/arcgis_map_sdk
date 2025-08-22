/// ArcGIS Maps SDK for JavaScript - Collection class
/// 
/// A generic collection class used throughout the ArcGIS Maps SDK.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Collection.html
import 'dart:js_interop';

/// Collection type for graphics and layers
@JS("esri.core.Collection")
extension type JsCollection<T extends JSAny?>._(JSObject _)
    implements JSObject {
  external int get length;
  external T? getItemAt(int index);
  external void add(T item, [int? index]);
  external T? remove(T item);
  external void removeAll();
  external JSArray<T> toArray();
  external T? find(JSFunction callback);
  external JsCollection<T>? filter(JSFunction callback);
  external int findIndex(JSFunction callback);
  external void forEach(JSFunction callback);
  external void removeAt(int index);
  external void removeMany(JsCollection<T>? items);
  external void addMany(JSArray<T> items, [int? index]);
}