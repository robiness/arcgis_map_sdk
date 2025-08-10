import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

class WebLayerController {
  WebLayerController({required this.mapId});

  final int mapId;

  // Map instance for layer operations
  late final EsriMap _map;

  // Layer tracking
  final Map<String, JSObject> _layers = {};
  final List<Graphic> _graphicsInView = [];

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
    final map = (view as MapView).map;

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
    map.add(featureLayer as JSObject);
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
    final map = (view as MapView).map;

    final layerProperties = {
      'id': layerId,
    }.jsify() as JSObject;

    final graphicsLayer = JsGraphicsLayer(layerProperties);

    // Add to map
    map.add(graphicsLayer as JSObject);
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
  }) async {
    final map = (view as SceneView).map;

    final layerProperties = {
      'id': layerId,
      'url': url,
    }.jsify() as JSObject;

    final sceneLayer = JsSceneLayer(layerProperties);

    // Add to map
    map.add(sceneLayer as JSObject);
    _layers[layerId] = sceneLayer as JSObject;

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
    final map = (view as MapView).map;
    var layer = map.findLayerById(layerId.toJS);

    // If not found in current map, check if it's a FeatureLayer that needs to be treated as GraphicsLayer
    if (layer == null) {
      // Try to get from cached layers as fallback
      layer = _layers[layerId];
      print(
          'Layer $layerId not found in map, using cached reference: ${layer != null}');
    }

    if (layer == null) {
      // Debug: List all available layers
      print('Layer $layerId not found. Available layers:');
      final allLayers = map.layers;
      print('Total layers: ${allLayers.length}');
      throw Exception('Layer with id $layerId not found');
    }

    // Check layer type and handle accordingly
    final layerType = (layer as JSObject).type;

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
      // Handle GraphicsLayer - add directly
      graphicsLayer.add(jsGraphic);
    } else if (featureLayer != null) {
      // Handle FeatureLayer - use applyEdits
      final edits = {
        'addFeatures': [jsGraphic]
      }.jsify() as JSObject;

      await featureLayer.applyEdits(edits).toDart;
    } else {
      throw Exception(
          'Layer $layerId is neither a GraphicsLayer nor a FeatureLayer');
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
    final map = (view as MapView).map;
    final layer = map.findLayerById(layerId.toJS);

    if (layer == null) {
      throw Exception('Layer with id $layerId not found');
    }

    // Cast to graphics layer and check type
    final layerType = (layer as JSObject).type;
    if (layerType != 'graphics') {
      throw Exception(
          'Layer $layerId is not a graphics layer (type: $layerType)');
    }
    final graphicsLayer = layer as JsGraphicsLayer;

    // Find and remove the graphic with matching ID
    final graphics = graphicsLayer.graphics;
    final items = graphics.items as JSArray<JSObject>;

    for (final graphic in items.toDart) {
      final attributes = graphic['attributes'] as JSObject?;
      if (attributes != null && attributes['id'] == objectId.toJS) {
        graphicsLayer.remove(graphic);
        break;
      }
    }

    // Remove from tracking
    _graphicsInView.removeWhere((g) => g.attributes['id'] == objectId);
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
      final map = (view as MapView).map;
      final layer = map.findLayerById(layerId.toJS);

      if (layer != null) {
        // Cast to enhanced type for access to removeAll method
        if ((layer as JSObject).type == 'graphics') {
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
        // Cast to enhanced type for access to removeAll method
        if ((layer as JSObject).type == 'graphics') {
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

    final options = animationOptions != null
        ? animationOptions.toMap().jsify() as JSObject
        : null;

    if (isSceneView) {
      await (view as SceneView).goTo(jsTarget, options).toDart;
    } else {
      await (view as MapView).goTo(jsTarget, options).toDart;
    }
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

    final options =
        padding != null ? {'padding': padding}.jsify() as JSObject : null;

    if (isSceneView) {
      await (view as SceneView).goTo(target, options).toDart;
    } else {
      await (view as MapView).goTo(target, options).toDart;
    }
  }

  Future<bool> zoomIn({
    required int lodFactor,
    AnimationOptions? animationOptions,
    required JSObject view,
    required bool isSceneView,
  }) async {
    try {
      final currentZoom = (view as MapView).zoom;
      final newZoom = currentZoom + lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify() as JSObject
          : null;

      if (isSceneView) {
        await (view as SceneView).goTo(target, options).toDart;
      } else {
        await (view as MapView).goTo(target, options).toDart;
      }
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
      final currentZoom = (view as MapView).zoom;
      final newZoom = currentZoom - lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify() as JSObject
          : null;

      if (isSceneView) {
        await (view as SceneView).goTo(target, options).toDart;
      } else {
        await (view as MapView).goTo(target, options).toDart;
      }
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
        screenshotPromise = (view as SceneView).takeScreenshot();
      } else {
        screenshotPromise = (view as MapView).takeScreenshot();
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
    final container =
        web.document.getElementById('map-$mapId') as web.HTMLElement?;
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
    final map = isSceneView ? (view as SceneView).map : (view as MapView).map;

    for (final layer in _layers.values) {
      final jsLayer = layer as JSObject;
      if (jsLayer.type == 'graphics' && jsLayer.id == layerId) {
        final graphicsLayer = jsLayer as JsGraphicsLayer;
        final graphics = graphicsLayer.graphics;
        final items = graphics.items as JSArray<JSObject>;

        for (final graphic in items.toDart) {
          final attributes = graphic['attributes'] as JSObject?;
          if (attributes != null && attributes['id'] == graphicId.toJS) {
            final newSymbol = symbol.toJson().jsify() as JSObject;
            (graphic as JsGraphic).symbol = newSymbol;
            return;
          }
        }
      }
    }
  }

  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required List<Graphic> data,
    required JsView view,
  }) async {
    // Implementation would update the feature layer data
    print(
        'FeatureLayer update not fully implemented - use addGraphic/removeGraphic instead');
  }

  bool destroyLayer({
    required String layerId,
    required JSObject view,
  }) {
    try {
      // Get the layer from the map instead of cached reference
      final map = (view as MapView).map;
      final layer = map.findLayerById(layerId.toJS);
      if (layer == null) return false;

      // Remove from map
      map.remove(layer);

      // Destroy the layer
      (layer as JSObject).destroy();

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
    final map = isSceneView ? (view as SceneView).map : (view as MapView).map;

    for (final layer in _layers.values) {
      final jsLayer = layer as JSObject;
      if (jsLayer.type == 'graphics') {
        final graphicsLayer = jsLayer as JsGraphicsLayer;
        final graphics = graphicsLayer.graphics;
        final items = graphics.items as JSArray<JSObject>;

        for (final graphic in items.toDart) {
          final attributes = graphic['attributes'] as JSObject?;
          if (attributes != null && attributes['id'] == polygonId.toJS) {
            final polygon = graphic['geometry'] as Polygon;
            final point = Point(
              {
                'latitude': pointCoordinates.latitude,
                'longitude': pointCoordinates.longitude,
              }.jsify() as JSObject,
            );
            return polygon.contains(point);
          }
        }
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
      final sceneView = view as SceneView;
      final camera = sceneView.camera;
      camera.heading = angleDegrees;
      sceneView.camera = camera;
    } else {
      // For MapView, set viewpoint rotation
      final mapView = view as MapView;
      final viewpoint = mapView.viewpoint;
      viewpoint.rotation = angleDegrees;
      mapView.viewpoint = viewpoint;
    }
  }

  void switchView(JsView newView, bool isSceneView) {
    // Handle view switching - transfer layers, etc.
    print('View switched to ${isSceneView ? '3D' : '2D'}');
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
      (view as SceneView).padding = paddingObject;
    } else {
      (view as MapView).padding = paddingObject;
    }
  }

  Future<void> toggleBaseMap({
    required BaseMap baseMap,
    required JSObject view,
  }) async {
    final map = (view as MapView).map;
    map.basemap = baseMap.value;
  }

  Future<void> setInteraction({
    required bool isEnabled,
    required JSObject view,
    required bool isSceneView,
  }) async {
    if (isSceneView) {
      final navigation = (view as SceneView).navigation;
      navigation.enabled = isEnabled;
    } else {
      final navigation = (view as MapView).navigation;
      navigation.enabled = isEnabled;
    }
  }

  Future<void> retryLoad(JSObject view) async {
    // Refresh/reload the map and its layers
    final map = (view as MapView).map;

    // Reload all layers
    for (final layer in _layers.values) {
      final jsLayer = layer as JSObject;
      if (jsLayer.type == 'feature') {
        await (jsLayer as JsFeatureLayer).load().toDart;
      } else if (jsLayer.type == 'scene') {
        await (jsLayer as JsSceneLayer).load().toDart;
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
    return _graphicsInView
        .map((g) => g.attributes['id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> updateIsAttributionTextVisible({
    required bool isAttributionTextVisible,
    required JSObject view,
    required bool isSceneView,
  }) async {
    if (isSceneView) {
      final ui = (view as SceneView).ui;
      if (isAttributionTextVisible) {
        ui.add('attribution', 'bottom-right');
      } else {
        ui.remove('attribution');
      }
    } else {
      final ui = (view as MapView).ui;
      if (isAttributionTextVisible) {
        ui.add('attribution', 'bottom-right');
      } else {
        ui.remove('attribution');
      }
    }
  }

  void dispose() {
    _layers.clear();
    _graphicsInView.clear();
    print('WebLayerController disposed for mapId: $mapId');
  }
}
