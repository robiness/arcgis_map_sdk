import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

export 'package:arcgis_map_sdk_web/src/arcgis_map_sdk_web.dart';

@JS("JSON.stringify")
external JSAny? jsonStringify(JSAny? value);

@JS("esri.geometry.Point")
extension type JsPoint._(JSObject _) implements JSObject {
  external double get latitude;

  external double get longitude;

  external JsPoint(JSAny? map);
}

@JS("loadFeatureLayer")
external JSAny? loadFeatureLayer();

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-Layer.html
@JS("esri.layers.Layer")
extension type JsLayer._(JSObject _) implements JSObject {
  external String id;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-Layer.html#type
  /// Possible Values:
  /// "base-dynamic"|"base-elevation"|"base-tile"|"bing-maps"|"building-scene"|"csv"|"dimension"|"elevation"|"feature"|
  /// "geojson"|"geo-rss"|"graphics"|"group"|"imagery"|"imagery-tile"|"integrated-mesh"|"kml"|"line-of-sight"|"map-image"
  /// |"map-notes"|"media"|"ogc-feature"|"open-street-map"|"point-cloud"|"route"|"scene"|"georeferenced-image"|"stream"
  /// |"tile"|"unknown"|"unsupported"|"vector-tile"|"wcs"|"web-tile"|"wfs"|"wms"|"wmts"|"voxel"|"subtype-group"
  external String get type;

  external void destroy();

  external String url;
}

@JS("FeatureLayer")
extension type JsFeatureLayer._(JSObject _) implements JSObject {
  external JsFeatureLayer(JSAny? map);

  external JSPromise<JsFeatureSet> queryFeatures();

  external JSPromise<JsEditsResult> applyEdits(JSAny? data);

  external String get id;
}

@JS("esri.layers.GraphicsLayer")
extension type JsGraphicsLayer._(JSObject _) implements JSObject {
  external JsGraphicsLayer(JSAny? map);

  external void add(JsGraphic graphic);

  external void addMany(Collection<JsGraphic> graphic);

  external void remove(JsGraphic graphic);

  external void removeAll();

  external void destroy();

  external set elevationInfo(JSAny? data);

  external JSAny? get elevationInfo;

  external Collection<JsGraphic>? get graphics;

  external String get id;
}

/// https://developers.arcgis.com/javascript/latest/sample-code/layers-scenelayer/
@JS("esri.layers.SceneLayer")
extension type JsSceneLayer._(JSObject _) implements JSObject {
  external JsSceneLayer(JSAny? map);

  external set elevationInfo(JSAny? data);

  external JSAny? get elevationInfo;

  external String get id;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html
@JS("esri.views.ui.DefaultUI")
extension type DefaultUI._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#components
  external JSArray<JSString> components;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#add
  external void add(JSAny? widget, JSString? optionName);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-ui-DefaultUI.html#remove
  external void remove(JSAny? widget);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Attribution.html
@JS("esri.widgets.Attribution")
extension type JsAttribution._(JSObject _) implements JSObject {
  external JsAttribution(JSAny? map);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Attribution.html#visible
  external bool get visible;

  external String get attributionText;
}

@JS("esri.Map")
extension type JsEsriMap._(JSObject _) implements JSObject {
  external JsEsriMap(JSAny? map);

  external void add(JSAny? layer);

  external JSAny? findLayerById(String layerId);

  external Collection<JsLayer>? get layers;

  external JsBaseMap get basemap;

  external JsLayer reorder(JSAny? layer, int index);

  external String? ground;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-VectorTileLayer.html
@JS("esri.layers.VectorTileLayer")
extension type JsVectorTileLayer._(JSObject _) implements JSObject {
  external JsVectorTileLayer(JSAny? map);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Basemap.html
@JS("esri.Basemap")
extension type JsBaseMap._(JSObject _) implements JSObject {
  external JsBaseMap(JSAny? basemap);

  external Collection referenceLayers;

  external bool get loaded;
}

@JS("esri.Collection")
extension type Collection<T extends JSAny?>._(JSObject _) implements JSObject {
  external int get length;

  external T? find(JSFunction callback);

  external Collection<T>? filter(JSFunction callback);

  external int findIndex(JSFunction callback);

  external void forEach(JSFunction collection);

  external void removeAt(int index);

  external void removeMany(Collection<T>? items);

  external void removeAll();

  external void add(JSAny? graphics, int? index);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html
@JS("esri.Graphic")
extension type JsGraphic._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#geometry
  external JsGeometry get geometry;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#attributes
  external JsAttributes attributes;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Geometry.html
@JS("esri.geometry.Geometry")
extension type JsGeometry._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Geometry.html#extent
  external JsExtent get extent;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Graphic.html#attributes
@JS()
extension type JsAttributes._(JSObject _) implements JSObject {
  external String get id;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html
@JS("esri.geometry.Extent")
extension type JsExtent._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html#contains
  external bool contains(JSAny? geometry);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-geometry-Extent.html#intersects
  external bool intersects(JSAny? geometry);

  external JsPoint get center;

  external double get height;

  external double get width;

  external JsExtent(JSAny? map);

  external JsExtent expand(double ratio);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-View.html
@JS("esri.views.View")
extension type JsView._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-View.html#type
  external String get type;

  external double get zoom;

  external set padding(JSAny? padding);

  external DefaultUI get ui;

  external JSAny? get padding;

  external JsHandle on(JSArray<JSString> event, JSFunction callback);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-MapView.html#hitTest
  external JSPromise<JsHitTestResult> hitTest(JSAny? event, JSAny? options);

  external JSPromise<JSAny?> goTo(JSAny? target, JSAny? targetOptions);

  external Collection<JsGraphic> get graphics;

  external JSAny? get center;

  external set popup(Popup? popup);

  external Popup? get popup;

  external JSAny? container;

  external JsExtent get extent;
}

@JS("esri.views.MapView")
extension type JsMapView._(JSObject _) implements JSObject {
  external JsMapView(JSAny? map);

  external double get zoom;

  external set padding(JSAny? padding);

  external DefaultUI get ui;

  external JSAny? get padding;

  external JsHandle on(JSArray<JSString> event, JSFunction callback);

  external JSPromise<JsHitTestResult> hitTest(JSAny? event);

  external JSPromise<JSAny?> goTo(JSAny? target, JSAny? targetOptions);

  external Collection<JsGraphic> get graphics;

  external String get id;

  external JSAny? get components;

  external set components(JSAny? components);

  external JSAny? get center;

  external set popup(Popup? popup);

  external Popup? get popup;

  external JsViewpoint viewpoint;

  external JSAny? container;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-SceneView.html
@JS("esri.views.SceneView")
extension type JsSceneView._(JSObject _) implements JSObject {
  external JsSceneView(JSAny? map);

  external JSAny? get padding;

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-SceneView.html#viewingMode
  /// Possible Values:"global"|"local"
  external String viewingMode;

  external DefaultUI get ui;

  external set padding(JSAny? padding);

  external JsHandle on(JSArray<JSString> event, JSFunction callback);

  external JSPromise<JsHitTestResult> hitTest(JSAny? event);

  external JSPromise<JSAny?> goTo(JSAny? target, JSAny? targetOptions);

  external Collection<JsGraphic> get graphics;

  external String get id;

  external double get zoom;

  external set popup(Popup? popup);

  external Popup? get popup;

  external JsViewpoint viewpoint;

  external JsCamera camera;

  external JSAny? container;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Viewpoint.html
@JS("esri.Viewpoint")
extension type JsViewpoint._(JSObject _) implements JSObject {
  external JsViewpoint(JSAny? map);

  external JsCamera camera;

  external double rotation;

  external double scale;

  external JsGeometry targetGeometry;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-Camera.html
@JS("esri.Camera")
extension type JsCamera._(JSObject _) implements JSObject {
  external JsCamera(JSAny? map);

  external double heading;

  external double tilt;

  external JsPoint point;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-BasemapToggle.html
@JS("esri.widgets.BasemapToggle")
extension type BasemapToggle._(JSObject _) implements JSObject {
  external BasemapToggle(JSAny? map);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-BasemapToggle.html#toggle
  external JSPromise<JSAny?> toggle();

  external JsBaseMap get activeBasemap;
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-ElevationProfile.html
@JS("esri.widgets.ElevationProfile")
extension type JsElevationProfile._(JSObject _) implements JSObject {
  external JsElevationProfile(JSAny? properties);

  external String get id;
}


/// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Accessor.html
@JS("esri.Accessor")
extension type Accessor._(JSObject _) implements JSObject {
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Accessor.html#get
  external JSAny? get(String path);

  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Accessor.html#set
  external JSAny? set(String path, JSAny? value);
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-Accessor.html#WatchHandle
@JS()
extension type WatchHandle._(JSObject _) implements JSObject {
  external void remove();
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-views-MapView.html#HitTestResult
@JS()
extension type JsHitTestResult._(JSObject _) implements JSObject {
  external JSArray<HitTestResultItem>? results;
}

@JS()
extension type HitTestResultItem._(JSObject _) implements JSObject {
  external JsGraphic? graphic;
  external JsPoint point;
}

///https://developers.arcgis.com/javascript/latest/api-reference/esri-rest-support-FeatureSet.html@JS()
@JS("esri.rest.support.FeatureSet")
extension type JsFeatureSet._(JSObject _) implements JSObject {
  external Collection<JsGraphic>? features;
}

@JS("esri.layers.FeatureLayer")
extension type JsEditsResult._(JSObject _) implements JSObject {
  external JSAny? addFeatureResults;
  external JSAny? updateFeatureResults;
  external JSAny? deleteFeatureResults;
}

@JS()
extension type JsHandle._(JSObject _) implements JSObject {
  external void remove();
}

///https://developers.arcgis.com/javascript/latest/api-reference/esri-widgets-Popup.html
@JS()
extension type Popup._(JSObject _) implements JSObject {}

extension WebGLRenderingContextExtension on WebGLRenderingContext {
  external WebglLoseContext? getCustomExtension(String something);
}

@JS()
@staticInterop
class WebglLoseContext {}

extension WebglLoseContextExtension on WebglLoseContext {
  external void loseContext();

  external void restoreContext();
}

/// https://developers.arcgis.com/javascript/latest/api-reference/esri-core-reactiveUtils.html#watch
@JS('esri.reactiveUtils.watch')
external WatchHandle watch(JSFunction getValue, JSFunction callback,
    JSAny? options);
