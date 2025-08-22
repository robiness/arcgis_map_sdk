/// Main export file for all ArcGIS JavaScript interop definitions
/// 
/// This file provides a clean, modular structure for JavaScript interop with
/// the ArcGIS Maps SDK for JavaScript. It replaces the monolithic approach
/// with properly typed, organized definitions.

// Core definitions
export 'definitions.dart';
export 'js_graphic.dart';

// Views
export 'arcgis_map.dart';
export 'arcgis_scene.dart';

// Layers
export 'layers/js_graphics_layer.dart';
export 'layers/js_feature_layer.dart';
export 'layers/js_scene_layer.dart';

// Widgets
export 'widgets/attribution.dart';