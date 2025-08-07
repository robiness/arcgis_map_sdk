import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/arcgis_map_web_js.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
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
    final view =
        _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

    // Check that FeatureLayer constructor is available globally after ArcGIS CDN loads
    final constructor = featureLayerConstructor;

    if (constructor == null) {
      throw Exception(
          'FeatureLayer constructor not found. Ensure ArcGIS API is loaded.');
    }

    // Create FeatureLayer options as JSObject
    final featureLayerOptions = <String, dynamic>{
      'id': layerId,
      if (url != null) 'url': url,
    };

    // If no URL provided, create a local feature layer with fields
    if (url == null) {
      // Create fields for local feature layer
      final fields = [
        {
          'name': 'OBJECTID',
          'alias': 'ObjectID',
          'type': 'oid'
        },
        {
          'name': 'id',
          'alias': 'ID',
          'type': 'string'
        }
      ];
      
      featureLayerOptions.addAll({
        'source': [], // Empty source for local features
        'fields': fields,
        'objectIdField': 'OBJECTID',
        'geometryType': 'point', // Default to point
      });
    }

    final jsOptions = featureLayerOptions.jsify() as JSObject;

    // Create FeatureLayer instance using jsEval with direct constructor call
    // This ensures the 'new' operator is used correctly
    final createFeatureLayerJS = '''
      (function(options) {
        return new window.FeatureLayer(options);
      })
    ''';
    final constructorFn = jsEval(createFeatureLayerJS.toJS) as JSFunction;
    final featureLayer = constructorFn.callAsFunction(null, jsOptions)
        as JsFeatureLayer;

    view.map.add(featureLayer);

    return FeatureLayer(
      id: layerId,
      url: url,
    );
  }

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) async {
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    // Find the graphics layer
    final layer = view.map.findLayerById(layerId.toJS) as JsGraphicsLayer?;
    if (layer == null) {
      throw Exception('Graphics layer with id $layerId not found');
    }
    
    // Convert Dart graphic to JS graphic
    final graphicData = graphic.toJson().jsify() as JSObject;
    
    // Create JS Graphic using eval
    final createGraphicJS = '''
      (function(graphicData) {
        return new window.Graphic(graphicData);
      })
    ''';
    final constructorFn = jsEval(createGraphicJS.toJS) as JSFunction;
    final jsGraphic = constructorFn.callAsFunction(null, graphicData) as JsGraphic;
    
    // Add graphic to the layer
    layer.add(jsGraphic);
    
    return Future.value();
  }

  @override
  Future<GraphicsLayer> addGraphicsLayer(GraphicsLayerOptions options,
      int mapId, String layerId, void Function(dynamic p1)? onPressed) async {
    final view =
        _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

    // Check that GraphicsLayer constructor is available globally after ArcGIS CDN loads
    final constructor = graphicsLayerConstructor;

    if (constructor == null) {
      throw Exception(
          'GraphicsLayer constructor not found. Ensure ArcGIS API is loaded.');
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
    final graphicsLayer = constructorFn.callAsFunction(
        null, graphicsLayerOptions) as JsGraphicsLayer;

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
    final view =
        _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

    // Check that SceneLayer constructor is available globally after ArcGIS CDN loads
    final constructor = sceneLayerConstructor;

    if (constructor == null) {
      throw Exception(
          'SceneLayer constructor not found. Ensure ArcGIS API is loaded.');
    }

    // SceneLayer should preferably be added to 3D SceneView
    if (!_isSceneViewActive[mapId]!) {
      print('Warning: SceneLayer works best in 3D mode. Consider switching to 3D view.');
    }

    // Create SceneLayer options as JSObject
    final sceneLayerOptions = {
      'url': url,
      'id': layerId,
    }.jsify() as JSObject;

    try {
      // Create SceneLayer instance using jsEval with direct constructor call
      // This ensures the 'new' operator is used correctly
      final createSceneLayerJS = '''
        (function(options) {
          return new window.SceneLayer(options);
        })
      ''';
      final constructorFn = jsEval(createSceneLayerJS.toJS) as JSFunction;
      final sceneLayer =
          constructorFn.callAsFunction(null, sceneLayerOptions) as JsSceneLayer;

      view.map.add(sceneLayer);

      print('SceneLayer added successfully with id: $layerId');
      return SceneLayer(
        id: layerId,
      );
    } catch (e) {
      print('Error creating SceneLayer: $e');
      // Still return the layer object even if there was an error
      // The error might be logged by ArcGIS but not necessarily fatal
      return SceneLayer(
        id: layerId,
      );
    }
  }

  @override
  void addViewPadding(int mapId, ViewPadding padding) {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      final paddingObject = {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      }.jsify() as JSObject;
      
      view.padding = paddingObject;
      print('View padding set for mapId: $mapId');
    } catch (e) {
      print('Error setting view padding: $e');
    }
  }

  @override
  Stream<String> attributionText(int mapId) {
    final controller = StreamController<String>();
    final view =
        _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

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
    final controller = StreamController<LatLng>.broadcast();
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    // Get initial center position
    final center = view.center as JsPoint;
    controller.add(LatLng(center.latitude, center.longitude));
    
    // Watch for center changes
    final centerHandler = (JSObject event) {
      final newCenter = view.center as JsPoint;
      controller.add(LatLng(newCenter.latitude, newCenter.longitude));
    }.toJS as JSFunction;
    
    final eventArray = ['center'.toJS].toJS;
    view.on(eventArray, centerHandler);
    
    return controller.stream;
  }

  @override
  bool destroyLayer({required int mapId, required String layerId}) {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      // Find and remove the layer
      final layer = view.map.findLayerById(layerId.toJS) as JsLayer?;
      if (layer != null) {
        // Remove from map
        final removeFn = jsEval('''
          (function(map, layer) {
            map.remove(layer);
          })
        '''.toJS) as JSFunction;
        removeFn.callAsFunction(null, view.map, layer);
        
        // Destroy the layer
        layer.destroy();
        return true;
      }
      return false;
    } catch (e) {
      print('Error destroying layer: $e');
      return false;
    }
  }

  @override
  void dispose({required int mapId}) {
    try {
      // Destroy views
      final mapView = _mapViews[mapId];
      final sceneView = _sceneViews[mapId];
      
      if (mapView != null) {
        final destroyFn = jsEval('''
          (function(view) {
            if (view.destroy) {
              view.destroy();
            }
          })
        '''.toJS) as JSFunction;
        destroyFn.callAsFunction(null, mapView);
      }
      
      if (sceneView != null) {
        final destroySceneFn = jsEval('''
          (function(view) {
            if (view.destroy) {
              view.destroy();
            }
          })
        '''.toJS) as JSFunction;
        destroySceneFn.callAsFunction(null, sceneView);
      }
      
      // Clean up controllers
      _clickControllers[mapId]?.close();
      
      // Remove from maps
      _mapViews.remove(mapId);
      _sceneViews.remove(mapId);
      _isSceneViewActive.remove(mapId);
      _methodCallHandlers.remove(mapId);
      _clickControllers.remove(mapId);
      
      print('Disposed map resources for mapId: $mapId');
    } catch (e) {
      print('Error disposing map: $e');
    }
  }

  @override
  Future<Uint8List> exportImage(int mapId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      // Use takeScreenshot method from ArcGIS API
      final takeScreenshotJS = '''
        (function(view) {
          return view.takeScreenshot();
        })
      ''';
      
      final screenshotFn = jsEval(takeScreenshotJS.toJS) as JSFunction;
      final screenshotPromise = screenshotFn.callAsFunction(null, view) as JSPromise;
      
      final screenshotResult = await screenshotPromise.toDart;
      
      // Extract data URL and convert to Uint8List
      final extractDataUrlJS = '''
        (function(result) {
          return result.dataUrl;
        })
      ''';
      final extractFn = jsEval(extractDataUrlJS.toJS) as JSFunction;
      final dataUrl = extractFn.callAsFunction(null, screenshotResult) as JSString;
      final base64Data = dataUrl.toDart.split(',')[1]; // Remove data:image/png;base64,
      
      return base64Decode(base64Data);
    } catch (e) {
      print('Error exporting image: $e');
      rethrow;
    }
  }

  @override
  Future<AutoPanMode> getAutoPanMode(int mapId) async {
    // Web implementation doesn't have AutoPan mode - return default
    return AutoPanMode.off;
  }

  @override
  Stream<BoundingBox> getBounds(int mapId) {
    final controller = StreamController<BoundingBox>.broadcast();
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    // Get initial bounds
    final extent = view.extent;
    final initialBounds = BoundingBox(
      height: extent.height,
      width: extent.width,
      topRight: LatLng(extent.center.latitude + (extent.height / 2), 
                      extent.center.longitude + (extent.width / 2)),
      lowerLeft: LatLng(extent.center.latitude - (extent.height / 2),
                       extent.center.longitude - (extent.width / 2)),
    );
    controller.add(initialBounds);
    
    // Watch for extent changes
    final extentHandler = (JSObject event) {
      final newExtent = view.extent;
      final newBounds = BoundingBox(
        height: newExtent.height,
        width: newExtent.width,
        topRight: LatLng(newExtent.center.latitude + (newExtent.height / 2),
                        newExtent.center.longitude + (newExtent.width / 2)),
        lowerLeft: LatLng(newExtent.center.latitude - (newExtent.height / 2),
                         newExtent.center.longitude - (newExtent.width / 2)),
      );
      controller.add(newBounds);
    }.toJS as JSFunction;
    
    final eventArray = ['extent'.toJS].toJS;
    view.on(eventArray, extentHandler);
    
    return controller.stream;
  }

  @override
  List<Graphic> getGraphicsInView(int mapId) {
    // Web implementation - would require complex geometry operations
    // Return empty list for now as this is mainly used for performance optimization
    return [];
  }

  @override
  List<String> getVisibleGraphicIds(int mapId) {
    // Web implementation - would require complex visibility calculations
    // Return empty list for now as this is mainly used for performance optimization
    return [];
  }

  @override
  Future<double> getWanderExtentFactor(int mapId) async {
    // Web implementation uses default wander extent factor
    return 10.0;
  }

  @override
  Stream<double> getZoom(int mapId) {
    final controller = StreamController<double>.broadcast();
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    // Initial zoom value
    controller.add(view.zoom);
    
    // Watch for zoom changes
    final zoomHandler = (JSObject event) {
      controller.add(view.zoom);
    }.toJS as JSFunction;
    
    final eventArray = ['zoom'.toJS].toJS;
    view.on(eventArray, zoomHandler);
    
    return controller.stream;
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
        throw Exception(
            'Map container not found for id: map-$mapId after waiting');
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
          "esri/layers/FeatureLayer",
          "esri/Graphic"
        ], function(Map, MapView, SceneView, Attribution, SceneLayer, GraphicsLayer, FeatureLayer, Graphic) {
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
            },
            Graphic: Graphic
          };
          
          // Expose constructors directly for easier Dart interop access
          window.SceneLayer = SceneLayer;
          window.GraphicsLayer = GraphicsLayer;
          window.FeatureLayer = FeatureLayer;
          window.Graphic = Graphic;
          
          // Signal that modules are ready
          window._arcgisModulesReady = true;
          console.log("ArcGIS modules exposed globally, including Graphic, SceneLayer, GraphicsLayer, and FeatureLayer");
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
    // Web implementation - would need hover event handling
    // Return stream that emits false for now
    final controller = StreamController<bool>.broadcast();
    controller.add(false);
    return controller.stream;
  }

  @override
  Future<void> moveCamera(
      {required LatLng point,
      required int mapId,
      double? zoomLevel,
      int? threeDHeading,
      int? threeDTilt,
      AnimationOptions? animationOptions}) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      final target = <String, dynamic>{
        'center': [point.longitude, point.latitude],
        if (zoomLevel != null) 'zoom': zoomLevel,
      };
      
      // For 3D views, set camera properties
      if (_isSceneViewActive[mapId]! && (threeDHeading != null || threeDTilt != null)) {
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
      
      await view.goTo(jsTarget, options).toDart;
    } catch (e) {
      print('Error moving camera: $e');
      rethrow;
    }
  }

  @override
  Future<void> moveCameraToPoints(
      {required List<LatLng> points, required int mapId, double? padding}) async {
    if (points.isEmpty) return;
    
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
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
      
      final options = padding != null 
          ? {'padding': padding}.jsify() as JSObject
          : null;
      
      await view.goTo(target, options).toDart;
    } catch (e) {
      print('Error moving camera to points: $e');
      rethrow;
    }
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
    // Web implementation - would require complex geometry operations with ArcGIS JS API
    // Return false for now as this requires geometric analysis
    print('polygonContainsPoint not fully implemented for web - requires geometry analysis');
    return false;
  }

  @override
  Future<void> removeGraphic(int mapId, String layerId, String graphicId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      // Find the graphics layer
      final layer = view.map.findLayerById(layerId.toJS) as JsGraphicsLayer?;
      if (layer == null) {
        throw Exception('Graphics layer with id $layerId not found');
      }
      
      // Find and remove the graphic with matching ID
      final removeGraphicJS = '''
        (function(layer, graphicId) {
          if (layer.graphics && layer.graphics.items) {
            const graphicToRemove = layer.graphics.items.find(g => 
              g.attributes && g.attributes.id === graphicId
            );
            if (graphicToRemove) {
              layer.remove(graphicToRemove);
              return true;
            }
          }
          return false;
        })
      ''';
      
      final removeFn = jsEval(removeGraphicJS.toJS) as JSFunction;
      removeFn.callAsFunction(null, layer, graphicId.toJS);
    } catch (e) {
      print('Error removing graphic: $e');
      rethrow;
    }
  }

  @override
  void removeGraphics(
      {required int mapId,
      String? layerId,
      String? removeByAttributeKey,
      String? removeByAttributeValue,
      String? excludeAttributeKey,
      List<String>? excludeAttributeValues}) {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      if (layerId != null) {
        // Remove graphics from specific layer
        final layer = view.map.findLayerById(layerId.toJS) as JsGraphicsLayer?;
        if (layer == null) return;
        
        final removeGraphicsJS = '''
          (function(layer, options) {
            if (!layer.graphics || !layer.graphics.items) return;
            
            const graphicsToRemove = layer.graphics.items.filter(graphic => {
              if (!graphic.attributes) return false;
              
              // Check remove criteria
              if (options.removeKey && options.removeValue) {
                if (graphic.attributes[options.removeKey] !== options.removeValue) return false;
              }
              
              // Check exclude criteria  
              if (options.excludeKey && options.excludeValues) {
                const excludeArray = Array.isArray(options.excludeValues) ? options.excludeValues : [options.excludeValues];
                if (excludeArray.includes(graphic.attributes[options.excludeKey])) return false;
              }
              
              return true;
            });
            
            graphicsToRemove.forEach(graphic => layer.remove(graphic));
          })
        ''';
        
        final options = {
          'removeKey': removeByAttributeKey,
          'removeValue': removeByAttributeValue,
          'excludeKey': excludeAttributeKey,
          'excludeValues': excludeAttributeValues,
        }.jsify() as JSObject;
        
        final removeFn = jsEval(removeGraphicsJS.toJS) as JSFunction;
        removeFn.callAsFunction(null, layer, options);
      } else {
        // Remove from all graphics layers
        final removeFromAllJS = '''
          (function(map, options) {
            map.layers.items.forEach(layer => {
              if (layer.type === 'graphics' && layer.graphics && layer.graphics.items) {
                const graphicsToRemove = layer.graphics.items.filter(graphic => {
                  if (!graphic.attributes) return false;
                  
                  // Check remove criteria
                  if (options.removeKey && options.removeValue) {
                    if (graphic.attributes[options.removeKey] !== options.removeValue) return false;
                  }
                  
                  // Check exclude criteria  
                  if (options.excludeKey && options.excludeValues) {
                    const excludeArray = Array.isArray(options.excludeValues) ? options.excludeValues : [options.excludeValues];
                    if (excludeArray.includes(graphic.attributes[options.excludeKey])) return false;
                  }
                  
                  return true;
                });
                
                graphicsToRemove.forEach(graphic => layer.remove(graphic));
              }
            });
          })
        ''';
        
        final options = {
          'removeKey': removeByAttributeKey,
          'removeValue': removeByAttributeValue,
          'excludeKey': excludeAttributeKey,
          'excludeValues': excludeAttributeValues,
        }.jsify() as JSObject;
        
        final removeFn = jsEval(removeFromAllJS.toJS) as JSFunction;
        removeFn.callAsFunction(null, view.map, options);
      }
    } catch (e) {
      print('Error removing graphics: $e');
    }
  }

  @override
  Future<void> retryLoad(int mapId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      // Refresh/reload the map and its layers
      final retryLoadJS = '''
        (function(view) {
          if (view.map && view.map.layers) {
            view.map.layers.items.forEach(layer => {
              if (layer.refresh) {
                layer.refresh();
              } else if (layer.load) {
                layer.load();
              }
            });
          }
          // Also refresh the view itself if possible
          if (view.refresh) {
            view.refresh();
          }
        })
      ''';
      
      final retryFn = jsEval(retryLoadJS.toJS) as JSFunction;
      retryFn.callAsFunction(null, view);
      
      print('Retry load completed for mapId: $mapId');
    } catch (e) {
      print('Error retrying load: $e');
      rethrow;
    }
  }

  @override
  Future<void> setAutoPanMode(String autoPanMode, int mapId) async {
    // Web implementation doesn't support AutoPan mode - mainly for mobile GPS
    print('setAutoPanMode not supported on web: $autoPanMode');
  }

  @override
  Future<void> setInteraction(int mapId, {required bool isEnabled}) {
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    // Set navigation interaction on the view
    
    final interactionFn = jsEval('''
      (function(view, enabled) {
        view.navigation.enabled = enabled;
      })
    '''.toJS) as JSFunction;
    interactionFn.callAsFunction(null, view, isEnabled.toJS);
    
    return Future.value();
  }

  @override
  Future<void> setLocationDisplay(int mapId, String type) async {
    // Web implementation - location display is mainly for mobile GPS
    print('Location display not fully supported on web: $type');
  }

  @override
  Future<void> setLocationDisplayAccuracySymbol(int mapId, Symbol symbol) async {
    // Web implementation - location display is mainly for mobile GPS
    print('Location display symbols not supported on web');
  }

  @override
  Future<void> setLocationDisplayDefaultSymbol(int mapId, Symbol symbol) async {
    // Web implementation - location display is mainly for mobile GPS
    print('Location display symbols not supported on web');
  }

  @override
  Future<void> setLocationDisplayPingAnimationSymbol(int mapId, Symbol symbol) async {
    // Web implementation - location display is mainly for mobile GPS  
    print('Location display symbols not supported on web');
  }

  @override
  Future<void> setMethodCallHandler(
      {required int mapId, required Future Function(MethodCall p1) onCall}) {
    _methodCallHandlers[mapId] = onCall;
    return Future.value();
  }

  @override
  void setMouseCursor(SystemMouseCursor cursor, int mapId) {
    final container = web.document.getElementById('map-$mapId') as web.HTMLElement?;
    if (container == null) return;
    
    String cssValue = 'default';
    if (cursor == SystemMouseCursors.click) {
      cssValue = 'pointer';
    } else if (cursor == SystemMouseCursors.grab) {
      cssValue = 'grab';
    } else if (cursor == SystemMouseCursors.grabbing) {
      cssValue = 'grabbing';
    } else if (cursor == SystemMouseCursors.move) {
      cssValue = 'move';
    } else if (cursor == SystemMouseCursors.wait) {
      cssValue = 'wait';
    } else if (cursor == SystemMouseCursors.forbidden) {
      cssValue = 'not-allowed';
    }
    
    container.style.cursor = cssValue;
  }

  @override
  Future<void> setRotation(double angleDegrees, int mapId) {
    final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
    
    if (_isSceneViewActive[mapId]!) {
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
    
    return Future.value();
  }

  @override
  Future<void> setUseCourseSymbolOnMovement(int mapId, bool useCourseSymbol) async {
    // Web implementation - course symbols mainly for mobile GPS
    print('Course symbol not supported on web: $useCourseSymbol');
  }

  @override
  void setWanderExtentFactor(double factor, int mapId) {
    // Web implementation - this is mainly for mobile GPS tracking
    print('setWanderExtentFactor not applicable for web: $factor');
  }

  @override
  Future<void> startLocationDisplayDataSource(int mapId) async {
    // Web implementation - would need geolocation API integration
    print('Location data source not implemented for web');
  }

  @override
  Future<void> stopLocationDisplayDataSource(int mapId) async {
    // Web implementation - would need geolocation API integration
    print('Location data source not implemented for web');
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
  Future<void> toggleBaseMap(int mapId, BaseMap baseMap) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final basemapId = baseMap.value;
      
      // Change basemap using JavaScript
      final changeBasemapJS = '''
        (function(map, basemapId) {
          map.basemap = basemapId;
        })
      ''';
      
      final changeFn = jsEval(changeBasemapJS.toJS) as JSFunction;
      changeFn.callAsFunction(null, view.map, basemapId.toJS);
      
      print('Basemap changed to: $basemapId');
    } catch (e) {
      print('Error changing basemap: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateFeatureLayer(
      {required int mapId,
      required String featureLayerId,
      required List<Graphic> data}) async {
    // Web implementation - would require feature layer data update
    print('FeatureLayer update not fully implemented - use addGraphic/removeGraphic instead');
  }

  @override
  void updateGraphicSymbol(
      {required int mapId,
      required String layerId,
      required String graphicId,
      required Symbol symbol}) {
    // Web implementation - would require finding and updating specific graphic
    print('updateGraphicSymbol not fully implemented - use removeGraphic/addGraphic instead');
  }

  @override
  Future<void> updateIsAttributionTextVisible(
      int mapId, bool isAttributionTextVisible) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      
      // Update attribution visibility
      final updateAttributionJS = '''
        (function(view, visible) {
          if (view.ui && view.ui.components) {
            if (visible) {
              if (!view.ui.components.includes('attribution')) {
                view.ui.add('attribution', 'bottom-right');
              }
            } else {
              view.ui.remove('attribution');
            }
          }
        })
      ''';
      
      final updateFn = jsEval(updateAttributionJS.toJS) as JSFunction;
      updateFn.callAsFunction(null, view, isAttributionTextVisible.toJS);
    } catch (e) {
      print('Error updating attribution visibility: $e');
    }
  }

  @override
  Future<void> updateLocationDisplaySourcePositionManually(
      int mapId, UserPosition position) async {
    // Web implementation - would need to update location marker manually
    print('Manual location update not implemented for web');
  }

  @override
  Stream<List<String>> visibleGraphics(int mapId) {
    // Web implementation - would require complex visibility tracking
    final controller = StreamController<List<String>>.broadcast();
    controller.add([]);
    return controller.stream;
  }

  @override
  Future<bool> zoomIn(
      {required int lodFactor,
      required int mapId,
      AnimationOptions? animationOptions}) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final currentZoom = view.zoom;
      final newZoom = currentZoom + lodFactor;
      
      final options = animationOptions != null 
          ? animationOptions.toMap().jsify() as JSObject
          : null;
      
      final target = {'zoom': newZoom}.jsify() as JSObject;
      
      await view.goTo(target, options).toDart;
      return true;
    } catch (e) {
      print('Error zooming in: $e');
      return false;
    }
  }

  @override
  Future<bool> zoomOut(
      {required int lodFactor,
      required int mapId,
      AnimationOptions? animationOptions}) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final currentZoom = view.zoom;
      final newZoom = currentZoom - lodFactor;
      
      final options = animationOptions != null 
          ? animationOptions.toMap().jsify() as JSObject
          : null;
      
      final target = {'zoom': newZoom}.jsify() as JSObject;
      
      await view.goTo(target, options).toDart;
      return true;
    } catch (e) {
      print('Error zooming out: $e');
      return false;
    }
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
