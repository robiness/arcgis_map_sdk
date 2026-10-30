import 'package:arcgis_map_sdk/src/arcgis_location_display.dart';
import 'package:arcgis_map_sdk/src/model/map_status.dart';
import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:flutter/services.dart';

typedef MapStatusListener = void Function(MapStatus status);

class ArcgisMapController {
  ArcgisMapController._({
    required this.mapId,
  }) : _locationDisplay = ArcgisLocationDisplay(mapId: mapId) {
    ArcgisMapPlatform.instance.setMethodCallHandler(
      mapId: mapId,
      onCall: _onCall,
    );
  }

  final int mapId;

  late ArcgisLocationDisplay _locationDisplay;

  ArcgisLocationDisplay get locationDisplay => _locationDisplay;

  final _listeners = <MapStatusListener>[];
  MapStatus _mapStatus = MapStatus.unknown;

  MapStatus get mapStatus => _mapStatus;

  static Future<ArcgisMapController> init(
    int id,
  ) async {
    await ArcgisMapPlatform.instance.init(id);
    return ArcgisMapController._(mapId: id);
  }

  Future<FeatureLayer> addFeatureLayer({
    required String layerId,
    required FeatureLayerOptions options,
    List<Graphic>? data,
    void Function(dynamic)? onPressed,
    String? url,
    void Function(double)? getZoom,
  }) {
    return ArcgisMapPlatform.instance.addFeatureLayer(
      options,
      data,
      onPressed,
      url,
      mapId,
      getZoom,
      layerId,
    );
  }

  /// Exports an image of the currently visible map view containing all
  /// layers of that view.
  Future<Uint8List> exportImage() {
    return ArcgisMapPlatform.instance.exportImage(mapId);
  }

  Future<GraphicsLayer> addGraphicsLayer({
    required String layerId,
    required GraphicsLayerOptions options,
    void Function(dynamic)? onPressed,
  }) {
    return ArcgisMapPlatform.instance.addGraphicsLayer(
      options,
      mapId,
      layerId,
      onPressed,
    );
  }

  Future<SceneLayer> addSceneLayer({
    required String layerId,
    required String url,
    required SceneLayerOptions options,
  }) {
    return ArcgisMapPlatform.instance.addSceneLayer(
      options: options,
      layerId: layerId,
      url: url,
      mapId: mapId,
    );
  }

  /// Adds a VectorTileLayer built from [style], a Mapbox GL style object.
  /// [index] is the position in the map's operational layers (0 = bottom).
  /// Completes once the layer has loaded (its service description and style
  /// resolved); throws when it cannot load, and then leaves no layer behind.
  /// Register headers for the service with [setRequestHeaders] first; the
  /// load already requests its description. The error of a failed load names
  /// the layer. An id already in the map throws a StateError. Web only for
  /// now.
  Future<void> addVectorTileLayer({
    required String layerId,
    required Map<String, Object?> style,
    int? index,
  }) {
    return ArcgisMapPlatform.instance.addVectorTileLayer(
      mapId: mapId,
      layerId: layerId,
      style: style,
      index: index,
    );
  }

  /// Replaces the whole style of a layer added by [addVectorTileLayer].
  /// A style set while the layer still loads waits for that load. A swap
  /// overtaken by a later one completes without error. The layer's
  /// visibility stays as it is. Throws when the style cannot load, with an
  /// error that names the layer, and when [layerId] names no vector tile
  /// layer of the map. Web only for now.
  Future<void> setVectorTileStyle({
    required String layerId,
    required Map<String, Object?> style,
  }) {
    return ArcgisMapPlatform.instance.setVectorTileStyle(
      mapId: mapId,
      layerId: layerId,
      style: style,
    );
  }

  /// Shows or hides any operational layer. An id the map does not know
  /// changes nothing. Web only for now.
  void setLayerVisibility({required String layerId, required bool visible}) {
    ArcgisMapPlatform.instance.setLayerVisibility(
      mapId: mapId,
      layerId: layerId,
      visible: visible,
    );
  }

  Future<void> _onCall(MethodCall call) async {
    final method = call.method;
    switch (method) {
      case "onStatusChanged":
        return _notifyStatusChanged(call);
      default:
        throw UnimplementedError('Method "$method" not implemented');
    }
  }

  Stream<double> getZoom() {
    return ArcgisMapPlatform.instance.getZoom(mapId);
  }

  /// The map scale at the view's centre, the denominator of 1:scale, on every
  /// change.
  ///
  /// Unlike [getZoom], whose levels follow the tiling scheme of the basemap
  /// (a vector basemap counts one level lower than a raster one at the same
  /// scale), the scale means the same on every basemap. Web only for now.
  Stream<double> getScale() {
    return ArcgisMapPlatform.instance.getScale(mapId);
  }

  void switchMapStyle(MapStyle mapStyle) {
    ArcgisMapPlatform.instance.switchMapStyle(mapId, mapStyle);
  }

  Stream<LatLng> centerPosition() {
    return ArcgisMapPlatform.instance.centerPosition(mapId);
  }

  Stream<List<String>> visibleGraphics() {
    return ArcgisMapPlatform.instance.visibleGraphics(mapId);
  }

  Stream<BoundingBox> getBounds() {
    return ArcgisMapPlatform.instance.getBounds(mapId);
  }

  Stream<String> attributionText() {
    return ArcgisMapPlatform.instance.attributionText(mapId);
  }

  Stream<Attributes?> onClickListener() {
    return ArcgisMapPlatform.instance.onClickListener(mapId);
  }

  /// The map coordinates of every click on the map, hit or no hit.
  ///
  /// Complements [onClickListener], which answers *what* was clicked: this
  /// stream answers *where*, so a consumer can let a user place something on
  /// the map (a new site, a measurement point) while panning and zooming
  /// stay untouched. Web only for now.
  Stream<LatLng> onMapClickListener() {
    return ArcgisMapPlatform.instance.onMapClickListener(mapId);
  }

  void setMouseCursor(SystemMouseCursor cursor) {
    ArcgisMapPlatform.instance.setMouseCursor(cursor, mapId);
  }

  void updateGraphicSymbol({
    required String layerId,
    required String graphicId,
    required Symbol symbol,
  }) {
    ArcgisMapPlatform.instance.updateGraphicSymbol(
      mapId: mapId,
      layerId: layerId,
      symbol: symbol,
      graphicId: graphicId,
    );
  }

  Future<void> updateFeatureLayer({
    required String featureLayerId,
    required List<Graphic> data,
  }) {
    return ArcgisMapPlatform.instance.updateFeatureLayer(
      mapId: mapId,
      data: data,
      featureLayerId: featureLayerId,
    );
  }

  /// Sets the opacity of a whole layer, from 0 to 1, e.g. to fade its
  /// graphics in or out together. Web only for now.
  void setLayerOpacity({required String layerId, required double opacity}) {
    ArcgisMapPlatform.instance.setLayerOpacity(
      mapId: mapId,
      layerId: layerId,
      opacity: opacity,
    );
  }

  /// Every ArcGIS request whose URL starts with [urlPrefix] gets the headers
  /// [headers] returns at request time. A second call for the same prefix
  /// replaces the first. Headers apply page-wide, to the requests of every
  /// map. [urlPrefix] must be an absolute http or https URL whose path
  /// starts with `/`, such as `https://api.test/`. [headers] runs once per
  /// request, so it should answer from a cache. A failing [headers] fails
  /// that request. Web only for now.
  void setRequestHeaders({
    required String urlPrefix,
    required Future<Map<String, String>> Function() headers,
  }) {
    ArcgisMapPlatform.instance.setRequestHeaders(
      mapId: mapId,
      urlPrefix: urlPrefix,
      headers: headers,
    );
  }

  /// Removes the headers set for [urlPrefix], whichever map set them. Web
  /// only for now.
  void clearRequestHeaders({required String urlPrefix}) {
    ArcgisMapPlatform.instance.clearRequestHeaders(
      mapId: mapId,
      urlPrefix: urlPrefix,
    );
  }

  /// Shows or hides the named style layers in every vector tile layer of the
  /// current basemap, base and reference, including reference layers the SDK
  /// moved beneath the graphics. Ids a layer lacks are skipped. The SDK keeps
  /// the last visibility of every id it was given for the life of the map and
  /// applies it again after every basemap change. Completes once the layers
  /// of the current basemap have loaded and been changed. The visibility is
  /// kept even when the call throws because the current basemap failed to
  /// load. Web only for now.
  Future<void> setBasemapStyleLayersVisible({
    required List<String> styleLayerIds,
    required bool visible,
  }) {
    return ArcgisMapPlatform.instance.setBasemapStyleLayersVisible(
      mapId: mapId,
      styleLayerIds: styleLayerIds,
      visible: visible,
    );
  }

  bool destroyLayer({required String layerId}) {
    return ArcgisMapPlatform.instance
        .destroyLayer(layerId: layerId, mapId: mapId);
  }

  bool polygonContainsPoint({
    required String polygonId,
    required LatLng pointCoordinates,
  }) {
    return ArcgisMapPlatform.instance.polygonContainsPoint(
      polygonId: polygonId,
      pointCoordinates: pointCoordinates,
      mapId: mapId,
    );
  }

  /// Moves the camera to [point], at [scale] (the denominator of 1:scale)
  /// where given, else at [zoomLevel].
  ///
  /// A zoom level follows the tiling scheme of the basemap, so the same level
  /// shows another scale on a vector basemap than on a raster one; a scale
  /// shows the same on every basemap. [scale] is web only for now.
  Future<void> moveCamera({
    required LatLng point,
    double? zoomLevel,
    double? scale,
    int? threeDHeading,
    int? threeDTilt,
    AnimationOptions? animationOptions,
  }) {
    return ArcgisMapPlatform.instance.moveCamera(
      mapId: mapId,
      point: point,
      zoomLevel: zoomLevel,
      scale: scale,
      threeDHeading: threeDHeading,
      threeDTilt: threeDTilt,
      animationOptions: animationOptions,
    );
  }

  /// Moves the camera to the provided [points] and makes sure that all of
  /// them are visible.
  /// Currently, [padding] is only supported on mobile.
  Future<void> moveCameraToPoints({
    required List<LatLng> points,
    double? padding,
  }) {
    return ArcgisMapPlatform.instance.moveCameraToPoints(
      mapId: mapId,
      points: points,
      padding: padding,
    );
  }

  /// Adds a listener that gets notified if the map status changes.
  /// The listener can be removed by calling the [VoidCallback] returned by this function.
  VoidCallback addStatusChangeListener(MapStatusListener listener) {
    _listeners.add(listener);
    return () => _listeners.removeWhere((l) => l == listener);
  }

  /// Calling native `retryLoadAsync` (android) and `retryLoad` (swift)
  /// https://developers.arcgis.com/kotlin/api-reference/arcgis-maps-kotlin/com.arcgismaps/-loadable/retry-load.html
  /// This does not trigger `onMapCreated` since it will only try, if there is an error
  Future<void> retryLoad() {
    return ArcgisMapPlatform.instance.retryLoad(mapId);
  }

  void _notifyStatusChanged(MethodCall call) {
    _mapStatus = MapStatus.values.byName(call.arguments as String);
    for (final listener in _listeners) {
      listener(_mapStatus);
    }
  }

  Future<void> setInteraction({required bool isEnabled}) {
    return ArcgisMapPlatform.instance
        .setInteraction(mapId, isEnabled: isEnabled);
  }

  Future<bool> zoomIn({
    required int lodFactor,
    AnimationOptions? animationOptions,
  }) {
    return ArcgisMapPlatform.instance.zoomIn(
      lodFactor: lodFactor,
      mapId: mapId,
      animationOptions: animationOptions,
    );
  }

  Future<bool> zoomOut({
    required int lodFactor,
    AnimationOptions? animationOptions,
  }) {
    return ArcgisMapPlatform.instance.zoomOut(
      lodFactor: lodFactor,
      mapId: mapId,
      animationOptions: animationOptions,
    );
  }

  Future<void> setRotation(double angleDegrees) {
    return ArcgisMapPlatform.instance.setRotation(angleDegrees, mapId);
  }

  Future<void> addGraphic({required String layerId, required Graphic graphic}) {
    return ArcgisMapPlatform.instance.addGraphic(mapId, layerId, graphic);
  }

  Future<void> removeGraphic({
    required String layerId,
    required String objectId,
  }) {
    return ArcgisMapPlatform.instance.removeGraphic(mapId, layerId, objectId);
  }

  /// Removes the [Graphic]s from a specific [GraphicsLayer], given their [removeByAttributeKey] with an [removeByAttributeValue].
  /// If in this selection, there are [Graphic]s that should not be deleted,
  /// you cannot remove them using the key-value pair [excludeAttributeKey] with [excludeAttributeValues].
  ///
  /// For example, you want to remove all pins in the map, except the selected pin, then you remove the pin family
  /// and keep the selected pin using its id.
  ///
  /// If [removeByAttributeKey] is null, all graphics are removed.
  ///
  ///
  /// For example, you want to remove all pins in the map of 'type' : 'pin', except the pins with the id
  /// 'basePin01' and 'highlightPin04', then write the following function.
  ///
  /// ```dart
  ///  controller.removeGraphics(
  ///   removeByAttributeKey: 'type',
  ///   removeByAttributeValue: 'pin',
  ///   excludeAttributeKey: 'id',
  ///   excludeAttributeValues: ['basePin01', 'highlightPin04'],
  ///   );
  /// ```
  ///
  void removeGraphics({
    String? layerId,
    String? removeByAttributeKey,
    String? removeByAttributeValue,
    String? excludeAttributeKey,
    List<String>? excludeAttributeValues,
  }) {
    ArcgisMapPlatform.instance.removeGraphics(
      mapId: mapId,
      layerId: layerId,
      removeByAttributeKey: removeByAttributeKey,
      removeByAttributeValue: removeByAttributeValue,
      excludeAttributeKey: excludeAttributeKey,
      excludeAttributeValues: excludeAttributeValues,
    );
  }

  void addViewPadding({required ViewPadding padding}) {
    ArcgisMapPlatform.instance.addViewPadding(mapId, padding);
  }

  Future<void> toggleBaseMap({required BaseMap baseMap}) {
    return ArcgisMapPlatform.instance.toggleBaseMap(mapId, baseMap);
  }

  void dispose() {
    ArcgisMapPlatform.instance.dispose(mapId: mapId);
  }

  List<Graphic> getGraphicsInView() {
    return ArcgisMapPlatform.instance.getGraphicsInView(mapId);
  }

  Stream<bool> isGraphicHoveredStream() {
    return ArcgisMapPlatform.instance.isGraphicHoveredStream(mapId);
  }

  /// The attributes of the topmost graphic under the pointer, or null where
  /// the pointer is over no graphic.
  ///
  /// Complements [isGraphicHoveredStream], which only answers *whether*
  /// something is hovered. Emits on every pointer move, so a consumer that
  /// only cares about changes should apply `distinct`. Web only for now.
  Stream<Attributes?> hoveredGraphicStream() {
    return ArcgisMapPlatform.instance.hoveredGraphicStream(mapId);
  }

  List<String> getVisibleGraphicIds() {
    return ArcgisMapPlatform.instance.getVisibleGraphicIds(mapId);
  }

  Future<void> setLocationDisplay(ArcgisLocationDisplay locationDisplay) {
    return ArcgisMapPlatform.instance
        .setLocationDisplay(mapId, locationDisplay.type)
        .whenComplete(
      () {
        _locationDisplay.deattachFromMap();
        _locationDisplay = locationDisplay..attachToMap(mapId);
      },
    );
  }

  Future<void> updateIsAttributionTextVisible(bool isAttributionTextVisible) {
    return ArcgisMapPlatform.instance
        .updateIsAttributionTextVisible(mapId, isAttributionTextVisible);
  }
}
