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
  external JsExtent get extent;
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

  external JsExtent get extent;

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
