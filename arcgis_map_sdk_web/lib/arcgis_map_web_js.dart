import 'dart:js_interop';

export 'package:arcgis_map_sdk_web/src/arcgis_map_sdk_web.dart';

//
@JS("JSON.stringify")
external JSString jsonStringify(JSAny value);
//
@JS("esri.geometry.Point")
extension type JsPoint._(JSObject _) implements JSObject {
  external double get latitude;

  external double get longitude;

  external factory JsPoint(JSObject map);
}
//
@JS('require')
external JSFunction get require;

/// Configure AMD require settings
@JS('require.config')
external void requireConfig(JSObject config);

/// Check if window property exists and get its value
@JS('window._arcgisModulesReady')
external JSAny? get arcgisModulesReady;

/// Set property on JavaScript object
@JS('Object.defineProperty')
external void defineProperty(JSObject obj, JSString name, JSObject descriptor);

/// External function constructor for creating callback functions
@JS('Function')
external JSFunction createFunction(JSString code);

/// Helper extension for JSObject property access
extension JSObjectExtensions on JSObject {
  JSAny? operator [](String key) {
    return getProperty(this, key.toJS);
  }

  void operator []=(String key, JSAny? value) {
    setProperty(this, key.toJS, value);
  }
}

/// Helper functions for map operations to replace jsEval calls
@JS()
external JSFunction get createMapRemoveFunction;

@JS()
external JSFunction get createScreenshotFunction;

@JS()
external JSFunction get createNavigationFunction;

@JS()
external JSFunction get createAttributionFunction;

@JS()
external JSFunction get createGraphicRemoveFunction;

@JS()
external JSFunction get createBasemapFunction;
//
/// Global require function for AMD module loading
@JS('window')
external JSObject get window;
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-Layer.html
@JS("esri.layers.Layer")
extension type JsLayer._(JSObject _) implements JSObject {
  external String get id;

  external set id(String value);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-Layer.html#type
  /// Possible Values:
  /// "base-dynamic"|"base-elevation"|"base-tile"|"bing-maps"|"building-scene"|"csv"|"dimension"|"elevation"|"feature"|
  /// "geojson"|"geo-rss"|"graphics"|"group"|"imagery"|"imagery-tile"|"integrated-mesh"|"kml"|"line-of-sight"|"map-image"
  /// |"map-notes"|"media"|"ogc-feature"|"open-street-map"|"point-cloud"|"route"|"scene"|"georeferenced-image"|"stream"
  /// |"tile"|"unknown"|"unsupported"|"vector-tile"|"wcs"|"web-tile"|"wfs"|"wms"|"wmts"|"voxel"|"subtype-group"
  external String get type;

  external void destroy();

  external String get url;

  external set url(String value);
}
//
@JS("esri.layers.FeatureLayer")
extension type JsFeatureLayer._(JSObject _) implements JSObject {
  external factory JsFeatureLayer(JSObject properties);

  external JSPromise<JsFeatureSet> queryFeatures();

  external JSPromise<JsEditsResult> applyEdits(JSObject data);

  external String get id;
}
//
@JS("esri.layers.GraphicsLayer")
extension type JsGraphicsLayer._(JSObject _) implements JSObject {
  external factory JsGraphicsLayer(JSObject properties);

  external void add(JsGraphic graphic);

  external void addMany(JSObject graphics);

  external void remove(JsGraphic graphic);

  external void removeAll();

  external void destroy();

  external set elevationInfo(JSObject data);

  external JSObject get elevationInfo;

  external JSObject? get graphics;

  external String get id;
}
//
/// SceneLayer Options for CDN/AMD approach
extension type JsSceneLayerOptions._(JSObject _) implements JSObject {
  external factory JsSceneLayerOptions({String url, String id});
}
//
/// SceneLayer Constructor - available globally after ArcGIS CDN loads
@JS('window.SceneLayer')
external JSFunction? get sceneLayerConstructor;

/// External constructor function for SceneLayer
@JS('window.SceneLayer')
external JsSceneLayer createSceneLayer(JSObject options);

/// GraphicsLayer Constructor - available globally after ArcGIS CDN loads
@JS('window.GraphicsLayer')
external JSFunction? get graphicsLayerConstructor;

/// FeatureLayer Constructor - available globally after ArcGIS CDN loads
@JS('window.FeatureLayer')
external JSFunction? get featureLayerConstructor;
//
/// https://developers.arcgis.com/javascript/latest/sample-code/layers-scenelayer/
/// SceneLayer will be available after CDN loads
extension type JsSceneLayer._(JSObject _) implements JSObject {
  external set elevationInfo(JSObject data);

  external JSObject get elevationInfo;

  external String get id;
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html
@JS("esri.views.ui.DefaultUI")
extension type DefaultUI._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#components
  external JSArray<JSString> get components;

  external set components(JSArray<JSString> value);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#add
  external void add(JSObject widget, [JSString? position]);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#remove
  external void remove(JSObject widget);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Attribution.html
@JS("esri.widgets.Attribution")
extension type JsAttribution._(JSObject _) implements JSObject {
  external factory JsAttribution(JSObject properties);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Attribution.html#visible
  external bool get visible;

  external String get attributionText;
}
//
@JS("esri.Map")
extension type JsEsriMap._(JSObject _) implements JSObject {
  external factory JsEsriMap(JSObject properties);

  external void add(JSObject layer);

  external JSObject? findLayerById(JSString layerId);

  external JSObject? get layers;

  external JsBaseMap get basemap;

  external JsLayer reorder(JSObject layer, JSNumber index);

  external JSString? get ground;

  external set ground(JSString? value);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-VectorTileLayer.html
@JS("esri.layers.VectorTileLayer")
extension type JsVectorTileLayer._(JSObject _) implements JSObject {
  external factory JsVectorTileLayer(JSObject properties);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Basemap.html
@JS("esri.Basemap")
extension type JsBaseMap._(JSObject _) implements JSObject {
  external factory JsBaseMap(JSObject properties);

  external JSObject get referenceLayers;

  external bool get loaded;
}
//
@JS("esri.core.Collection")
extension type Collection<T extends JSAny?>._(JSObject _) implements JSObject {
  external JSNumber get length;

  external T? find(JSFunction callback);

  external Collection<T>? filter(JSFunction callback);

  external JSNumber findIndex(JSFunction callback);

  external void forEach(JSFunction callback);

  external void removeAt(JSNumber index);

  external void removeMany(Collection<T>? items);

  external void removeAll();

  external void add(T item, [JSNumber? index]);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html
@JS("esri.Graphic")
extension type JsGraphic._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#geometry
  external JsGeometry get geometry;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#attributes
  external JsAttributes get attributes;

  external set attributes(JsAttributes value);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Geometry.html
@JS("esri.geometry.Geometry")
extension type JsGeometry._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Geometry.html#extent
  external JsExtent? get extent;
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#attributes
@JS()
extension type JsAttributes._(JSObject _) implements JSObject {
  external String get id;
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html
@JS("esri.geometry.Extent")
extension type JsExtent._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html#contains
  external bool contains(JSObject geometry);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html#intersects
  external bool intersects(JSObject geometry);

  external JsPoint get center;

  external double get height;

  external double get width;

  external factory JsExtent(JSObject properties);

  external JsExtent expand(double ratio);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-View.html
@JS("esri.core.views.View")
extension type JsView._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-View.html#type
  external String get type;

  external double get zoom;

  external set padding(JSObject padding);

  external DefaultUI get ui;

  external JSObject get padding;

  external JsHandle on(JSArray<JSString> event, JSFunction callback);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-MapView.html#hitTest
  external JSPromise<JsHitTestResult> hitTest(JSObject event,
      [JSObject? options]);

  external JSPromise<JSObject?> goTo(JSObject target,
      [JSObject? targetOptions]);

  external Collection<JsGraphic> get graphics;

  external JSObject get center;

  external set popup(JSObject? popup);

  external JSObject? get popup;

  external JSObject get container;

  external set container(JSObject? value);

  external JsExtent? get extent;

  external JsEsriMap get map;
}
//
@JS("esri.views.MapView")
extension type JsMapView._(JSObject _) implements JsView {
  external factory JsMapView(JSObject properties);

  external double get zoom;

  external set padding(JSObject padding);

  external DefaultUI get ui;

  external JSObject get padding;

  external JsHandle on(JSArray<JSString> event, JSFunction callback);

  external JSPromise<JsHitTestResult> hitTest(JSObject event);

  external JSPromise<JSObject?> goTo(JSObject target,
      [JSObject? targetOptions]);

  external Collection<JsGraphic> get graphics;

  external String get id;

  external JSObject get components;

  external set components(JSObject components);

  external JSObject get center;

  external set popup(JSObject? popup);

  external JSObject? get popup;

  external JsViewpoint get viewpoint;

  external set viewpoint(JsViewpoint value);

  external JSObject get container;

  external set container(JSObject? value);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-SceneView.html
@JS("esri.views.SceneView")
extension type JsSceneView._(JSObject _) implements JsView {
  external factory JsSceneView(JSObject properties);

  external JSObject get padding;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-SceneView.html#viewingMode
  /// Possible Values:"global"|"local"
  external String get viewingMode;

  external set viewingMode(String value);

  external DefaultUI get ui;

  external set padding(JSObject padding);

  external JSPromise<JsHitTestResult> hitTest(JSObject event);

  external JSPromise<JSObject?> goTo(JSObject target,
      [JSObject? targetOptions]);

  external Collection<JsGraphic> get graphics;

  external String get id;

  external double get zoom;

  external set popup(JSObject? popup);

  external JSObject? get popup;

  external JsViewpoint get viewpoint;

  external set viewpoint(JsViewpoint value);

  external JsCamera get camera;

  external set camera(JsCamera value);

  external JSObject get container;

  external set container(JSObject? value);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Viewpoint.html
@JS("esri.Viewpoint")
extension type JsViewpoint._(JSObject _) implements JSObject {
  external factory JsViewpoint(JSObject properties);

  external JsCamera get camera;

  external set camera(JsCamera value);

  external double get rotation;

  external set rotation(double value);

  external double get scale;

  external set scale(double value);

  external JsGeometry get targetGeometry;

  external set targetGeometry(JsGeometry value);
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Camera.html
@JS("esri.Camera")
extension type JsCamera._(JSObject _) implements JSObject {
  external factory JsCamera(JSObject properties);

  external double get heading;

  external set heading(double value);

  external double get tilt;

  external set tilt(double value);

  external JsPoint get point;

  external set point(JsPoint value);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Accessor.html#WatchHandle
@JS()
extension type JsHandle._(JSObject _) implements JSObject {
  external void remove();
}
//
/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-MapView.html#HitTestResult
@JS()
extension type JsHitTestResult._(JSObject _) implements JSObject {
  external JSArray<HitTestResultItem>? get results;
}
//
@JS()
extension type HitTestResultItem._(JSObject _) implements JSObject {
  external JsGraphic? get graphic;

  external JsPoint get point;
}
//
///https://developers.arcgis.com/javascript/latest/api-reference/esri-rest-support-FeatureSet.html
@JS("esri.rest.support.FeatureSet")
extension type JsFeatureSet._(JSObject _) implements JSObject {
  external Collection<JsGraphic>? get features;
}
//
@JS("esri.layers.FeatureLayer")
extension type JsEditsResult._(JSObject _) implements JSObject {
  external JSObject get addFeatureResults;

  external JSObject get updateFeatureResults;

  external JSObject get deleteFeatureResults;
}

//
// Enhanced JS Interop for ArcGIS 4.33
//

/// Enhanced MapView with all 4.33 features
@JS("esri.views.MapView")
extension type JsMapViewEnhanced._(JSObject _) implements JsView {
  external factory JsMapViewEnhanced(JSObject properties);

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
  external DefaultUI get ui;

  external JSObject? get popup;

  external set popup(JSObject? value);

  // Navigation and viewpoint
  external JsViewpoint get viewpoint;

  external set viewpoint(JsViewpoint value);

  external JSPromise<JSObject?> goTo(JSObject target, [JSObject? options]);

  // Hit testing and events
  external JSPromise<JsHitTestResult> hitTest(JSObject event,
      [JSObject? options]);

  external JsHandle on(JSString event, JSFunction handler);

  // Export and screenshot
  external JSPromise<JSObject> takeScreenshot([JSObject? options]);

  // Navigation controls
  external JSObject get navigation;

  // Constraints
  external JSObject get constraints;

  external set constraints(JSObject value);
}

/// Enhanced SceneView with all 4.33 features
@JS("esri.views.SceneView")
extension type JsSceneViewEnhanced._(JSObject _) implements JsView {
  external factory JsSceneViewEnhanced(JSObject properties);

  // Core properties
  external JsEsriMap get map;

  external set map(JsEsriMap value);

  external JSObject? get container;

  external set container(JSObject? value);

  external JsExtent? get extent;

  external JsPoint get center;

  external double get zoom;

  external double get scale;

  external JSObject get padding;

  external set padding(JSObject value);

  // 3D specific
  external JsCamera get camera;

  external set camera(JsCamera value);

  external String get viewingMode;

  external set viewingMode(String value);

  // UI and interaction
  external DefaultUI get ui;

  external JSObject? get popup;

  external set popup(JSObject? value);

  // Navigation and viewpoint
  external JsViewpoint get viewpoint;

  external set viewpoint(JsViewpoint value);

  external JSPromise<JSObject?> goTo(JSObject target, [JSObject? options]);

  // Hit testing and events
  external JSPromise<JsHitTestResult> hitTest(JSObject event,
      [JSObject? options]);

  external JsHandle on(JSString event, JSFunction handler);

  // Export and screenshot
  external JSPromise<JSObject> takeScreenshot([JSObject? options]);

  // Navigation controls
  external JSObject get navigation;

  // Environment (lighting, atmosphere)
  external JSObject get environment;

  external set environment(JSObject value);
}

/// Enhanced Camera with complete 4.33 API
@JS("esri.Camera")
extension type JsCameraEnhanced._(JSObject _) implements JSObject {
  external factory JsCameraEnhanced(JSObject properties);

  external JsPoint get position;

  external set position(JsPoint value);

  external double get heading;

  external set heading(double value);

  external double get tilt;

  external set tilt(double value);

  external double get fov;

  external set fov(double value);

  external JsCameraEnhanced clone();
}

/// Enhanced Map with complete 4.33 API
@JS("esri.Map")
extension type JsMapEnhanced._(JSObject _) implements JSObject {
  external factory JsMapEnhanced(JSObject properties);

  external String get basemap;

  external set basemap(String value);

  external Collection<JsLayer> get layers;

  external Collection<JsLayer> get allLayers;

  external String get ground;

  external set ground(String value);

  // Layer management
  external void add(JsLayer layer, [int? index]);

  external void addMany(JSArray<JsLayer> layers, [int? index]);

  external JsLayer? remove(JsLayer layer);

  external JSArray<JsLayer> removeMany(JSArray<JsLayer> layers);

  external void removeAll();

  external JsLayer? findLayerById(JSString id);

  // Loading state
  external String get loadStatus;

  external JSPromise<JSObject> load();

  external JSPromise<JSObject> when([JSFunction? callback]);
}

/// Enhanced Graphics Layer with complete API
@JS("esri.layers.GraphicsLayer")
extension type JsGraphicsLayerEnhanced._(JSObject _) implements JSObject {
  external factory JsGraphicsLayerEnhanced(JSObject properties);

  external String get id;

  external set id(String value);

  external String get title;

  external set title(String value);

  external String get type;

  external bool get visible;

  external set visible(bool value);

  external double get opacity;

  external set opacity(double value);

  // Graphics management
  external Collection<JsGraphic> get graphics;

  external void add(JsGraphic graphic);

  external void addMany(JSArray<JsGraphic> graphics);

  external JsGraphic? remove(JsGraphic graphic);

  external JSArray<JsGraphic> removeMany(JSArray<JsGraphic> graphics);

  external void removeAll();

  // Elevation
  external JSObject? get elevationInfo;

  external set elevationInfo(JSObject? value);

  // Loading and lifecycle
  external String get loadStatus;

  external JSPromise<JSObject> load();

  external void destroy();
}

/// Enhanced Graphic with complete API
@JS("esri.Graphic")
extension type JsGraphicEnhanced._(JSObject _) implements JSObject {
  external factory JsGraphicEnhanced(JSObject properties);

  external JsGeometry? get geometry;

  external set geometry(JsGeometry? value);

  external JSObject? get attributes;

  external set attributes(JSObject? value);

  external JSObject? get symbol;

  external set symbol(JSObject? value);

  external JSObject? get popupTemplate;

  external set popupTemplate(JSObject? value);

  external JsGraphicEnhanced clone();

  external JSObject toJSON();
}

/// Enhanced FeatureLayer with complete API
@JS("esri.layers.FeatureLayer")
extension type JsFeatureLayerEnhanced._(JSObject _) implements JSObject {
  external factory JsFeatureLayerEnhanced(JSObject properties);

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
  external Collection<JsGraphic>? get source;

  external set source(Collection<JsGraphic>? value);

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

/// Enhanced SceneLayer with complete API
@JS("esri.layers.SceneLayer")
extension type JsSceneLayerEnhanced._(JSObject _) implements JSObject {
  external factory JsSceneLayerEnhanced(JSObject properties);

  external String get id;

  external set id(String value);

  external String get title;

  external set title(String value);

  external String get type;

  external String get url;

  external set url(String value);

  external bool get visible;

  external set visible(bool value);

  external double get opacity;

  external set opacity(double value);

  // 3D specific
  external JSObject? get elevationInfo;

  external set elevationInfo(JSObject? value);

  external JSObject? get popupTemplate;

  external set popupTemplate(JSObject? value);

  // Loading and lifecycle
  external String get loadStatus;

  external JSPromise<JSObject> load();

  external void destroy();
}

/// Navigation control for views
@JS()
extension type JsNavigation._(JSObject _) implements JSObject {
  external bool get enabled;

  external set enabled(bool value);

  external bool get mouseWheelZoomEnabled;

  external set mouseWheelZoomEnabled(bool value);

  external bool get browserTouchPanEnabled;

  external set browserTouchPanEnabled(bool value);
}

/// View constraints
@JS()
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

/// Environment settings for SceneView
@JS()
extension type JsEnvironment._(JSObject _) implements JSObject {
  external JSObject get lighting;

  external set lighting(JSObject value);

  external JSObject get atmosphere;

  external set atmosphere(JSObject value);

  external JSObject? get background;

  external set background(JSObject? value);
}

/// Basemap with enhanced API
@JS("esri.Basemap")
extension type JsBasemapEnhanced._(JSObject _) implements JSObject {
  external factory JsBasemapEnhanced(JSObject properties);

  external String get id;

  external String get title;

  external Collection<JsLayer> get baseLayers;

  external Collection<JsLayer> get referenceLayers;

  external String get portalItem;

  external bool get loaded;

  external JSPromise<JSObject> load();
}

/// Geometry utilities
@JS("esri.geometry.geometryEngine")
external JSObject get geometryEngine;

@JS("esri.geometry.Polygon")
extension type JsPolygon._(JSObject _) implements JsGeometry {
  external factory JsPolygon(JSObject properties);

  external JSArray<JSArray<JSArray<JSNumber>>> get rings;

  external set rings(JSArray<JSArray<JSArray<JSNumber>>> value);

  external bool contains(JsPoint point);
}

@JS("esri.geometry.Polyline")
extension type JsPolyline._(JSObject _) implements JsGeometry {
  external factory JsPolyline(JSObject properties);

  external JSArray<JSArray<JSArray<JSNumber>>> get paths;

  external set paths(JSArray<JSArray<JSArray<JSNumber>>> value);
}

/// Symbol types for graphics
@JS("esri.symbols.SimpleMarkerSymbol")
extension type JsSimpleMarkerSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleMarkerSymbol(JSObject properties);

  external String get type;

  external String get style;

  external set style(String value);

  external JSNumber get size;

  external set size(JSNumber value);

  external JSObject get color;

  external set color(JSObject value);
}

@JS("esri.symbols.SimpleLineSymbol")
extension type JsSimpleLineSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleLineSymbol(JSObject properties);

  external String get type;

  external String get style;

  external set style(String value);

  external JSNumber get width;

  external set width(JSNumber value);

  external JSObject get color;

  external set color(JSObject value);
}

@JS("esri.symbols.SimpleFillSymbol")
extension type JsSimpleFillSymbol._(JSObject _) implements JSObject {
  external factory JsSimpleFillSymbol(JSObject properties);

  external String get type;

  external String get style;

  external set style(String value);

  external JSObject get color;

  external set color(JSObject value);

  external JsSimpleLineSymbol? get outline;

  external set outline(JsSimpleLineSymbol? value);
}

// Helper functions for property access
@JS('Reflect.get')
external JSAny? getProperty(JSObject obj, JSString key);

@JS('Reflect.set')
external void setProperty(JSObject obj, JSString key, JSAny? value);
