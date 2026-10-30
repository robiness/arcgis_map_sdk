/// ArcGIS Maps SDK for JavaScript - VectorTileLayer class
///
/// Contains the VectorTileLayer class, the layer type of vector basemaps and
/// of layers drawn from a Mapbox GL style.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-VectorTileLayer.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/arcgis_map.dart';

/// Vector tile layer
@JS("esri.layers.VectorTileLayer")
extension type JsVectorTileLayer._(JSObject _) implements JsLayer {
  external factory JsVectorTileLayer(JSObject properties);

  /// The style layer named [layerId], or null when the layer has none.
  external JSObject? getStyleLayer(String layerId);

  /// Shows (`'visible'`) or hides (`'none'`) the style layer named [layerId].
  /// Throws before the layer has loaded; ignores an unknown id after.
  external void setStyleLayerVisibility(String layerId, String visibility);

  /// Replaces the whole style with [style]. A call made before the previous
  /// one has finished rejects the previous one with an `AbortError`.
  external JSPromise<JSAny?> loadStyle(JSAny style);
}
