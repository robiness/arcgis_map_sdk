import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/layer_graphics.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
import 'package:arcgis_map_sdk_web/src/mouse_cursor_css.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

class WebLayerController {
  WebLayerController({required this.mapId});

  final int mapId;

  // Map instance not cached at this layer controller level

  // Layer tracking
  final Map<String, JSObject> _layers = {};

  /// The graphics of each graphics layer by layer id, found by graphic id.
  final Map<String, LayerGraphics> _layerGraphics = {};

  // SceneLayers deferred while in 2D mode (MapView can't handle them at all)
  final List<JsSceneLayer> _deferredSceneLayers = [];

  /// The load of each vector tile layer by id, completing whether or not the
  /// layer loads.
  final Map<String, Future<void>> _vectorTileLoads = {};

  Future<void> initialize() async {
    // Initialize the controller
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

    final jsProperties = layerProperties.jsify()! as JSObject;
    final featureLayer = JsFeatureLayer(jsProperties);

    // Add to map
    map.add(featureLayer);
    _layers[layerId] = featureLayer as JSObject;

    return FeatureLayer(
      id: layerId,
      url: url,
    );
  }

  /// Adds a graphics layer at [index] among the map's operational layers, on
  /// top when null.
  Future<GraphicsLayer> addGraphicsLayer({
    required String layerId,
    required GraphicsLayerOptions options,
    void Function(dynamic)? onPressed,
    int? index,
    required JSObject view,
  }) async {
    final map = (view as JsView).map;

    final layerProperties = <String, dynamic>{
      'id': layerId,
      'elevationInfo': {
        'mode': options.elevationMode.value,
      },
      'opacity': options.opacity,
      if (options.effect != null) 'effect': options.effect,
    }.jsify()! as JSObject;

    final graphicsLayer = JsGraphicsLayer(layerProperties);

    map.add(graphicsLayer, index);
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

  /// Adds a vector tile layer drawn from [style] at [index] among the map's
  /// operational layers, on top when null, and completes once it has loaded.
  ///
  /// The layer joins the map both views share, so it shows in 2D and 3D. A
  /// layer that fails to load stays in the map unless removed, so it is
  /// removed and destroyed here, and its id can be added again.
  Future<void> addVectorTileLayer({
    required String layerId,
    required Map<String, Object?> style,
    int? index,
    required JSObject view,
  }) async {
    final map = (view as JsView).map;
    if (_layerInMap(map, layerId) != null) {
      throw StateError('A layer with id $layerId is already in the map');
    }

    final layer =
        JsVectorTileLayer({'id': layerId, 'style': style}.jsify()! as JSObject);
    map.add(layer, index);
    _layers[layerId] = layer;

    // One future for the load and its cleanup, so whoever waits on the
    // layer's _vectorTileLoads entry finds a failed layer already gone.
    final loading = () async {
      try {
        await layer.load().toDart;
      } catch (e) {
        map.remove(layer);
        layer.destroy();
        // The id may already belong to a layer added after this one left
        // the map.
        if (identical(_layers[layerId], layer)) {
          _layers.remove(layerId);
          _vectorTileLoads.remove(layerId);
        }
        throw Exception(
            'Vector tile layer $layerId failed to load: ${_describeLoadError(e)}');
      }
    }();
    _vectorTileLoads[layerId] = loading.then((_) {}, onError: (Object _) {});
    await loading;
  }

  /// Replaces the whole style of the vector tile layer [layerId] with
  /// [style].
  ///
  /// A style set while the layer still loads waits for that load, which
  /// `loadStyle` would otherwise abort. A swap overtaken by a later one is
  /// rejected with an `AbortError` and completes here without error, as the
  /// later style is the one that shows.
  Future<void> setVectorTileStyle({
    required String layerId,
    required Map<String, Object?> style,
    required JSObject view,
  }) async {
    final map = (view as JsView).map;
    // Before the wait, so the style is the one given at this call, and one
    // that cannot be converted fails at once rather than as a failed load.
    final jsStyle = style.jsify()!;
    await _vectorTileLoads[layerId];

    final layer = _layerInMap(map, layerId);
    if (layer == null || layer.type != 'vector-tile') {
      throw Exception('Layer with id $layerId not found');
    }
    try {
      await (layer as JsVectorTileLayer).loadStyle(jsStyle).toDart;
    } catch (e) {
      if (_isAbortError(e)) return;
      throw Exception(
          'Vector tile layer $layerId failed to load its style: ${_describeLoadError(e)}');
    }
  }

  /// Shows or hides the layer [layerId] of the map, or a scene layer parked
  /// while the view is 2D. An unknown id changes nothing.
  void setLayerVisibility({
    required String layerId,
    required bool visible,
    required JSObject view,
  }) {
    final layer = _layerInMap((view as JsView).map, layerId) ??
        _deferredSceneLayers
            .where((sceneLayer) => sceneLayer.id == layerId)
            .firstOrNull;
    layer?.visible = visible;
  }

  /// The layer [layerId] of [map], or null. Not looked up in [_layers], as
  /// ArcgisMapWeb.destroyLayer removes layers from the map only.
  static JsLayer? _layerInMap(JsEsriMap map, String layerId) {
    return map.findLayerById(layerId) as JsLayer?;
  }

  /// `<name>: <message>` of the esri/core/Error ArcGIS rejects a load or a
  /// style with, anything else as it is. A rejection with a JS string, number
  /// or boolean reaches Dart as a Dart value, one with null or undefined as a
  /// [NullRejectionException].
  static String _describeLoadError(Object error) {
    if (error is NullRejectionException ||
        error is String ||
        error is num ||
        error is bool) {
      return '$error';
    }
    try {
      final arcgisError = error as JSObject;
      return '${arcgisError['name']}: ${arcgisError['message']}';
    } catch (_) {
      // Neither an object nor a primitive with a Dart counterpart, such as a
      // JS symbol.
      return '$error';
    }
  }

  /// Whether [error] is the esri/core/Error `loadStyle` rejects with once a
  /// later call has taken over.
  static bool _isAbortError(Object error) {
    try {
      return ((error as JSObject)['name'] as JSString?)?.toDart == 'AbortError';
    } catch (_) {
      return false;
    }
  }

  // Graphics Management

  Future<void> addGraphic({
    required String layerId,
    required Graphic graphic,
    required JSObject view,
  }) async {
    final layer = _layerToAddTo(view, layerId);
    final added = _toJsGraphic(graphic);
    if (layer.graphics case final graphics?) {
      _graphicsOf(layerId, graphics).add(added);
    } else {
      await _addFeatures(layer.features!, [added.graphic]);
    }
  }

  /// Adds [graphics] to the layer [layerId] in one call, in their order.
  Future<void> addGraphics({
    required String layerId,
    required Iterable<Graphic> graphics,
    required JSObject view,
  }) async {
    final layer = _layerToAddTo(view, layerId);
    final added = [for (final graphic in graphics) _toJsGraphic(graphic)];
    if (layer.graphics case final graphicsLayer?) {
      _graphicsOf(layerId, graphicsLayer).addMany(added);
    } else if (added.isNotEmpty) {
      await _addFeatures(layer.features!, [for (final a in added) a.graphic]);
    }
  }

  /// The graphics or feature layer [layerId] of the map, falling back to the
  /// cached reference.
  ({JsGraphicsLayer? graphics, JsFeatureLayer? features}) _layerToAddTo(
    JSObject view,
    String layerId,
  ) {
    final layer =
        (view as JsView).map.findLayerById(layerId) ?? _layers[layerId];
    if (layer == null) {
      throw Exception('Layer with id $layerId not found');
    }
    return switch ((layer as JsLayer).type) {
      'graphics' => (graphics: layer as JsGraphicsLayer, features: null),
      'feature' => (graphics: null, features: layer as JsFeatureLayer),
      _ => throw Exception(
          'Layer $layerId is neither a GraphicsLayer nor a FeatureLayer'),
    };
  }

  /// [graphic] as ArcGIS takes it, with the id from its attributes.
  static IdentifiedGraphic _toJsGraphic(Graphic graphic) {
    final json = graphic.toJson();
    final id = (json['attributes'] as Map?)?['id'];
    return (
      graphic: JsGraphic(json.jsify()! as JSObject),
      id: id is String ? id : null,
    );
  }

  static Future<void> _addFeatures(
    JsFeatureLayer layer,
    List<JsGraphic> features,
  ) async {
    await layer
        .applyEdits({'addFeatures': features}.jsify()! as JSObject)
        .toDart;
  }

  Future<void> removeGraphic({
    required String layerId,
    required String objectId,
    required JSObject view,
  }) async {
    _graphicsIn(view, layerId).remove(objectId);
  }

  /// Removes from the graphics layer [layerId] the graphics with
  /// [graphicIds] in one call. Ids the layer lacks are skipped.
  void removeGraphicsById({
    required String layerId,
    required Iterable<String> graphicIds,
    required JSObject view,
  }) {
    _graphicsIn(view, layerId).removeMany(graphicIds);
  }

  /// The graphics of the graphics layer [layerId] of the map.
  LayerGraphics _graphicsIn(JSObject view, String layerId) {
    final layer = (view as JsView).map.findLayerById(layerId);
    if (layer == null) {
      throw Exception('Layer with id $layerId not found');
    }
    final layerType = (layer as JsLayer).type;
    if (layerType != 'graphics') {
      throw Exception(
          'Layer $layerId is not a graphics layer (type: $layerType)');
    }
    return _graphicsOf(layerId, layer as JsGraphicsLayer);
  }

  /// Removes from the graphics layer [layerId], or from every graphics layer
  /// of the map where it is null, the graphics whose attributes hold
  /// [removeByAttributeValue] under [removeByAttributeKey], or all graphics
  /// with attributes where either is null. Graphics that hold one of
  /// [excludeAttributeValues] under [excludeAttributeKey] stay.
  void removeGraphics({
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
    required JSObject view,
  }) {
    final map = (view as JsView).map;
    final layers = layerId == null
        ? map.layers.toArray().toDart
        : [if (map.findLayerById(layerId) case final layer?) layer as JsLayer];
    final match = switch ((removeByAttributeKey, removeByAttributeValue)) {
      (final key?, final value?) => (key: key, value: value),
      _ => null,
    };
    final exclusion = switch ((excludeAttributeKey, excludeAttributeValues)) {
      (final key?, final values?) => (key: key, values: values.toSet()),
      _ => null,
    };

    bool removes(JSObject attributes) {
      if (match != null &&
          stringAttribute(attributes, match.key) != match.value) {
        return false;
      }
      return exclusion == null ||
          !exclusion.values
              .contains(stringAttribute(attributes, exclusion.key));
    }

    for (final layer in layers) {
      if (layer.type == 'graphics') {
        _graphicsOf(layer.id, layer as JsGraphicsLayer).removeWhere(removes);
      }
    }
  }

  /// The graphics of [layer], the layer [layerId], indexed anew where it has
  /// taken the id of another layer.
  LayerGraphics _graphicsOf(String layerId, JsGraphicsLayer layer) {
    final graphics = _layerGraphics[layerId];
    if (graphics != null && graphics.layer.strictEquals(layer).toDart) {
      return graphics;
    }
    return _layerGraphics[layerId] = LayerGraphics(layer);
  }

  // Camera and View Operations

  Future<void> moveCamera({
    required LatLng point,
    double? zoomLevel,
    double? scale,
    int? threeDHeading,
    int? threeDTilt,
    AnimationOptions? animationOptions,
    required JSObject view,
    required bool isSceneView,
  }) async {
    final target = <String, dynamic>{
      'center': [point.longitude, point.latitude],
      if (scale != null)
        'scale': scale
      else if (zoomLevel != null)
        'zoom': zoomLevel,
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

    final jsTarget = target.jsify()! as JSObject;

    final options = animationOptions != null
        ? animationOptions.toMap().jsify()! as JSObject
        : null;

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

    final target = extentData.jsify()! as JSObject;

    final options =
        padding != null ? {'padding': padding}.jsify()! as JSObject : null;

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

      final target = {'zoom': newZoom}.jsify()! as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify()! as JSObject
          : null;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e, stack) {
      developer.log('Error zooming in',
          name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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

      final target = {'zoom': newZoom}.jsify()! as JSObject;

      final options = animationOptions != null
          ? animationOptions.toMap().jsify()! as JSObject
          : null;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e, stack) {
      developer.log('Error zooming out',
          name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      return false;
    }
  }

  // Export and Screenshot

  Future<Uint8List> exportImage(JSObject view,
      {required bool isSceneView}) async {
    try {
      JSPromise<JSObject> screenshotPromise;

      if (isSceneView) {
        screenshotPromise = (view as JsSceneView).takeScreenshot();
      } else {
        screenshotPromise = (view as JsMapView).takeScreenshot();
      }

      final screenshotResult = await screenshotPromise.toDart;
      final dataUrl = screenshotResult['dataUrl']! as JSString;
      final base64Data = dataUrl.toDart.split(',')[1];

      return base64Decode(base64Data);
    } catch (e, stack) {
      developer.log('Error exporting image',
          name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      rethrow;
    }
  }

  // Utility Methods

  void setMouseCursor(SystemMouseCursor cursor) {
    final container =
        web.document.getElementById('map-$mapId') as web.HTMLElement?;
    if (container == null) return;

    container.style.cursor = cssCursorFor(cursor);
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
    _graphicsOf(layerId, layer).find(graphicId)?.symbol =
        symbol.toJson().jsify()! as JSObject;
  }

  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required List<Graphic> data,
    required JsView view,
  }) async {
    // Implementation would update the feature layer data
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
      _layerGraphics.remove(layerId);

      return true;
    } catch (e, stack) {
      developer.log('Error destroying layer',
          name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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
          final g = item! as JsGraphic;
          final attrs = g.attributes;
          final id = (attrs == null) ? null : (attrs['id'] as JSString?);
          if (id != null && id.toDart == polygonId) {
            // Extension-type casts on JS interop are runtime no-ops, so we
            // discriminate on geometry.type before downcasting to JsPolygon.
            final geometry = g.geometry;
            if (geometry == null || geometry.type != 'polygon') return;
            final polygon = geometry as JsPolygon;
            final pointProps = {
              'latitude': pointCoordinates.latitude,
              'longitude': pointCoordinates.longitude,
            }.jsify()! as JSObject;
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
      final layer = items[i]! as JSObject;
      final layerType = (layer['type'] as JSString?)?.toDart;
      if (layerType == 'scene') {
        detached.add(layer as JsSceneLayer);
      }
    }
    for (final sl in detached) {
      map.remove(sl);
      _deferredSceneLayers.add(sl);
    }
    if (detached.isNotEmpty) {}
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
    }.jsify()! as JSObject;

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
    _vectorTileLoads.clear();
    _layerGraphics.clear();
  }
}
