/// Main export file for all ArcGIS JavaScript interop definitions
///
/// This file provides a clean, modular structure for JavaScript interop with
/// the ArcGIS Maps SDK for JavaScript. It follows the ArcGIS JS API namespace
/// organization for better maintainability and discoverability.
library;


// Views
export 'arcgis_map.dart';
export 'arcgis_scene.dart';
export 'core/attributes.dart';
// Core definitions (esri.core.*)
export 'core/collection.dart';
export 'core/handles.dart';
export 'core/reactive_utils.dart';
export 'geometry/camera.dart';
export 'geometry/extent.dart';
// Geometry definitions (esri.geometry.*)
export 'geometry/geometry.dart';
export 'geometry/point.dart';
export 'geometry/polygon.dart';
export 'geometry/polyline.dart';
// Graphics
export 'js_graphic.dart';
export 'layers/js_feature_layer.dart';
// Layers
export 'layers/js_graphics_layer.dart';
export 'layers/js_scene_layer.dart';
// REST support (esri.rest.support.*)
export 'rest/support/feature_set.dart';
export 'symbols/simple_fill_symbol.dart';
export 'symbols/simple_line_symbol.dart';
// Symbols (esri.symbols.*)
export 'symbols/simple_marker_symbol.dart';
// Utils and globals
export 'utils/globals.dart';
// Widgets
export 'widgets/attribution.dart';
