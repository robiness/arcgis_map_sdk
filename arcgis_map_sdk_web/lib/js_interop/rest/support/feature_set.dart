/// ArcGIS Maps SDK for JavaScript - FeatureSet and Edit Results
///
/// Feature set and edit result classes for REST operations.
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-support-FeatureSet.html
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/core/collection.dart';

/// Feature set for queries
@JS("esri.rest.support.FeatureSet")
extension type JsFeatureSet._(JSObject _) implements JSObject {
  external JsCollection<JSObject>? get features;
}

/// Edit results for feature layer operations
@JS()
extension type JsEditsResult._(JSObject _) implements JSObject {
  external JSObject get addFeatureResults;
  external JSObject get updateFeatureResults;
  external JSObject get deleteFeatureResults;
}
