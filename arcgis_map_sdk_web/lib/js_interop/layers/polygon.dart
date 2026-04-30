/// ArcGIS Maps SDK for JavaScript - Legacy polygon definitions
///
/// ⚠️ DEPRECATED: This file contains duplicate geometry definitions.
/// Use the geometry types from '../geometry/' instead:
/// - JsPolygon for polygon geometry
/// - JsPoint for point geometry
///
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Polygon.html
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Point.html
library;

import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/polygon.dart';

// Re-export the proper geometry types from the organized structure
// This maintains backwards compatibility while encouraging migration to the correct types
typedef Polygon = JsPolygon;
typedef Point = JsPoint;
