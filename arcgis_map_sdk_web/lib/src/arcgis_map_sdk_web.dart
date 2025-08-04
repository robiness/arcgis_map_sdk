import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/src/arcgis_map_web_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart';

class ArcgisMapWeb extends ArcgisMapPlatform {
  static final _hasScriptLoaded = Completer();

  static void registerWith(Registrar registrar) {
    ArcgisMapPlatform.instance = ArcgisMapWeb();

    final link = HTMLLinkElement()
      ..type = "text/css"
      ..href =
          "assets/packages/arcgis_map_sdk_web/assets/css_overrides/override_outline.css"
      ..rel = "stylesheet";

    document.head!.append(link);

    // Check for ArcGIS API availability and complete the script loading
    _checkArcGISAvailability();
  }

  static void _checkArcGISAvailability() {
    print('🔍 [ArcGIS Web] Checking for ArcGIS API availability...');

    // Check if esri is already available
    if (globalContext.hasProperty('esri'.toJS).toDart) {
      print('✅ [ArcGIS Web] ArcGIS API already available!');
      if (!_hasScriptLoaded.isCompleted) {
        _hasScriptLoaded.complete();
        print('✅ [ArcGIS Web] Script loading Completer completed');
      }
      return;
    }

    print('⏳ [ArcGIS Web] ArcGIS API not yet available, polling...');

    // Poll for esri availability with timeout
    int attempts = 0;
    const maxAttempts = 300; // 30 seconds timeout
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      attempts++;

      if (globalContext.hasProperty('esri'.toJS).toDart) {
        print(
            '✅ [ArcGIS Web] ArcGIS API loaded after polling! (attempt $attempts)');
        timer.cancel();
        if (!_hasScriptLoaded.isCompleted) {
          _hasScriptLoaded.complete();
          print('✅ [ArcGIS Web] Script loading Completer completed');
        }
      } else if (attempts >= maxAttempts) {
        print(
            '❌ [ArcGIS Web] Timeout waiting for ArcGIS API after $attempts attempts');
        timer.cancel();
        if (!_hasScriptLoaded.isCompleted) {
          _hasScriptLoaded
              .completeError('ArcGIS API failed to load within 30 seconds');
        }
      } else if (attempts % 50 == 0) {
        print(
            '⏳ [ArcGIS Web] Still polling for ArcGIS API... (attempt $attempts/$maxAttempts)');
      }
    });
  }

  final Map<int, ArcgisMapWebController> _mapById = {};

  ArcgisMapWebController _map(int mapId) {
    final controller = _mapById[mapId];
    if (controller == null) {
      throw StateError('Maps cannot be retrieved before calling buildView!');
    }
    return controller;
  }

  @override
  Future<void> setMethodCallHandler({
    required int mapId,
    required Future<dynamic> Function(MethodCall) onCall,
  }) async {
    // No-Op
  }

  @override
  Future<void> moveCameraToPoints({
    required List<LatLng> points,
    required int mapId,
    double? padding,
  }) {
    return _map(mapId).moveCameraToPoints(points: points, padding: padding);
  }

  @override
  Future<void> init(int mapId) async {
    print('🚀 [ArcGIS Web] init() called for mapId: $mapId');
    print('⏳ [ArcGIS Web] Waiting for script loading...');
    await _hasScriptLoaded.future;
    print('✅ [ArcGIS Web] Script loaded, initializing map controller...');
    _map(mapId).init();
    print('✅ [ArcGIS Web] Map controller init() called');
  }

  @override
  Future<void> moveCamera({
    required LatLng point,
    required int mapId,
    double? zoomLevel,
    int? threeDHeading,
    int? threeDTilt,
    AnimationOptions? animationOptions,
  }) {
    return _map(mapId).moveCamera(
      point: point,
      zoomLevel: zoomLevel,
      threeDHeading: threeDHeading,
      threeDTilt: threeDTilt,
      animationOptions: animationOptions,
    );
  }

  @override
  Future<bool> zoomIn({
    required int lodFactor,
    required int mapId,
    AnimationOptions? animationOptions,
  }) {
    return _map(mapId)
        .zoomIn(lodFactor: lodFactor, animationOptions: animationOptions);
  }

  @override
  Future<bool> zoomOut({
    required int lodFactor,
    required int mapId,
    AnimationOptions? animationOptions,
  }) {
    return _map(mapId)
        .zoomOut(lodFactor: lodFactor, animationOptions: animationOptions);
  }

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) {
    return _map(mapId).addGraphic(layerId, graphic);
  }

  @override
  Future<void> removeGraphic(int mapId, String layerId, String objectId) {
    return _map(mapId).removeGraphic(layerId, objectId);
  }

  @override
  void removeGraphics({
    required int mapId,
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
  }) {
    _map(mapId).removeGraphics(
      layerId: layerId,
      removeByAttributeKey: removeByAttributeKey,
      removeByAttributeValue: removeByAttributeValue,
      excludeAttributeKey: excludeAttributeKey,
      excludeAttributeValues: excludeAttributeValues,
    );
  }

  @override
  void addViewPadding(int mapId, ViewPadding padding) {
    return _map(mapId).addViewPadding(padding: padding);
  }

  @override
  Future<void> toggleBaseMap(int mapId, BaseMap baseMap) {
    return _map(mapId).toggleBaseMap(baseMap: baseMap);
  }

  @override
  List<Graphic> getGraphicsInView(int mapId) => _map(mapId).graphicsInView;

  @override
  Stream<bool> isGraphicHoveredStream(int mapId) =>
      _map(mapId).isGraphicHoveredStream;

  @override
  Future<FeatureLayer> addFeatureLayer(
    FeatureLayerOptions options,
    List<Graphic>? data,
    void Function(dynamic)? onPressed,
    String? url,
    int mapId,
    void Function(double)? getZoom,
    String layerId,
  ) {
    return _map(mapId)
        .addFeatureLayer(options, data, onPressed, url, getZoom, layerId);
  }

  @override
  Future<GraphicsLayer> addGraphicsLayer(
    GraphicsLayerOptions options,
    int mapId,
    String layerId,
    void Function(dynamic)? onPressed,
  ) {
    return _map(mapId).addGraphicsLayer(
      options,
      layerId,
      onPressed,
    );
  }

  @override
  Future<SceneLayer> addSceneLayer({
    required SceneLayerOptions options,
    required String layerId,
    required String url,
    required int mapId,
  }) {
    return _map(mapId).addSceneLayer(
      options: options,
      layerId: layerId,
      url: url,
    );
  }

  @override
  void setMouseCursor(SystemMouseCursor cursor, int mapId) {
    _map(mapId).setMouseCursor(cursor);
  }

  @override
  void updateGraphicSymbol({
    required int mapId,
    required String layerId,
    required String graphicId,
    required Symbol symbol,
  }) {
    _map(mapId).updateGraphicSymbol(
      layerId: layerId,
      symbol: symbol,
      graphicId: graphicId,
    );
  }

  @override
  Stream<double> getZoom(int mapId) {
    return _map(mapId).getZoom();
  }

  @override
  void switchMapStyle(int mapId, MapStyle mapStyle) {
    _map(mapId).switchMapStyle(mapStyle);
  }

  @override
  Stream<LatLng> centerPosition(int mapId) {
    return _map(mapId).centerPosition();
  }

  @override
  Stream<BoundingBox> getBounds(int mapId) {
    return _map(mapId).getBounds();
  }

  @override
  Stream<List<String>> visibleGraphics(int mapId) {
    return _map(mapId).visibleGraphics();
  }

  @override
  List<String> getVisibleGraphicIds(int mapId) {
    return _map(mapId).getVisibleGraphicIds();
  }

  @override
  Stream<String> attributionText(int mapId) {
    return _map(mapId).attributionText();
  }

  @override
  Stream<Attributes?> onClickListener(int mapId) {
    return _map(mapId).onClickListener();
  }

  @override
  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required int mapId,
    required List<Graphic> data,
  }) async {
    await _map(mapId).updateFeatureLayer(
      featureLayerId: featureLayerId,
      data: data,
    );
  }

  @override
  bool destroyLayer({required int mapId, required String layerId}) {
    return _map(mapId).destroyLayer(layerId);
  }

  @override
  bool polygonContainsPoint({
    required String polygonId,
    required LatLng pointCoordinates,
    required int mapId,
  }) {
    return _map(mapId).polygonContainsPoint(polygonId, pointCoordinates);
  }

  @override
  void dispose({required int mapId}) {
    _map(mapId).dispose();
    _mapById.remove(mapId);
  }

  @override
  Widget buildView({
    required int creationId,
    required PlatformViewCreatedCallback onPlatformViewCreated,
    required ArcgisMapOptions mapOptions,
  }) {
    print('🏗️ [ArcGIS Web] buildView() called for mapId: $creationId');

    // Bail fast if we've already rendered this map ID...
    final widget = _mapById[creationId]?.widget;
    if (widget != null) {
      print('♻️ [ArcGIS Web] Returning existing widget for mapId: $creationId');
      return widget;
    }

    print('🎯 [ArcGIS Web] Creating new map controller for mapId: $creationId');
    final controller = StreamController<MapEvent>.broadcast();

    _hasScriptLoaded.future.then((_) {
      print(
          '⚙️ [ArcGIS Web] Configuring ArcGIS API settings for mapId: $creationId');

      /// Configure ArcGIS API to use CDN assets instead of local build
      /// Since we're using CDN, we don't need to set assetsPath
      // ignore: avoid_dynamic_calls
      final esri = globalContext.getProperty('esri'.toJS);
      final core = esri!.getProperty('config'.toJS);
      final config = core.getProperty('config'.toJS);
      // CDN automatically handles asset paths, so we don't set assetsPath
      print(
          '✅ [ArcGIS Web] ArcGIS API configuration completed for mapId: $creationId');
    });

    final mapController = ArcgisMapWebController(
      mapId: creationId,
      streamController: controller,
      mapOptions: mapOptions,
    );

    _mapById[creationId] = mapController;
    print('📦 [ArcGIS Web] Map controller stored for mapId: $creationId');

    onPlatformViewCreated.call(creationId);
    print(
        '📞 [ArcGIS Web] onPlatformViewCreated callback called for mapId: $creationId');

    final resultWidget = mapController.widget!;
    print(
        '🎨 [ArcGIS Web] Widget created and returning for mapId: $creationId');
    return resultWidget;
  }
}
