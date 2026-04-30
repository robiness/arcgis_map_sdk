import 'dart:async';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/web_layer_controller.dart';
import 'package:arcgis_map_sdk_web/src/web_stream_manager.dart';
import 'package:flutter/services.dart';

class ArcgisMapWebController {
  ArcgisMapWebController._({
    required this.mapId,
  })  : _layerController = WebLayerController(mapId: mapId),
        _streamManager = WebStreamManager(mapId: mapId);

  final int mapId;

  late final WebLayerController _layerController;
  late final WebStreamManager _streamManager;

  // View management
  JsMapView? mapView;
  JsSceneView? sceneView;
  bool _isSceneViewActive = false;
  JsView? get _activeView => _isSceneViewActive ? sceneView : mapView;

  static Future<ArcgisMapWebController> init(int id) async {
    final controller = ArcgisMapWebController._(mapId: id);
    await controller._initialize();
    return controller;
  }


  Future<void> _initialize() async {
    await _layerController.initialize();
    await _streamManager.initialize();
  }

  // Layer Management Methods - Mirror main controller
  Future<FeatureLayer> addFeatureLayer({
    required String layerId,
    required FeatureLayerOptions options,
    List<Graphic>? data,
    void Function(dynamic)? onPressed,
    String? url,
    void Function(double)? getZoom,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.addFeatureLayer(
      layerId: layerId,
      options: options,
      data: data,
      onPressed: onPressed,
      url: url,
      getZoom: getZoom,
      view: view,
    );
  }

  Future<GraphicsLayer> addGraphicsLayer({
    required String layerId,
    required GraphicsLayerOptions options,
    void Function(dynamic)? onPressed,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.addGraphicsLayer(
      layerId: layerId,
      options: options,
      onPressed: onPressed,
      view: view,
    );
  }

  Future<SceneLayer> addSceneLayer({
    required String layerId,
    required String url,
    required SceneLayerOptions options,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.addSceneLayer(
      layerId: layerId,
      url: url,
      options: options,
      view: view,
      isSceneViewActive: _isSceneViewActive,
    );
  }

  /// Exports an image of the currently visible map view
  Future<Uint8List> exportImage() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.exportImage(view, isSceneView: _isSceneViewActive);
  }

  // Stream Methods - Mirror main controller
  Stream<double> getZoom() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.getZoom(view);
  }

  Stream<LatLng> centerPosition() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.centerPosition(view);
  }

  Stream<BoundingBox> getBounds() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.getBounds(view);
  }

  Stream<String> attributionText() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.attributionText(view);
  }

  Stream<Attributes?> onClickListener() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.onClickListener(view);
  }

  Stream<List<String>> visibleGraphics() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _streamManager.visibleGraphics(view);
  }

  // Graphics Methods - Mirror main controller
  Future<void> addGraphic({required String layerId, required Graphic graphic}) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.addGraphic(
      layerId: layerId,
      graphic: graphic,
      view: view,
    );
  }

  Future<void> removeGraphic({
    required String layerId,
    required String objectId,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.removeGraphic(
      layerId: layerId,
      objectId: objectId,
      view: view,
    );
  }

  void removeGraphics({
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    _layerController.removeGraphics(
      layerId: layerId,
      removeByAttributeKey: removeByAttributeKey,
      removeByAttributeValue: removeByAttributeValue,
      excludeAttributeKey: excludeAttributeKey,
      excludeAttributeValues: excludeAttributeValues,
      view: view,
    );
  }

  // Camera Methods - Mirror main controller
  Future<void> moveCamera({
    required LatLng point,
    double? zoomLevel,
    int? threeDHeading,
    int? threeDTilt,
    AnimationOptions? animationOptions,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.moveCamera(
      point: point,
      zoomLevel: zoomLevel,
      threeDHeading: threeDHeading,
      threeDTilt: threeDTilt,
      animationOptions: animationOptions,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<void> moveCameraToPoints({
    required List<LatLng> points,
    double? padding,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.moveCameraToPoints(
      points: points,
      padding: padding,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<bool> zoomIn({
    required int lodFactor,
    AnimationOptions? animationOptions,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.zoomIn(
      lodFactor: lodFactor,
      animationOptions: animationOptions,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<bool> zoomOut({
    required int lodFactor,
    AnimationOptions? animationOptions,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.zoomOut(
      lodFactor: lodFactor,
      animationOptions: animationOptions,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  // Utility Methods - Mirror main controller
  void setMouseCursor(SystemMouseCursor cursor) {
    _layerController.setMouseCursor(cursor);
  }

  void updateGraphicSymbol({
    required String layerId,
    required String graphicId,
    required Symbol symbol,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    _layerController.updateGraphicSymbol(
      layerId: layerId,
      graphicId: graphicId,
      symbol: symbol,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required List<Graphic> data,
  }) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.updateFeatureLayer(
      featureLayerId: featureLayerId,
      data: data,
      view: view,
    );
  }

  bool destroyLayer({required String layerId}) {
    final view = _activeView;
    if (view == null) return false;

    return _layerController.destroyLayer(
      layerId: layerId,
      view: view,
    );
  }

  bool polygonContainsPoint({
    required String polygonId,
    required LatLng pointCoordinates,
  }) {
    final view = _activeView;
    if (view == null) return false;

    return _layerController.polygonContainsPoint(
      polygonId: polygonId,
      pointCoordinates: pointCoordinates,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<void> setRotation(double angleDegrees) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.setRotation(
      angleDegrees: angleDegrees,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  void switchMapStyle(MapStyle mapStyle) {
    final shouldUse3D = mapStyle == MapStyle.threeD;
    if (shouldUse3D != _isSceneViewActive) {
      _isSceneViewActive = shouldUse3D;
      _streamManager.switchView(_activeView!);
    }
  }

  void attachDeferredSceneLayers(JsEsriMap map) =>
      _layerController.attachDeferredSceneLayers(map);

  void detachSceneLayersFromMap(JsEsriMap map) =>
      _layerController.detachSceneLayersFromMap(map);

  void addViewPadding({required ViewPadding padding}) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    _layerController.addViewPadding(
      padding: padding,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<void> toggleBaseMap({required BaseMap baseMap}) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.toggleBaseMap(
      baseMap: baseMap,
      view: view,
    );
  }

  Future<void> setInteraction({required bool isEnabled}) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.setInteraction(
      isEnabled: isEnabled,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  Future<void> retryLoad() {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.retryLoad(view);
  }

  // Note: Status management removed for web implementation simplicity
  // Can be added later if needed

  List<Graphic> getGraphicsInView() {
    final view = _activeView;
    if (view == null) return [];

    return _layerController.getGraphicsInView(view);
  }

  Stream<bool> isGraphicHoveredStream() {
    final view = _activeView;
    if (view == null) return Stream.value(false);

    return _streamManager.isGraphicHoveredStream(view);
  }

  List<String> getVisibleGraphicIds() {
    final view = _activeView;
    if (view == null) return [];

    return _layerController.getVisibleGraphicIds(view);
  }

  Future<void> updateIsAttributionTextVisible(bool isAttributionTextVisible) {
    final view = _activeView;
    if (view == null) throw Exception('Map view not initialized');

    return _layerController.updateIsAttributionTextVisible(
      isAttributionTextVisible: isAttributionTextVisible,
      view: view,
      isSceneView: _isSceneViewActive,
    );
  }

  void dispose() {
    _layerController.dispose();
    _streamManager.dispose();
  }
}
