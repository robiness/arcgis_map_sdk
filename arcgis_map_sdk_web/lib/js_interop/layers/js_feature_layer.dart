/// ArcGIS Maps SDK for JavaScript - FeatureLayer class
///
/// Contains the FeatureLayer class for displaying and managing feature data.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-FeatureLayer.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/arcgis_map.dart';
import 'package:arcgis_map_sdk_web/js_interop/core/collection.dart';
import 'package:arcgis_map_sdk_web/js_interop/js_graphic.dart';
import 'package:arcgis_map_sdk_web/js_interop/rest/support/feature_set.dart';

/// Feature Layer with complete API
@JS("esri.layers.FeatureLayer")
extension type JsFeatureLayer._(JSObject _) implements JsLayer {
  external factory JsFeatureLayer(JSObject properties);

  external String get id;
  external set id(String value);
  external String get title;
  external set title(String value);
  external String get type;
  external String? get url;
  external set url(String? value);
  external bool get visible;
  external set visible(bool value);
  external double get opacity;
  external set opacity(double value);

  // Feature management
  external JsCollection<JsGraphic>? get source;
  external set source(JsCollection<JsGraphic>? value);
  external JSArray<JSObject>? get fields;
  external set fields(JSArray<JSObject>? value);
  external String? get objectIdField;
  external set objectIdField(String? value);
  external String? get geometryType;
  external set geometryType(String? value);

  // Queries and edits
  external JSPromise<JsFeatureSet> queryFeatures([JSObject? query]);
  external JSPromise<JsEditsResult> applyEdits(JSObject edits);

  // Rendering
  external JSObject? get renderer;
  external set renderer(JSObject? value);
  external JSObject? get labelingInfo;
  external set labelingInfo(JSObject? value);

  // Loading and lifecycle
  external String get loadStatus;
  external JSPromise<JSObject> load();
  external void destroy();
}
