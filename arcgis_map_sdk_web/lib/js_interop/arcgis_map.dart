/// ArcGIS Maps SDK for JavaScript - Map and MapView classes
/// 
/// Contains 2D map and view implementations for the ArcGIS JS API.
/// 
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-Map.html
/// @see https://developers.arcgis.com/javascript/latest/api-reference/esri-views-MapView.html
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/js_graphic.dart';
import 'package:arcgis_map_sdk_web/js_interop/core/collection.dart';
import 'package:arcgis_map_sdk_web/js_interop/core/handles.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/extent.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/point.dart';
import 'package:arcgis_map_sdk_web/js_interop/geometry/camera.dart';

/// Base view interface
@JS("esri.views.View")
extension type JsView._(JSObject _) implements JSObject {
  external String get type;
  external double get zoom;
  external set padding(JSObject padding);
  external JSObject get padding;
  external JsHandle on(JSAny event, JSFunction callback);
  external JsHandle watch(String property, JSFunction callback);
  external JSPromise<JsHitTestResult> hitTest(JSObject event,
      [JSObject? options]);
  external JSPromise<JSObject?> goTo(JSObject target,
      [JSObject? targetOptions]);
  external JsCollection<JsGraphic> get graphics;
  external JsPoint get center;
  external set popup(JSObject? popup);
  external JSObject? get popup;
  external JSObject? get container;
  external set container(JSObject? value);
  external JsExtent? get extent;
  external JsEsriMap get map;
  external JsDefaultUI get ui;
}

/// Map (2D) with complete API
@JS("esri.Map")
extension type JsEsriMap._(JSObject _) implements JSObject {
  external factory JsEsriMap(JSObject properties);
  external JSObject get basemap;
  external set basemap(JSAny value);
  external JsCollection<JsLayer> get layers;
  external JsCollection<JsLayer> get allLayers;
  external String? get ground;
  external set ground(String? value);

  // Layer management
  external void add(JsLayer layer, [int? index]);
  external void addMany(JSArray<JsLayer> layers, [int? index]);
  external JsLayer? remove(JsLayer layer);
  external JSArray<JsLayer> removeMany(JSArray<JsLayer> layers);
  external void removeAll();
  external JSObject? findLayerById(String id);

  // Loading state
  external String get loadStatus;
  external JSPromise<JSObject> load();
  external JSPromise<JSObject> when([JSFunction? callback]);
}

/// MapView (2D) with complete API
@JS("esri.views.MapView")
extension type JsMapView._(JSObject _) implements JsView {
  external factory JsMapView(JSObject properties);

  // Core properties
  external JsEsriMap get map;
  external set map(JsEsriMap value);
  external JSObject? get container;
  external set container(JSObject? value);
  external JsExtent? get extent;
  external JsPoint get center;
  external double get zoom;
  external double get scale;
  external double get rotation;
  external JSObject get padding;
  external set padding(JSObject value);

  // UI and interaction
  external JsDefaultUI get ui;
  external JSObject? get popup;
  external set popup(JSObject? value);

  // Navigation and viewpoint
  external JsViewpoint get viewpoint;
  external set viewpoint(JsViewpoint value);
  external JSPromise<JSObject?> goTo(JSObject target, [JSObject? options]);

  // Hit testing and events
  external JSPromise<JsHitTestResult> hitTest(JSObject event,
      [JSObject? options]);
  external JsHandle on(JSAny event, JSFunction handler);

  // Export and screenshot
  external JSPromise<JSObject> takeScreenshot([JSObject? options]);

  // Navigation controls
  external JsNavigation get navigation;

  // Constraints
  external JsViewConstraints get constraints;
  external set constraints(JsViewConstraints value);
}

/// Default UI for views
@JS("esri.views.ui.DefaultUI")
extension type JsDefaultUI._(JSObject _) implements JSObject {
  external JSArray<JSString> get components;
  external set components(JSArray<JSString> value);
  external void add(JSObject widget, [JSString? position]);
  external void remove(JSObject widget);
}

/// Navigation control for views
@JS("esri.views.navigation.Navigation")
extension type JsNavigation._(JSObject _) implements JSObject {
  external bool get enabled;
  external set enabled(bool value);
  external bool get mouseWheelZoomEnabled;
  external set mouseWheelZoomEnabled(bool value);
  external bool get browserTouchPanEnabled;
  external set browserTouchPanEnabled(bool value);
}

/// View constraints
@JS("esri.views.ViewConstraints")
extension type JsViewConstraints._(JSObject _) implements JSObject {
  external JSObject? get geometry;
  external set geometry(JSObject? value);
  external double? get minZoom;
  external set minZoom(double? value);
  external double? get maxZoom;
  external set maxZoom(double? value);
  external double? get minScale;
  external set minScale(double? value);
  external double? get maxScale;
  external set maxScale(double? value);
}

/// Base layer interface
@JS("esri.layers.Layer")
extension type JsLayer._(JSObject _) implements JSObject {
  external String get id;
  external set id(String value);
  external String get type;
  external void destroy();
  external String? get url;
  external set url(String? value);
  external String get title;
  external set title(String value);
  external bool get visible;
  external set visible(bool value);
  external double get opacity;
  external set opacity(double value);
  external String get loadStatus;
  external JSPromise<JSObject> load();
}

/// Basemap with enhanced API
@JS("esri.Basemap")
extension type JsBasemap._(JSObject _) implements JSObject {
  external factory JsBasemap(JSObject properties);
  external String get id;
  external String get title;
  external JsCollection<JsLayer> get baseLayers;
  external JsCollection<JsLayer> get referenceLayers;
  external String get portalItem;
  external bool get loaded;
  external JSPromise<JSObject> load();
}
