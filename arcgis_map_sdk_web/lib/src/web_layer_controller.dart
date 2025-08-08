import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/arcgis_map_web_js.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

class WebLayerController {
  WebLayerController({required this.mapId});

  final int mapId;

  // Map instance for layer operations
  late final JsMapEnhanced _map;

  // Layer tracking
  final Map<String, JsLayer> _layers = {};
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
    required JsView view,
  }) async {
    final map = view.map as JsMapEnhanced;

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
    final featureLayer = JsFeatureLayerEnhanced(jsProperties);

    // Add to map
    map.add(featureLayer as JsLayer);
    _layers[layerId] = featureLayer as JsLayer;

    return FeatureLayer(
      id: layerId,
      url: url,
    );
  }

  Future<GraphicsLayer> addGraphicsLayer({
    required String layerId,
    required GraphicsLayerOptions options,
    void Function(dynamic)? onPressed,
    required JsView view,
  }) async {
    final map = view.map as JsMapEnhanced;

    final layerProperties = {
      'id': layerId,
    }.jsify() as JSObject;

    final graphicsLayer = JsGraphicsLayerEnhanced(layerProperties);

    // Add to map
    map.add(graphicsLayer as JsLayer);
    _layers[layerId] = graphicsLayer as JsLayer;

    return GraphicsLayer(
      id: layerId,
    );
  }

  Future<SceneLayer> addSceneLayer({
    required String layerId,
    required String url,
    required SceneLayerOptions options,
    required JsView view,
  }) async {
    final map = view.map as JsMapEnhanced;

    final layerProperties = {
      'id': layerId,
      'url': url,
    }.jsify() as JSObject;

    final sceneLayer = JsSceneLayerEnhanced(layerProperties);

    // Add to map
    map.add(sceneLayer as JsLayer);
    _layers[layerId] = sceneLayer as JsLayer;

    return SceneLayer(
      id: layerId,
    );
  }

  // Graphics Management

  Future<void> addGraphic({
    required String layerId,
    required Graphic graphic,
    required JsView view,
  }) async {
    // Get the layer from the map
    final map = view.map as JsMapEnhanced;
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
    final layerType = layer.type;

    JsGraphicsLayerEnhanced? graphicsLayer;
    JsFeatureLayerEnhanced? featureLayer;

    if (layerType == 'graphics') {
      graphicsLayer = JsGraphicsLayerEnhanced(layer as JSObject);
    } else if (layerType == 'feature') {
      featureLayer = JsFeatureLayerEnhanced(layer as JSObject);
    }

    // Convert Dart graphic to JS graphic
    final graphicData = graphic.toJson().jsify() as JSObject;
    final jsGraphic = JsGraphicEnhanced(graphicData);

    if (graphicsLayer != null) {
      // Handle GraphicsLayer - add directly
      graphicsLayer.add(jsGraphic as JsGraphic);
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
    required JsView view,
  }) async {
    // Get the layer from the map instead of cached reference
    final map = view.map as JsMapEnhanced;
    final layer = map.findLayerById(layerId.toJS);

    if (layer == null) {
      throw Exception('Layer with id $layerId not found');
    }

    // Cast to graphics layer and check type
    final layerType = layer.type;
    if (layerType != 'graphics') {
      throw Exception(
          'Layer $layerId is not a graphics layer (type: $layerType)');
    }
    final graphicsLayer = JsGraphicsLayerEnhanced(layer as JSObject);

    // Find and remove the graphic with matching ID
    final graphics = graphicsLayer.graphics;
    // Note: This is a simplified implementation
    // In a full implementation, you'd iterate through graphics.items
    // and find the one with matching objectId, then call remove()

    // Remove from tracking
    _graphicsInView.removeWhere((g) => g.getAttributesId() == objectId);
  }

  void removeGraphics({
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
    required JsView view,
  }) {
    if (layerId != null) {
      // Get the layer from the map instead of cached reference
      final map = view.map as JsMapEnhanced;
      final layer = map.findLayerById(layerId.toJS);

      if (layer != null) {
        // Cast to enhanced type for access to removeAll method
        if (layer.type == 'graphics') {
          final graphicsLayer = JsGraphicsLayerEnhanced(layer as JSObject);
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
        if (layer.type == 'graphics') {
          final graphicsLayer = JsGraphicsLayerEnhanced(layer as JSObject);
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
    required JsView view,
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

    // Use enhanced view types for better functionality
    final mapView = view as JsMapViewEnhanced?;
    final sceneView = view as JsSceneViewEnhanced?;

    if (mapView != null) {
      await mapView.goTo(jsTarget, options).toDart;
    } else if (sceneView != null) {
      await sceneView.goTo(jsTarget, options).toDart;
    } else {
      // Fallback to generic view
      await (view as JsView).goTo(jsTarget, options).toDart;
    }
  }

  Future<void> moveCameraToPoints({
    required List<LatLng> points,
    double? padding,
    required JsView view,
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

    // Use enhanced view types for better functionality
    final mapView = view as JsMapViewEnhanced?;
    final sceneView = view as JsSceneViewEnhanced?;

    if (mapView != null) {
      await mapView.goTo(target, options).toDart;
    } else if (sceneView != null) {
      await sceneView.goTo(target, options).toDart;
    } else {
      // Fallback to generic view
      await (view as JsView).goTo(target, options).toDart;
    }
  }

  Future<bool> zoomIn({
    required int lodFactor,
    AnimationOptions? animationOptions,
    required JsView view,
  }) async {
    try {
      final currentZoom = view.zoom;
      final newZoom = currentZoom + lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify() as JSObject
          : null;

      // Use enhanced view types for better functionality
      final mapView = view as JsMapViewEnhanced?;
      final sceneView = view as JsSceneViewEnhanced?;

      if (mapView != null) {
        await mapView.goTo(target, options).toDart;
      } else if (sceneView != null) {
        await sceneView.goTo(target, options).toDart;
      } else {
        // Fallback to generic view
        await (view as JsView).goTo(target, options).toDart;
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
    required JsView view,
  }) async {
    try {
      final currentZoom = view.zoom;
      final newZoom = currentZoom - lodFactor;

      final target = {'zoom': newZoom}.jsify() as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify() as JSObject
          : null;

      // Use enhanced view types for better functionality
      final mapView = view as JsMapViewEnhanced?;
      final sceneView = view as JsSceneViewEnhanced?;

      if (mapView != null) {
        await mapView.goTo(target, options).toDart;
      } else if (sceneView != null) {
        await sceneView.goTo(target, options).toDart;
      } else {
        // Fallback to generic view
        await (view as JsView).goTo(target, options).toDart;
      }
      return true;
    } catch (e) {
      print('Error zooming out: $e');
      return false;
    }
  }

  // Export and Screenshot

  Future<Uint8List> exportImage(JsView view) async {
    try {
      // Use enhanced view types for screenshot functionality
      final mapView = view as JsMapViewEnhanced?;
      final sceneView = view as JsSceneViewEnhanced?;

      JSPromise<JSObject> screenshotPromise;

      if (mapView != null) {
        screenshotPromise = mapView.takeScreenshot();
      } else if (sceneView != null) {
        screenshotPromise = sceneView.takeScreenshot();
      } else {
        throw Exception('View type does not support screenshot functionality');
      }

      final screenshotResult = await screenshotPromise.toDart;

      // For now, return empty data as this requires complex JS interop
      // to extract the actual image data from the screenshot result
      // In a full implementation, you would access screenshotResult.dataUrl
      // and convert the base64 data to Uint8List
      print('Screenshot taken successfully (placeholder implementation)');
      return Uint8List(0);
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
    required JsView view,
  }) {
    // Implementation would find the graphic and update its symbol
    print(
        'updateGraphicSymbol not fully implemented - use removeGraphic/addGraphic instead');
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
    required JsView view,
  }) {
    try {
      // Get the layer from the map instead of cached reference
      final map = view.map as JsMapEnhanced;
      final layer = map.findLayerById(layerId.toJS);
      if (layer == null) return false;

      // Remove from map
      map.remove(layer);

      // Destroy the layer
      if (layer is JsGraphicsLayerEnhanced) {
        layer.destroy();
      } else if (layer is JsFeatureLayerEnhanced) {
        layer.destroy();
      } else if (layer is JsSceneLayerEnhanced) {
        layer.destroy();
      }

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
    required JsView view,
  }) {
    // This would require complex geometry operations with ArcGIS JS API
    // For now, return false as placeholder
    print(
        'polygonContainsPoint not fully implemented - requires geometry analysis');
    return false;
  }

  Future<void> setRotation({
    required double angleDegrees,
    required JsView view,
    required bool isSceneView,
  }) async {
    // Cast to enhanced types for access to specific properties
    final sceneView = view as JsSceneViewEnhanced?;
    final mapView = view as JsMapViewEnhanced?;

    if (isSceneView && sceneView != null) {
      // For SceneView, set camera heading
      final camera = sceneView.camera as JsCameraEnhanced;
      final newCamera = JsCameraEnhanced({
        'position': camera.position,
        'heading': angleDegrees,
        'tilt': camera.tilt,
      }.jsify() as JSObject);
      sceneView.camera = newCamera as JsCamera;
    } else if (mapView != null) {
      // For MapView, set viewpoint rotation
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
    required JsView view,
  }) {
    final paddingObject = {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    }.jsify() as JSObject;

    if (view is JsMapViewEnhanced) {
      view.padding = paddingObject;
    } else if (view is JsSceneViewEnhanced) {
      view.padding = paddingObject;
    }
  }

  Future<void> toggleBaseMap({
    required BaseMap baseMap,
    required JsView view,
  }) async {
    final map = view.map as JsMapEnhanced;
    map.basemap = baseMap.value;
  }

  Future<void> setInteraction({
    required bool isEnabled,
    required JsView view,
  }) async {
    final mapView = view as JsMapViewEnhanced?;
    final sceneView = view as JsSceneViewEnhanced?;

    if (mapView != null) {
      final navigation = mapView.navigation as JsNavigation;
      navigation.enabled = isEnabled;
    } else if (sceneView != null) {
      final navigation = sceneView.navigation as JsNavigation;
      navigation.enabled = isEnabled;
    }
  }

  Future<void> retryLoad(JsView view) async {
    // Refresh/reload the map and its layers
    final map = view.map as JsMapEnhanced;

    // Reload all layers
    for (final layer in _layers.values) {
      final featureLayer = layer as JsFeatureLayerEnhanced?;
      final sceneLayer = layer as JsSceneLayerEnhanced?;

      if (featureLayer != null) {
        await featureLayer.load().toDart;
      } else if (sceneLayer != null) {
        await sceneLayer.load().toDart;
      }
    }

    print('Retry load completed for mapId: $mapId');
  }

  List<Graphic> getGraphicsInView(JsView view) {
    // Return cached graphics for performance
    return _graphicsInView;
  }

  List<String> getVisibleGraphicIds(JsView view) {
    // Extract IDs from visible graphics
    return _graphicsInView
        .map((g) => g.getAttributesId() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> updateIsAttributionTextVisible({
    required bool isAttributionTextVisible,
    required JsView view,
  }) async {
    final mapView = view as JsMapViewEnhanced?;
    final sceneView = view as JsSceneViewEnhanced?;

    if (mapView != null) {
      final ui = mapView.ui;
      if (isAttributionTextVisible) {
        // Add attribution if not present
        // This would need proper UI widget management
      } else {
        // Remove attribution
        // This would need proper UI widget management
      }
    } else if (sceneView != null) {
      final ui = sceneView.ui;
      if (isAttributionTextVisible) {
        // Add attribution if not present
      } else {
        // Remove attribution
      }
    }
  }

  void dispose() {
    _layers.clear();
    _graphicsInView.clear();
    print('WebLayerController disposed for mapId: $mapId');
  }
}
