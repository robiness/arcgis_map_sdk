import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

class WebLayerController {
  WebLayerController({required this.mapId});

  final int mapId;

  // Map instance not cached at this layer controller level

  // Layer tracking
  final Map<String, JSObject> _layers = {};
  final List<Graphic> _graphicsInView = [];

  // SceneLayers deferred while in 2D mode (MapView can't handle them at all)
  final List<JsSceneLayer> _deferredSceneLayers = [];

  Future<void> initialize() async {
    // Initialize the controller
    print('WebLayerController initialized for mapId: $mapId');
  }

  // Layer Management Methods

  Future<FeatureLayer> addFeatureLayer({
    required String layerId,
    required FeatureLayerOptions options,
    List<Graphic>? data,
    void Function(dynamic)? onPressed,
    String? url,
    void Function(double)? getZoom,
    required JSObject view,
  }) async {
    final map = (view as JsView).map;

    // Create FeatureLayer properties
    final layerProperties = <String, dynamic>{
      'id': layerId,
      if (url != null) 'url': url,
    };

    // If no URL provided, create a local feature layer
    if (url == null) {
      final fields = [
        {'name': 'OBJECTID', 'alias': 'ObjectID', 'type': 'oid'},
        {'name': 'id', 'alias': 'ID', 'type': 'string'}
      ];

      layerProperties.addAll({
        'source': [], // Empty source for local features
        'fields': fields,
        'objectIdField': 'OBJECTID',
        'geometryType': 'point', // Default to point
      });
    }

    final jsProperties = layerProperties.jsify() as JSObject;
    final featureLayer = JsFeatureLayer(jsProperties);

    // Add to map
    map.add(featureLayer);
    _layers[layerId] = featureLayer as JSObject;

    return FeatureLayer(
      id: layerId,
      url: url,
    );
  }

  Future<GraphicsLayer> addGraphicsLayer({
    required String layerId,
    required GraphicsLayerOptions options,
    void Function(dynamic)? onPressed,
    required JSObject view,
  }) async {
    final map = (view as JsView).map;

    final layerProperties = <String, dynamic>{
      'id': layerId,
      'elevationInfo': {
        'mode': options.elevationMode.value,
      },
    }.jsify() as JSObject;

    final graphicsLayer = JsGraphicsLayer(layerProperties);

    // Add to map
    map.add(graphicsLayer);
    _layers[layerId] = graphicsLayer as JSObject;

    return GraphicsLayer(
      id: layerId,
    );
  }

  Future<SceneLayer> addSceneLayer({
    required String layerId,
    required String url,
    required SceneLayerOptions options,
    required JSObject view,
    required bool isSceneViewActive,
  }) async {
    // SceneLayer styling goes through `renderer`, not a direct `symbol`
    // property. Wrap the caller's symbol in a SimpleRenderer to apply it.
    final layerProperties = <String, dynamic>{
      'id': layerId,
      'url': url,
      'renderer': <String, dynamic>{
        'type': 'simple',
        'symbol': options.symbol.toJson(),
      },
    }.jsify()! as JSObject;

    final sceneLayer = JsSceneLayer(layerProperties);
    _layers[layerId] = sceneLayer as JSObject;

    if (isSceneViewActive) {
      // Add immediately — SceneView can render it
      final map = (view as JsView).map;
      map.add(sceneLayer);
    } else {
      // Defer — MapView can't handle SceneLayers at all (even invisible ones)
      _deferredSceneLayers.add(sceneLayer);
    }

    return SceneLayer(
      id: layerId,
    );
  }

  // Graphics Management

  Future<void> addGraphic({
    required String layerId,
    required Graphic graphic,
    required JSObject view,
  }) async {
    // Get the layer from the map
    final map = (view as JsView).map;
    JSObject? layer = map.findLayerById(layerId);

    // If not found in current map, check if it's a FeatureLayer that needs to be treated as GraphicsLayer
    if (layer == null) {
      // Try to get from cached layers as fallback
      layer = _layers[layerId];
      print('Layer $layerId not found in map, using cached reference: ${layer != null}');
    }

    if (layer == null) {
      // Debug: Layer not found in map
      print('Layer $layerId not found in map');
      throw Exception('Layer with id $layerId not found');
    }

    // Check layer type and handle accordingly
    final jsLayer = layer as JsLayer;
    final layerType = jsLayer.type;

    JsGraphicsLayer? graphicsLayer;
    JsFeatureLayer? featureLayer;

    if (layerType == 'graphics') {
      graphicsLayer = layer as JsGraphicsLayer;
    } else if (layerType == 'feature') {
      featureLayer = layer as JsFeatureLayer;
    }

    // Convert Dart graphic to JS graphic
    final graphicData = graphic.toJson().jsify() as JSObject;
    final jsGraphic = JsGraphic(graphicData);

    if (graphicsLayer != null) {
      // Handle GraphicsLayer - add directly (cast enhanced graphic to expected type)
      graphicsLayer.add((jsGraphic as JSObject) as JsGraphic);
    } else if (featureLayer != null) {
      // Handle FeatureLayer - use applyEdits
      final edits = {
        'addFeatures': [jsGraphic]
      }.jsify() as JSObject;

      await featureLayer.applyEdits(edits).toDart;
    } else {
      throw Exception('Layer $layerId is neither a GraphicsLayer nor a FeatureLayer');
    }

    // Track for visibility calculations
    _graphicsInView.add(graphic);
  }

  Future<void> removeGraphic({
    required String layerId,
    required String objectId,
    required JSObject view,
  }) async {
    // Get the layer from the map instead of cached reference
    final map = (view as JsView).map;
    final layer = map.findLayerById(layerId);

    if (layer == null) {
      throw Exception('Layer with id $layerId not found');
    }

    // Cast to layer and check type
    final jsLayer = layer as JsLayer;
    final layerType = jsLayer.type;
    if (layerType != 'graphics') {
      throw Exception('Layer $layerId is not a graphics layer (type: $layerType)');
    }
    final graphicsLayer = layer as JsGraphicsLayer;

    // Find and remove the graphic with matching ID
    final graphics = graphicsLayer.graphics;
    graphics.forEach((JSAny? item) {
      final g = item as JsGraphic;
      final attrs = g.attributes;
      final id = (attrs == null) ? null : (attrs['id'] as JSString?);
      if (id != null && id.toDart == objectId) {
        graphicsLayer.remove((g as JSObject) as JsGraphic);
      }
    }.toJS);

    // Remove from tracking
    _graphicsInView.removeWhere((g) => g.getAttributesId() == objectId);
  }

  void removeGraphics({
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
    required JSObject view,
  }) {
    if (layerId != null) {
      // Get the layer from the map instead of cached reference
      final map = (view as JsView).map;
      final layer = map.findLayerById(layerId);

      if (layer != null) {
        // Cast to layer type for access to properties
        final jsLayer = layer as JsLayer;
        if (jsLayer.type == 'graphics') {
          final graphicsLayer = layer as JsGraphicsLayer;
          // For simplicity, remove all graphics if no specific criteria
          if (removeByAttributeKey == null) {
            graphicsLayer.removeAll();
            _graphicsInView.clear();
          }
        }
        // Full implementation would filter by attributes
      }
    } else {
      // Remove from all graphics layers
      for (final layer in _layers.values) {
        final jsLayer = layer as JsLayer;
        if (jsLayer.type == 'graphics') {
          final graphicsLayer = layer as JsGraphicsLayer;
          graphicsLayer.removeAll();
        }
      }
      _graphicsInView.clear();
    }
  }

  // Camera and View Operations

  Future<void> moveCamera({
    required LatLng point,
    double? zoomLevel,
    int? threeDHeading,
    int? threeDTilt,
    AnimationOptions? animationOptions,
    required JSObject view,
    required bool isSceneView,
  }) async {
    final target = <String, dynamic>{
      'center': [point.longitude, point.latitude],
      if (zoomLevel != null) 'zoom': zoomLevel,
    };

    // For 3D views, set camera properties
    if (isSceneView && (threeDHeading != null || threeDTilt != null)) {
      target['camera'] = <String, dynamic>{
        'position': {
          'longitude': point.longitude,
          'latitude': point.latitude,
          'z': 10000, // Default altitude
        },
        if (threeDHeading != null) 'heading': threeDHeading,
        if (threeDTilt != null) 'tilt': threeDTilt,
      };
    }

    final jsTarget = target.jsify() as JSObject;

    final options = animationOptions != null ? animationOptions.toMap().jsify() as JSObject : null;

    await (view as JsView).goTo(jsTarget, options).toDart;
  }

  Future<void> moveCameraToPoints({
    required List<LatLng> points,
    double? padding,
    required JSObject view,
    required bool isSceneView,
  }) async {
    if (points.isEmpty) return;

    // Calculate bounds for the points
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Create extent object
    final extentData = {
      'xmin': minLng,
      'ymin': minLat,
      'xmax': maxLng,
      'ymax': maxLat,
      'spatialReference': {'wkid': 4326}
    };

    final target = extentData.jsify() as JSObject;

    final options = padding != null ? {'padding': padding}.jsify() as JSObject : null;

    await (view as JsView).goTo(target, options).toDart;
  }

  Future<bool> zoomIn({
    required int lodFactor,
    AnimationOptions? animationOptions,
    required JSObject view,
    required bool isSceneView,
  }) async {
    try {
      final currentZoom = (view as JsView).zoom;
      final newZoom = currentZoom + lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null ? animationOptions.toMap().jsify() as JSObject : null;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e) {
      print('Error zooming in: $e');
      return false;
    }
  }

  Future<bool> zoomOut({
    required int lodFactor,
    AnimationOptions? animationOptions,
    required JSObject view,
    required bool isSceneView,
  }) async {
    try {
      final currentZoom = (view as JsView).zoom;
      final newZoom = currentZoom - lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null ? animationOptions.toMap().jsify() as JSObject : null;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e) {
      print('Error zooming out: $e');
      return false;
    }
  }

  // Export and Screenshot

  Future<Uint8List> exportImage(JSObject view, {required bool isSceneView}) async {
    try {
      JSPromise<JSObject> screenshotPromise;

      if (isSceneView) {
        screenshotPromise = (view as JsSceneView).takeScreenshot();
      } else {
        screenshotPromise = (view as JsMapView).takeScreenshot();
      }

      final screenshotResult = await screenshotPromise.toDart;
      final dataUrl = screenshotResult['dataUrl'] as JSString;
      final base64Data = dataUrl.toDart.split(',')[1];

      return base64Decode(base64Data);
    } catch (e) {
      print('Error exporting image: $e');
      rethrow;
    }
  }

  // Utility Methods

  void setMouseCursor(SystemMouseCursor cursor) {
    final container = web.document.getElementById('map-$mapId') as web.HTMLElement?;
    if (container == null) return;

    String cssValue = 'default';
    if (cursor == SystemMouseCursors.click) {
      cssValue = 'pointer';
    } else if (cursor == SystemMouseCursors.grab) {
      cssValue = 'grab';
    } else if (cursor == SystemMouseCursors.grabbing) {
      cssValue = 'grabbing';
    }

    container.style.cursor = cssValue;
  }

  void updateGraphicSymbol({
    required String layerId,
    required String graphicId,
    required Symbol symbol,
    required JSObject view,
    required bool isSceneView,
  }) {
    final layer = _layers[layerId] as JsGraphicsLayer?;
    if (layer == null || layer.type != 'graphics') return;
    bool updated = false;
    layer.graphics.forEach((JSAny? item) {
      final g = item as JsGraphic;
      final attrs = g.attributes;
      final id = (attrs == null) ? null : (attrs['id'] as JSString?);
      if (!updated && id != null && id.toDart == graphicId) {
        g.symbol = symbol.toJson().jsify() as JSObject;
        updated = true;
      }
    }.toJS);
  }

  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required List<Graphic> data,
    required JsView view,
  }) async {
    // Implementation would update the feature layer data
    print('FeatureLayer update not fully implemented - use addGraphic/removeGraphic instead');
  }

  bool destroyLayer({
    required String layerId,
    required JSObject view,
  }) {
    try {
      // Get the layer from the map instead of cached reference
      final map = (view as JsView).map;
      final layer = map.findLayerById(layerId);
      if (layer == null) return false;

      // Cast to layer type for method access
      final jsLayer = layer as JsLayer;

      // Remove from map
      map.remove(jsLayer);

      // Destroy the layer
      jsLayer.destroy();

      // Remove from tracking
      _layers.remove(layerId);

      return true;
    } catch (e) {
      print('Error destroying layer: $e');
      return false;
    }
  }

  bool polygonContainsPoint({
    required String polygonId,
    required LatLng pointCoordinates,
    required JSObject view,
    required bool isSceneView,
  }) {
    for (final layer in _layers.values) {
      final jsLayer = layer as JsLayer;
      if (jsLayer.type == 'graphics') {
        final graphicsLayer = jsLayer as JsGraphicsLayer;
        final graphics = graphicsLayer.graphics;
        bool result = false;
        graphics.forEach((JSAny? item) {
          if (result) return;
          final g = item as JsGraphic;
          final attrs = g.attributes;
          final id = (attrs == null) ? null : (attrs['id'] as JSString?);
          if (id != null && id.toDart == polygonId) {
            final polygon = g.geometry as JsPolygon;
            final pointProps = {
              'latitude': pointCoordinates.latitude,
              'longitude': pointCoordinates.longitude,
            }.jsify() as JSObject;
            final point = JsPoint(pointProps);
            result = polygon.contains(point);
          }
        }.toJS);
        if (result) return true;
      }
    }

    return false;
  }

  Future<void> setRotation({
    required double angleDegrees,
    required JSObject view,
    required bool isSceneView,
  }) async {
    if (isSceneView) {
      // For SceneView, set camera heading
      final sceneView = view as JsSceneView;
      final camera = sceneView.camera;
      camera.heading = angleDegrees;
      sceneView.camera = camera;
    } else {
      // For MapView, set viewpoint rotation
      final mapView = view as JsMapView;
      final viewpoint = mapView.viewpoint;
      viewpoint.rotation = angleDegrees;
      mapView.viewpoint = viewpoint;
    }
  }

  /// Re-adds every parked SceneLayer to [map]. Pairs with
  /// [detachSceneLayersFromMap].
  void attachDeferredSceneLayers(JsEsriMap map) {
    if (_deferredSceneLayers.isEmpty) return;
    for (final sceneLayer in _deferredSceneLayers) {
      map.add(sceneLayer);
    }
    print('Attached ${_deferredSceneLayers.length} SceneLayer(s) for 3D view');
    _deferredSceneLayers.clear();
  }

  /// Removes every SceneLayer from [map] and parks them for later
  /// re-attach. MapView can't render SceneLayers and would log
  /// "Failed to create layerview" warnings if they remained attached.
  void detachSceneLayersFromMap(JsEsriMap map) {
    final layerItems = map.layers['items'] as JSArray?;
    if (layerItems == null) return;
    final items = layerItems.toDart;
    final detached = <JsSceneLayer>[];
    for (int i = 0; i < items.length; i++) {
      final layer = items[i] as JSObject;
      final layerType = (layer['type'] as JSString?)?.toDart;
      if (layerType == 'scene') {
        detached.add(layer as JsSceneLayer);
      }
    }
    for (final sl in detached) {
      map.remove(sl);
      _deferredSceneLayers.add(sl);
    }
    if (detached.isNotEmpty) {
      print('Detached ${detached.length} SceneLayer(s) for 2D view');
    }
  }

  void addViewPadding({
    required ViewPadding padding,
    required JSObject view,
    required bool isSceneView,
  }) {
    final paddingObject = {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    }.jsify() as JSObject;

    if (isSceneView) {
      (view as JsSceneView).padding = paddingObject;
    } else {
      (view as JsMapView).padding = paddingObject;
    }
  }

  Future<void> toggleBaseMap({
    required BaseMap baseMap,
    required JSObject view,
  }) async {
    // Not implemented yet with interop setter; handled at higher level
  }

  Future<void> setInteraction({
    required bool isEnabled,
    required JSObject view,
    required bool isSceneView,
  }) async {
    if (isSceneView) {
      final navigation = (view as JsSceneView).navigation;
      navigation['enabled'] = isEnabled.toJS;
    } else {
      final navigation = (view as JsMapView).navigation;
      navigation['enabled'] = isEnabled.toJS;
    }
  }

  Future<void> retryLoad(JSObject view) async {
    // Refresh/reload the map and its layers

    // Reload all layers
    for (final layer in _layers.values) {
      final jsLayer = layer as JsLayer;
      final layerType = jsLayer.type;
      if (layerType == 'scene') {
        await (layer as JsSceneLayer).load().toDart;
      }
    }

    print('Retry load completed for mapId: $mapId');
  }

  List<Graphic> getGraphicsInView(JSObject view) {
    // Return cached graphics for performance
    return _graphicsInView;
  }

  List<String> getVisibleGraphicIds(JSObject view) {
    // Extract IDs from visible graphics
    return _graphicsInView.map((g) => g.getAttributesId()).where((id) => id.isNotEmpty).toList();
  }

  Future<void> updateIsAttributionTextVisible({
    required bool isAttributionTextVisible,
    required JSObject view,
    required bool isSceneView,
  }) async {
    // Not implemented: UI widget manipulation via interop
  }

  void dispose() {
    _layers.clear();
    _graphicsInView.clear();
    print('WebLayerController disposed for mapId: $mapId');
  }
}
