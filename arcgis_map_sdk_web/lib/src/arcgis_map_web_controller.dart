// import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
//
// class ArcgisMapWebController {
//   List<Graphic> get graphicsInView => null;
//
//   Stream<bool> get isGraphicHoveredStream => null;
//
//   Future<void> moveCameraToPoints(
//       {required List<LatLng> points, double? padding}) async {}
//
//   void init() {}
//
//   Future<void> moveCamera(
//       {required LatLng point,
//       double? zoomLevel,
//       int? threeDHeading,
//       int? threeDTilt,
//       AnimationOptions? animationOptions}) async {}
//
//   Future<bool> zoomIn(
//       {required int lodFactor, AnimationOptions? animationOptions}) async {}
//
//   Future<bool> zoomOut(
//       {required int lodFactor, AnimationOptions? animationOptions}) async {}
//
//   Future<void> addGraphic(String layerId, Graphic graphic) async {}
//
//   Future<void> removeGraphic(String layerId, String objectId) async {}
//
//   void removeGraphics(
//       {String? layerId,
//       String? removeByAttributeKey,
//       String? removeByAttributeValue,
//       String? excludeAttributeKey,
//       List<String>? excludeAttributeValues}) {}
//
//   void addViewPadding({required ViewPadding padding}) {}
//
//   Future<void> toggleBaseMap({required BaseMap baseMap}) async {}
//
//   Future<FeatureLayer> addFeatureLayer(
//       FeatureLayerOptions options,
//       List<Graphic>? data,
//       void Function(dynamic p1)? onPressed,
//       String? url,
//       void Function(double p1)? getZoom,
//       String layerId) async {}
//
//   Future<GraphicsLayer> addGraphicsLayer(GraphicsLayerOptions options,
//       String layerId, void Function(dynamic p1)? onPressed) async {}
//
//   Future<SceneLayer> addSceneLayer(
//       {required SceneLayerOptions options,
//       required String layerId,
//       required String url}) async {}
//
//   void updateGraphicSymbol(
//       {required String layerId,
//       required Symbol symbol,
//       required String graphicId}) {}
//
//   void switchMapStyle(MapStyle mapStyle) {}
//
//   Stream<LatLng> centerPosition() {}
//
//   Stream<BoundingBox> getBounds() {}‚
//
//   Stream<List<String>> visibleGraphics() {}
//
//   List<String> getVisibleGraphicIds() {}
//
//   Stream<String> attributionText() {}
//
//   Stream<Attributes?> onClickListener() {}
//
//   Future<void> updateFeatureLayer(
//       {required String featureLayerId, required List<Graphic> data}) async {}
//
//   bool destroyLayer(String layerId) {}
//
//   bool polygonContainsPoint(String polygonId, LatLng pointCoordinates) {}
// }
