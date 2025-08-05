import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:arcgis_map_sdk_web/arcgis_map_web_js.dart';
import 'dart:js_interop';
import 'dart:async';

@JS('eval')
external JSAny jsEval(JSString code);

class ArcgisMapWeb extends ArcgisMapPlatform {
  static final Map<int, JsMapView> _mapViews = {};
  static bool _scriptsInjected = false;
  static const _arcgisVersion = '4.33';
  static final Set<String> _registeredViewTypes = {};
  static Completer<void>? _arcgisModulesCompleter;

  /// Registers this class as the default instance of [ArcgisMapPlatform].
  static void registerWith(Registrar registrar) {
    print('ArcgisMapWeb.registerWith called');
    ArcgisMapPlatform.instance = ArcgisMapWeb();
    print('ArcgisMapWeb registered as platform instance');
  }

  @override
  Future<FeatureLayer> addFeatureLayer(
      FeatureLayerOptions options,
      List<Graphic>? data,
      void Function(dynamic p1)? onPressed,
      String? url,
      int mapId,
      void Function(double p1)? getZoom,
      String layerId) {
    // TODO: implement addFeatureLayer
    throw UnimplementedError();
  }

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) {
    // TODO: implement addGraphic
    throw UnimplementedError();
  }

  @override
  Future<GraphicsLayer> addGraphicsLayer(GraphicsLayerOptions options,
      int mapId, String layerId, void Function(dynamic p1)? onPressed) {
    // TODO: implement addGraphicsLayer
    throw UnimplementedError();
  }

  @override
  Future<SceneLayer> addSceneLayer(
      {required SceneLayerOptions options,
      required String layerId,
      required String url,
      required int mapId}) {
    // TODO: implement addSceneLayer
    throw UnimplementedError();
  }

  @override
  void addViewPadding(int mapId, ViewPadding padding) {
    // TODO: implement addViewPadding
  }

  @override
  Stream<String> attributionText(int mapId) {
    // TODO: implement attributionText
    throw UnimplementedError();
  }

  @override
  Widget buildView(
      {required int creationId,
      required PlatformViewCreatedCallback onPlatformViewCreated,
      required ArcgisMapOptions mapOptions}) {
    print('buildView called with creationId: $creationId');
    
    final viewType = 'arcgis-map-$creationId';
    
    // Register the HTML element factory only once
    if (!_registeredViewTypes.contains(viewType)) {
      print('Registering view factory for: $viewType');
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        print('Creating HTML element for viewId: $viewId');
        final mapDiv = web.document.createElement('div') as web.HTMLDivElement;
        mapDiv.id = 'map-$viewId';
        mapDiv.style.width = '100%';
        mapDiv.style.height = '100%';
        print('HTML element created with id: ${mapDiv.id}');
        return mapDiv;
      });
      _registeredViewTypes.add(viewType);
    } else {
      print('View factory already registered for: $viewType');
    }
    
    print('Returning HtmlElementView');
    return HtmlElementView(
      viewType: viewType,
      onPlatformViewCreated: (int id) {
        print('onPlatformViewCreated called with id: $id');
        onPlatformViewCreated(id);
      },
    );
  }

  @override
  Stream<LatLng> centerPosition(int mapId) {
    // TODO: implement centerPosition
    throw UnimplementedError();
  }

  @override
  bool destroyLayer({required int mapId, required String layerId}) {
    // TODO: implement destroyLayer
    throw UnimplementedError();
  }

  @override
  void dispose({required int mapId}) {
    // TODO: implement dispose
  }

  @override
  Future<Uint8List> exportImage(int mapId) {
    // TODO: implement exportImage
    throw UnimplementedError();
  }

  @override
  Future<AutoPanMode> getAutoPanMode(int mapId) {
    // TODO: implement getAutoPanMode
    throw UnimplementedError();
  }

  @override
  Stream<BoundingBox> getBounds(int mapId) {
    // TODO: implement getBounds
    throw UnimplementedError();
  }

  @override
  List<Graphic> getGraphicsInView(int mapId) {
    // TODO: implement getGraphicsInView
    throw UnimplementedError();
  }

  @override
  List<String> getVisibleGraphicIds(int mapId) {
    // TODO: implement getVisibleGraphicIds
    throw UnimplementedError();
  }

  @override
  Future<double> getWanderExtentFactor(int mapId) {
    // TODO: implement getWanderExtentFactor
    throw UnimplementedError();
  }

  @override
  Stream<double> getZoom(int mapId) {
    // TODO: implement getZoom
    throw UnimplementedError();
  }

  @override
  Future<void> init(int mapId) async {
    try {
      print('Starting map initialization for mapId: $mapId');
      
      // Wait for ArcGIS API to be loaded
      print('Waiting for ArcGIS API...');
      await _waitForArcGISAPI();
      print('ArcGIS API loaded successfully');

      // Create the map
      print('Creating map...');
      final mapProperties = {
        'basemap': 'streets-navigation-vector'.toJS,
      }.jsify()! as JSObject;
      final map = JsEsriMap(mapProperties);
      print('Map created successfully');

      // Find the container div
      print('Looking for container: map-$mapId');
      final container = web.document.getElementById('map-$mapId');
      if (container == null) {
        throw Exception('Map container not found for id: map-$mapId');
      }
      print('Container found: ${container.id}');

      // Create the map view
      print('Creating map view...');
      final mapViewProperties = {
        'container': container,
        'map': map,
        'zoom': 2.toJS,
        'center': [-118.805, 34.027].map((n) => n.toJS).toList().toJS,
      }.jsify()! as JSObject;
      final mapView = JsMapView(mapViewProperties);
      print('Map view created successfully');

      // Store the map view for later use
      _mapViews[mapId] = mapView;
      print('Map initialization completed for mapId: $mapId');
    } catch (e) {
      print('Error initializing map: $e');
      rethrow;
    }
  }

  Future<void> _waitForArcGISAPI() async {
    if (!_scriptsInjected) {
      await _injectArcGISScripts();
      _scriptsInjected = true;
    }
    
    // Check if esri object exists
    while (!_isArcGISAPILoaded()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<void> _injectArcGISScripts() async {
    print('Starting ArcGIS script injection...');
    
    // Inject CSS
    final cssLink = web.document.createElement('link') as web.HTMLLinkElement;
    cssLink.rel = 'stylesheet';
    cssLink.href = 'https://js.arcgis.com/$_arcgisVersion/esri/themes/light/main.css';
    web.document.head?.appendChild(cssLink);
    print('CSS injected: ${cssLink.href}');

    // Inject JavaScript
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://js.arcgis.com/$_arcgisVersion/';
    script.async = true;
    
    print('Script element created: ${script.src}');
    
    // Wait for script to load
    final scriptCompleter = Completer<void>();
    script.onLoad.listen((_) {
      print('ArcGIS script loaded successfully');
      scriptCompleter.complete();
    });
    script.onError.listen((error) {
      print('Failed to load ArcGIS script: $error');
      scriptCompleter.completeError('Failed to load ArcGIS API: $error');
    });
    
    web.document.head?.appendChild(script);
    print('Script added to document head');
    
    try {
      await scriptCompleter.future;
      print('Script loaded, now requiring AMD modules...');
      
      // Now use AMD require to load the modules and expose them globally
      _arcgisModulesCompleter = Completer<void>();
      
      jsEval('''
        // Configure AMD loader to use the correct base path
        require.config({
          baseUrl: "https://js.arcgis.com/$_arcgisVersion/",
          paths: {
            "esri": "esri"
          }
        });
        
        require([
          "esri/Map",
          "esri/views/MapView",
          "esri/views/SceneView"
        ], function(Map, MapView, SceneView) {
          console.log("ArcGIS modules loaded via AMD");
          
          // Expose modules globally with proper nested structure for Dart interop
          window.esri = {
            Map: Map,
            views: {
              MapView: MapView,
              SceneView: SceneView
            }
          };
          
          // Signal that modules are ready
          window._arcgisModulesReady = true;
          console.log("ArcGIS modules exposed globally");
        });
      '''.toJS);
      
      // Wait for the modules to be loaded
      while (!jsEval('typeof window._arcgisModulesReady !== "undefined" && window._arcgisModulesReady === true'.toJS).toString().contains('true')) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _arcgisModulesCompleter!.complete();
      print('ArcGIS AMD modules loaded and exposed globally');
    } catch (e) {
      print('Script injection failed: $e');
      rethrow;
    }
  }

  bool _isArcGISAPILoaded() {
    try {
      // Check if our AMD modules are loaded and ready
      final result = jsEval('typeof window._arcgisModulesReady !== "undefined" && window._arcgisModulesReady === true'.toJS);
      final isLoaded = result.toString().contains('true');
      print('ArcGIS API loaded check: $isLoaded');
      return isLoaded;
    } catch (e) {
      print('Error checking ArcGIS API: $e');
      return false;
    }
  }

  @override
  Stream<bool> isGraphicHoveredStream(int mapId) {
    // TODO: implement isGraphicHoveredStream
    throw UnimplementedError();
  }

  @override
  Future<void> moveCamera(
      {required LatLng point,
      required int mapId,
      double? zoomLevel,
      int? threeDHeading,
      int? threeDTilt,
      AnimationOptions? animationOptions}) {
    // TODO: implement moveCamera
    throw UnimplementedError();
  }

  @override
  Future<void> moveCameraToPoints(
      {required List<LatLng> points, required int mapId, double? padding}) {
    // TODO: implement moveCameraToPoints
    throw UnimplementedError();
  }

  @override
  Stream<Attributes?> onClickListener(int mapId) {
    // TODO: implement onClickListener
    throw UnimplementedError();
  }

  @override
  bool polygonContainsPoint(
      {required String polygonId,
      required LatLng pointCoordinates,
      required int mapId}) {
    // TODO: implement polygonContainsPoint
    throw UnimplementedError();
  }

  @override
  Future<void> removeGraphic(int mapId, String layerId, String graphicId) {
    // TODO: implement removeGraphic
    throw UnimplementedError();
  }

  @override
  void removeGraphics(
      {required int mapId,
      String? layerId,
      String? removeByAttributeKey,
      String? removeByAttributeValue,
      String? excludeAttributeKey,
      List<String>? excludeAttributeValues}) {
    // TODO: implement removeGraphics
  }

  @override
  Future<void> retryLoad(int mapId) {
    // TODO: implement retryLoad
    throw UnimplementedError();
  }

  @override
  Future<void> setAutoPanMode(String autoPanMode, int mapId) {
    // TODO: implement setAutoPanMode
    throw UnimplementedError();
  }

  @override
  Future<void> setInteraction(int mapId, {required bool isEnabled}) {
    // TODO: implement setInteraction
    throw UnimplementedError();
  }

  @override
  Future<void> setLocationDisplay(int mapId, String type) {
    // TODO: implement setLocationDisplay
    throw UnimplementedError();
  }

  @override
  Future<void> setLocationDisplayAccuracySymbol(int mapId, Symbol symbol) {
    // TODO: implement setLocationDisplayAccuracySymbol
    throw UnimplementedError();
  }

  @override
  Future<void> setLocationDisplayDefaultSymbol(int mapId, Symbol symbol) {
    // TODO: implement setLocationDisplayDefaultSymbol
    throw UnimplementedError();
  }

  @override
  Future<void> setLocationDisplayPingAnimationSymbol(int mapId, Symbol symbol) {
    // TODO: implement setLocationDisplayPingAnimationSymbol
    throw UnimplementedError();
  }

  @override
  Future<void> setMethodCallHandler(
      {required int mapId, required Future Function(MethodCall p1) onCall}) {
    // TODO: implement setMethodCallHandler
    throw UnimplementedError();
  }

  @override
  void setMouseCursor(SystemMouseCursor cursor, int mapId) {
    // TODO: implement setMouseCursor
  }

  @override
  Future<void> setRotation(double angleDegrees, int mapId) {
    // TODO: implement setRotation
    throw UnimplementedError();
  }

  @override
  Future<void> setUseCourseSymbolOnMovement(int mapId, bool useCourseSymbol) {
    // TODO: implement setUseCourseSymbolOnMovement
    throw UnimplementedError();
  }

  @override
  void setWanderExtentFactor(double factor, int mapId) {
    // TODO: implement setWanderExtentFactor
  }

  @override
  Future<void> startLocationDisplayDataSource(int mapId) {
    // TODO: implement startLocationDisplayDataSource
    throw UnimplementedError();
  }

  @override
  Future<void> stopLocationDisplayDataSource(int mapId) {
    // TODO: implement stopLocationDisplayDataSource
    throw UnimplementedError();
  }

  @override
  void switchMapStyle(int mapId, MapStyle mapStyle) {
    // TODO: implement switchMapStyle
  }

  @override
  Future<void> toggleBaseMap(int mapId, BaseMap baseMap) {
    // TODO: implement toggleBaseMap
    throw UnimplementedError();
  }

  @override
  Future<void> updateFeatureLayer(
      {required int mapId,
      required String featureLayerId,
      required List<Graphic> data}) {
    // TODO: implement updateFeatureLayer
    throw UnimplementedError();
  }

  @override
  void updateGraphicSymbol(
      {required int mapId,
      required String layerId,
      required String graphicId,
      required Symbol symbol}) {
    // TODO: implement updateGraphicSymbol
  }

  @override
  Future<void> updateIsAttributionTextVisible(
      int mapId, bool isAttributionTextVisible) {
    // TODO: implement updateIsAttributionTextVisible
    throw UnimplementedError();
  }

  @override
  Future<void> updateLocationDisplaySourcePositionManually(
      int mapId, UserPosition position) {
    // TODO: implement updateLocationDisplaySourcePositionManually
    throw UnimplementedError();
  }

  @override
  Stream<List<String>> visibleGraphics(int mapId) {
    // TODO: implement visibleGraphics
    throw UnimplementedError();
  }

  @override
  Future<bool> zoomIn(
      {required int lodFactor,
      required int mapId,
      AnimationOptions? animationOptions}) {
    // TODO: implement zoomIn
    throw UnimplementedError();
  }

  @override
  Future<bool> zoomOut(
      {required int lodFactor,
      required int mapId,
      AnimationOptions? animationOptions}) {
    // TODO: implement zoomOut
    throw UnimplementedError();
  }
}
