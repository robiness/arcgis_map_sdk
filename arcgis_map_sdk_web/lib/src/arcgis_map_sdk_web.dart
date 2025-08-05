import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/arcgis_map_web_js.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

@JS('eval')
external JSAny jsEval(JSString code);

class ArcgisMapWeb extends ArcgisMapPlatform {
  static final Map<int, JsMapView> _mapViews = {};
  static final Map<int, JsSceneView> _sceneViews = {};
  static final Map<int, bool> _isSceneViewActive = {};
  static final Map<int, Future Function(MethodCall)> _methodCallHandlers = {};
  static final Map<int, StreamController<Attributes?>> _clickControllers = {};
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
      String layerId) async {
    final view = _isSceneViewActive[mapId]!
        ? _sceneViews[mapId]!
        : _mapViews[mapId]!;

    // Check that FeatureLayer constructor is available globally after ArcGIS CDN loads
    final constructor = featureLayerConstructor;
    
    if (constructor == null) {
      throw Exception('FeatureLayer constructor not found. Ensure ArcGIS API is loaded.');
    }
    
    // Create FeatureLayer options as JSObject
    final featureLayerOptions = {
      'id': layerId,
      if (url != null) 'url': url,
    }.jsify() as JSObject;

    // Create FeatureLayer instance using jsEval with direct constructor call
    // This ensures the 'new' operator is used correctly
    final createFeatureLayerJS = '''
      (function(options) {
        return new window.FeatureLayer(options);
      })
    ''';
    final constructorFn = jsEval(createFeatureLayerJS.toJS) as JSFunction;
    final featureLayer = constructorFn.callAsFunction(null, featureLayerOptions) as JsFeatureLayer;

    view.map.add(featureLayer);

    return FeatureLayer(
      id: layerId,
      url: url,
    );
  }

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) {
    // TODO: implement addGraphic
    throw UnimplementedError();
  }

  @override
  Future<GraphicsLayer> addGraphicsLayer(GraphicsLayerOptions options,
      int mapId, String layerId, void Function(dynamic p1)? onPressed) async {
    final view = _isSceneViewActive[mapId]!
        ? _sceneViews[mapId]!
        : _mapViews[mapId]!;

    // Check that GraphicsLayer constructor is available globally after ArcGIS CDN loads
    final constructor = graphicsLayerConstructor;
    
    if (constructor == null) {
      throw Exception('GraphicsLayer constructor not found. Ensure ArcGIS API is loaded.');
    }
    
    // Create GraphicsLayer options as JSObject
    final graphicsLayerOptions = {
      'id': layerId,
    }.jsify() as JSObject;

    // Create GraphicsLayer instance using jsEval with direct constructor call
    // This ensures the 'new' operator is used correctly
    final createGraphicsLayerJS = '''
      (function(options) {
        return new window.GraphicsLayer(options);
      })
    ''';
    final constructorFn = jsEval(createGraphicsLayerJS.toJS) as JSFunction;
    final graphicsLayer = constructorFn.callAsFunction(null, graphicsLayerOptions) as JsGraphicsLayer;

    view.map.add(graphicsLayer);

    return GraphicsLayer(
      id: layerId,
    );
  }

  @override
  Future<SceneLayer> addSceneLayer({
    required SceneLayerOptions options,
    required String layerId,
    required String url,
    required int mapId,
  }) async {
    final view = _isSceneViewActive[mapId]!
        ? _sceneViews[mapId]!
        : _mapViews[mapId]!;

    // Check that SceneLayer constructor is available globally after ArcGIS CDN loads
    final constructor = sceneLayerConstructor;
    
    if (constructor == null) {
      throw Exception('SceneLayer constructor not found. Ensure ArcGIS API is loaded.');
    }
    
    // Create SceneLayer options as JSObject
    final sceneLayerOptions = {
      'url': url,
      'id': layerId,
    }.jsify() as JSObject;

    // Create SceneLayer instance using jsEval with direct constructor call
    // This ensures the 'new' operator is used correctly
    final createSceneLayerJS = '''
      (function(options) {
        return new window.SceneLayer(options);
      })
    ''';
    final constructorFn = jsEval(createSceneLayerJS.toJS) as JSFunction;
    final sceneLayer = constructorFn.callAsFunction(null, sceneLayerOptions) as JsSceneLayer;

    view.map.add(sceneLayer);

    return SceneLayer(
      id: layerId,
    );
  }

  @override
  void addViewPadding(int mapId, ViewPadding padding) {
    // TODO: implement addViewPadding
  }

  @override
  Stream<String> attributionText(int mapId) {
    final controller = StreamController<String>();
    final view = _isSceneViewActive[mapId]!
        ? _sceneViews[mapId]!
        : _mapViews[mapId]!;

    final attribution = JsAttribution(
      {'view': view}.jsify() as JSObject,
    );

    // Initial value
    controller.add(attribution.attributionText);

    // There's no watch handler in the JS interop,
    // so for now we'll just return the initial value.
    // TODO: Implement a watch handler to get updates.

    return controller.stream;
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

      // Create the map for 2D
      print('Creating 2D map...');
      final mapProperties2D = {
        'basemap': 'streets-navigation-vector'.toJS,
      }.jsify()! as JSObject;
      final map2D = JsEsriMap(mapProperties2D);
      print('2D Map created successfully');

      // Create the map for 3D with proper basemap and ground
      print('Creating 3D map...');
      final mapProperties3D = {
        'basemap': 'topo-3d'.toJS,
        'ground': 'world-elevation'.toJS,
      }.jsify()! as JSObject;
      final map3D = JsEsriMap(mapProperties3D);
      print('3D Map created successfully');

      // Wait for the container div to be created by Flutter
      print('Looking for container: map-$mapId');
      web.Element? container;
      
      // Wait up to 5 seconds for container to appear
      for (int i = 0; i < 50; i++) {
        container = web.document.getElementById('map-$mapId');
        if (container != null) break;
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      if (container == null) {
        throw Exception('Map container not found for id: map-$mapId after waiting');
      }
      print('Container found: ${container.id}');

      // Create the 2D MapView
      print('Creating 2D map view...');
      final mapViewProperties = {
        'container': container,
        'map': map2D,
        'zoom': 2.toJS,
        'center': [-118.805, 34.027].map((n) => n.toJS).toList().toJS,
      }.jsify()! as JSObject;
      final mapView = JsMapView(mapViewProperties);
      print('2D Map view created successfully');

      // Create the 3D SceneView (but don't attach container yet)
      print('Creating 3D scene view...');
      final sceneViewProperties = {
        'container': null, // Will be set when switching to 3D
        'map': map3D,
        'camera': {
          'position': {
            'spatialReference': {'latestWkid': 3857, 'wkid': 102100}.jsify(),
            'x': (-118.805 * 111320).toJS, // Rough conversion to Web Mercator
            'y': (34.027 * 111320).toJS,
            'z': 18161244.toJS,
          }.jsify(),
          'heading': 0.toJS,
          'tilt': 0.49.toJS,
        }.jsify(),
      }.jsify()! as JSObject;
      final sceneView = JsSceneView(sceneViewProperties);
      print('3D Scene view created successfully');

      // Store both views for later use
      _mapViews[mapId] = mapView;
      _sceneViews[mapId] = sceneView;
      _isSceneViewActive[mapId] = false; // Start with 2D view active

      // Set up click listeners for both views
      _setupClickListener(mapId, mapView);
      _setupClickListener(mapId, sceneView);

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
    cssLink.href =
        'https://js.arcgis.com/$_arcgisVersion/esri/themes/light/main.css';
    web.document.head?.appendChild(cssLink);
    print('CSS injected: ${cssLink.href}');

    // Inject JavaScript
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
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
          "esri/views/SceneView",
          "esri/widgets/Attribution",
          "esri/layers/SceneLayer",
          "esri/layers/GraphicsLayer",
          "esri/layers/FeatureLayer"
        ], function(Map, MapView, SceneView, Attribution, SceneLayer, GraphicsLayer, FeatureLayer) {
          console.log("ArcGIS modules loaded via AMD");
          
          // Expose modules globally with proper nested structure for Dart interop
          window.esri = {
            Map: Map,
            views: {
              MapView: MapView,
              SceneView: SceneView
            },
            widgets: {
              Attribution: Attribution
            },
            layers: {
              SceneLayer: SceneLayer,
              GraphicsLayer: GraphicsLayer,
              FeatureLayer: FeatureLayer
            }
          };
          
          // Expose constructors directly for easier Dart interop access
          window.SceneLayer = SceneLayer;
          window.GraphicsLayer = GraphicsLayer;
          window.FeatureLayer = FeatureLayer;
          
          // Signal that modules are ready
          window._arcgisModulesReady = true;
          console.log("ArcGIS modules exposed globally, including SceneLayer, GraphicsLayer, and FeatureLayer");
        });
      '''
          .toJS);

      // Wait for the modules to be loaded
      while (!jsEval(
              'typeof window._arcgisModulesReady !== "undefined" && window._arcgisModulesReady === true'
                  .toJS)
          .toString()
          .contains('true')) {
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
      final result = jsEval(
          'typeof window._arcgisModulesReady !== "undefined" && window._arcgisModulesReady === true'
              .toJS);
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
    if (!_clickControllers.containsKey(mapId)) {
      _clickControllers[mapId] = StreamController<Attributes?>.broadcast();
    }
    return _clickControllers[mapId]!.stream;
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
    _methodCallHandlers[mapId] = onCall;
    return Future.value();
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
    try {
      print('Switching map style for mapId: $mapId to: $mapStyle');

      final mapView = _mapViews[mapId];
      final sceneView = _sceneViews[mapId];
      final isCurrentlySceneView = _isSceneViewActive[mapId] ?? false;

      if (mapView == null || sceneView == null) {
        print('Views not found for mapId: $mapId');
        return;
      }

      final container = web.document.getElementById('map-$mapId');
      if (container == null) {
        print('Container not found for mapId: $mapId');
        return;
      }

      final shouldUse3D = mapStyle == MapStyle.threeD;

      if (shouldUse3D && !isCurrentlySceneView) {
        // Switch from 2D to 3D
        print('Switching from 2D to 3D');

        // Remove container from 2D view
        mapView.container = null;

        // Set container to 3D view
        sceneView.container = container;

        _isSceneViewActive[mapId] = true;
        print('Successfully switched to 3D view');
      } else if (!shouldUse3D && isCurrentlySceneView) {
        // Switch from 3D to 2D
        print('Switching from 3D to 2D');

        // Remove container from 3D view
        sceneView.container = null;

        // Set container to 2D view
        mapView.container = container;

        _isSceneViewActive[mapId] = false;
        print('Successfully switched to 2D view');
      } else {
        print(
            'No view change needed - already in ${shouldUse3D ? '3D' : '2D'} mode');
      }
    } catch (e) {
      print('Error switching map style: $e');
    }
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

  static void _setupClickListener(int mapId, JsView view) {
    // Create the click event handler
    final clickHandler = (JSObject event) {
      final controller = _clickControllers[mapId];
      if (controller != null) {
        // For now, emit null attributes as a basic implementation
        // TODO: Implement proper hit testing to get feature attributes
        controller.add(null);
      }
    }.toJS as JSFunction;

    // Add click event listener to the view
    final eventArray = ['click'.toJS].toJS;
    view.on(eventArray, clickHandler);
  }
}
