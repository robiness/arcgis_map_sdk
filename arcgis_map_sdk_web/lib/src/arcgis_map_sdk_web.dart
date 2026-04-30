import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/assets.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:arcgis_map_sdk_web/src/arcgis_map_web_controller.dart';
import 'package:arcgis_map_sdk_web/src/model_extension.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

class ArcgisMapWeb extends ArcgisMapPlatform {
  // New architecture - use web controllers instead of direct management
  static final Map<int, ArcgisMapWebController> _controllers = {};

  // Keep view tracking for backwards compatibility
  static final Map<int, JsMapView> _mapViews = {};
  static final Map<int, JsSceneView> _sceneViews = {};
  static final Map<int, bool> _isSceneViewActive = {};
  static final Map<int, Future Function(MethodCall)> _methodCallHandlers = {};
  static final Map<int, StreamController<Attributes?>> _clickControllers = {};

  // Store mapOptions for each map instance
  static final Map<int, ArcgisMapOptions> _mapOptions = {};

  // Store the shared map so we can create the lazy view later
  static final Map<int, JsEsriMap> _sharedMaps = {};

  static bool _scriptsInjected = false;
  static const _arcgisVersion = '4.33';
  static final Set<String> _registeredViewTypes = {};

  /// Registers this class as the default instance of [ArcgisMapPlatform].
  static void registerWith(Registrar registrar) {
    ArcgisMapPlatform.instance = ArcgisMapWeb();
    _injectOutlineOverrideCss();
  }

  /// Injects the override stylesheet that hides the blue focus outline the
  /// ArcGIS JS API draws around the map view surface on interaction.
  static void _injectOutlineOverrideCss() {
    final link = web.document.createElement('link') as web.HTMLLinkElement;
    link.rel = 'stylesheet';
    link.type = 'text/css';
    link.href = 'assets/packages/arcgis_map_sdk_web/'
        '${Assets.assets_css_overrides_override_outline_css}';
    web.document.head?.appendChild(link);
  }

  @override
  Future<FeatureLayer> addFeatureLayer(FeatureLayerOptions options, List<Graphic>? data,
      void Function(dynamic p1)? onPressed, String? url, int mapId, void Function(double p1)? getZoom, String layerId) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    return controller.addFeatureLayer(
      layerId: layerId,
      options: options,
      data: data,
      onPressed: onPressed,
      url: url,
      getZoom: getZoom,
    );
  }

  @override
  Future<void> addGraphic(int mapId, String layerId, Graphic graphic) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    return controller.addGraphic(
      layerId: layerId,
      graphic: graphic,
    );
  }

  @override
  Future<GraphicsLayer> addGraphicsLayer(
      GraphicsLayerOptions options, int mapId, String layerId, void Function(dynamic p1)? onPressed) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    return controller.addGraphicsLayer(
      layerId: layerId,
      options: options,
      onPressed: onPressed,
    );
  }

  @override
  Future<SceneLayer> addSceneLayer({
    required SceneLayerOptions options,
    required String layerId,
    required String url,
    required int mapId,
  }) async {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    // SceneLayer should preferably be added to 3D SceneView
    try {
      return await controller.addSceneLayer(layerId: layerId, url: url, options: options);
    } catch (e, stack) {
      developer.log('Error creating SceneLayer', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      // Still return the layer object even if there was an error
      // The error might be logged by ArcGIS but not necessarily fatal
      return SceneLayer(
        id: layerId,
      );
    }
  }

  @override
  void addViewPadding(int mapId, ViewPadding padding) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }
    try {
      controller.addViewPadding(padding: padding);
    } catch (e, stack) {
      developer.log('Error setting view padding', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
    }
  }

  @override
  Stream<String> attributionText(int mapId) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }
    return controller.attributionText();
  }

  @override
  Widget buildView(
      {required int creationId,
      required PlatformViewCreatedCallback onPlatformViewCreated,
      required ArcgisMapOptions mapOptions}) {

    // Store mapOptions for later use during initialization
    _mapOptions[creationId] = mapOptions;

    final viewType = 'arcgis-map-$creationId';

    // Register the HTML element factory only once
    if (!_registeredViewTypes.contains(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final mapDiv = web.document.createElement('div') as web.HTMLDivElement;
        mapDiv.id = 'map-$viewId';
        mapDiv.style.width = '100%';
        mapDiv.style.height = '100%';
        return mapDiv;
      });
      _registeredViewTypes.add(viewType);
    } else {
    }

    return HtmlElementView(
      viewType: viewType,
      onPlatformViewCreated: (int id) {
        // The platform view id can differ from creationId.
        // Remap mapOptions so init(id) finds them under the correct key.
        if (id != creationId && _mapOptions.containsKey(creationId)) {
          _mapOptions[id] = _mapOptions[creationId]!;
          _mapOptions.remove(creationId);
        }
        onPlatformViewCreated(id);
      },
    );
  }

  @override
  Stream<LatLng> centerPosition(int mapId) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }
    return controller.centerPosition();
  }

  @override
  bool destroyLayer({required int mapId, required String layerId}) {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

      // Find and remove the layer
      final layer = view.map.findLayerById(layerId) as JsLayer?;
      if (layer != null) {
        view.map.remove(layer);
        layer.destroy();
        return true;
      }
      return false;
    } catch (e, stack) {
      developer.log('Error destroying layer', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      return false;
    }
  }

  @override
  void dispose({required int mapId}) {
    try {
      // Dispose the web controller - this handles all cleanup
      final controller = _controllers[mapId];
      if (controller != null) {
        controller.dispose();
        _controllers.remove(mapId);
      }

      // Clean up backwards compatibility resources
      final mapView = _mapViews[mapId];
      final sceneView = _sceneViews[mapId];

      if (mapView != null) {
        // Enhanced views have better cleanup methods
        // but for safety, we can still call destroy if available
      }

      if (sceneView != null) {
        // Enhanced views have better cleanup methods
      }

      // Clean up legacy controllers
      _clickControllers[mapId]?.close();

      // Remove from maps
      _mapViews.remove(mapId);
      _sceneViews.remove(mapId);
      _sharedMaps.remove(mapId);
      _isSceneViewActive.remove(mapId);
      _methodCallHandlers.remove(mapId);
      _clickControllers.remove(mapId);
      _mapOptions.remove(mapId);

    } catch (e, stack) {
      developer.log('Error disposing map', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
    }
  }

  @override
  Future<Uint8List> exportImage(int mapId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

      // Use takeScreenshot method directly from enhanced view types
      JSPromise<JSObject> screenshotPromise;
      if (_isSceneViewActive[mapId]!) {
        final enhancedView = view as JsSceneView;
        screenshotPromise = enhancedView.takeScreenshot();
      } else {
        final enhancedView = view as JsMapView;
        screenshotPromise = enhancedView.takeScreenshot();
      }

      final screenshotResult = await screenshotPromise.toDart;
      final dataUrl = screenshotResult['dataUrl']! as JSString;
      final base64Data = dataUrl.toDart.split(',')[1]; // Remove data:image/png;base64,

      return base64Decode(base64Data);
    } catch (e, stack) {
      developer.log('Error exporting image', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }
    return controller.getBounds();
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
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    return controller.getZoom();
  }

  @override
  Future<void> init(int mapId) async {
    try {

      // Get the stored mapOptions for this mapId
      final mapOptions = _mapOptions[mapId];
      if (mapOptions == null) {
        throw Exception('MapOptions not found for mapId: $mapId. Make sure buildView was called first.');
      }

      // Wait for ArcGIS API to be loaded
      await _waitForArcGISAPI();

      // Configure global API key if provided
      if (mapOptions.apiKey != null && mapOptions.apiKey!.isNotEmpty) {
        try {
          // Set the global API key in esriConfig
          esriConfig['apiKey'] = mapOptions.apiKey!.toJS;
        } catch (e, stack) {
          developer.log('Failed to set global API key', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 900);
        }
      }

      // Create and initialize the new web controller
      final controller = await ArcgisMapWebController.init(mapId);
      _controllers[mapId] = controller;

      // Create a single shared map using mapOptions
      final basemapValue = mapOptions.basemap?.value ?? 'osm/light-gray';
      final groundValue = mapOptions.ground?.value;

      final mapProperties = <String, dynamic>{
        'basemap': basemapValue,
        if (groundValue != null) 'ground': groundValue,
      };
      final sharedMap = JsEsriMap(mapProperties.jsify()! as JSObject);

      // Wait for the container div to be created by Flutter
      web.Element? container;

      // Wait up to 5 seconds for container to appear
      for (int i = 0; i < 50; i++) {
        container = web.document.getElementById('map-$mapId');
        if (container != null) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (container == null) {
        throw Exception('Map container not found for id: map-$mapId after waiting');
      }

      final startIn3D = mapOptions.mapStyle == MapStyle.threeD;

      // Store the shared map for lazy view creation during switchMapStyle
      _sharedMaps[mapId] = sharedMap;

      // Only create the view we actually need. The other view is created
      // lazily in switchMapStyle(). Creating both upfront causes the
      // inactive view to fail on 3D-only basemap sublayers.
      if (startIn3D) {
        final sceneViewProperties = <String, dynamic>{
          'container': container,
          'map': sharedMap,
          'zoom': mapOptions.zoom,
          'center': [mapOptions.initialCenter.longitude, mapOptions.initialCenter.latitude],
        };
        final sceneView = JsSceneView(sceneViewProperties.jsify()! as JSObject);

        _applyPadding(mapOptions, sceneView);
        _applyDefaultUi(mapOptions, sceneView);
        _sceneViews[mapId] = sceneView;
        _isSceneViewActive[mapId] = true;

        controller.sceneView = sceneView;
        controller.switchMapStyle(MapStyle.threeD);
        _setupClickListener(mapId, sceneView);
      } else {
        final mapViewProperties = <String, dynamic>{
          'container': container,
          'map': sharedMap,
          'zoom': mapOptions.zoom,
          'center': [mapOptions.initialCenter.longitude, mapOptions.initialCenter.latitude],
          if (mapOptions.minZoom > 0 || mapOptions.maxZoom > 0)
            'constraints': <String, dynamic>{
              if (mapOptions.minZoom > 0) 'minZoom': mapOptions.minZoom,
              if (mapOptions.maxZoom > 0) 'maxZoom': mapOptions.maxZoom,
            },
          if (mapOptions.heading != 0) 'rotation': -mapOptions.heading,
        };
        final mapView = JsMapView(mapViewProperties.jsify()! as JSObject);

        _applyPadding(mapOptions, mapView);
        _applyDefaultUi(mapOptions, mapView);
        _mapViews[mapId] = mapView;
        _isSceneViewActive[mapId] = false;

        controller.mapView = mapView;
        _setupClickListener(mapId, mapView);
      }

      if (mapOptions.showLabelsBeneathGraphics) {
        await _moveReferenceLayersBeneathGraphics(sharedMap);
      }

    } catch (e, stack) {
      developer.log('Error initializing map', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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

    final cssLink = web.document.createElement('link') as web.HTMLLinkElement;
    cssLink.rel = 'stylesheet';
    cssLink.href = 'https://js.arcgis.com/$_arcgisVersion/esri/themes/light/main.css';
    web.document.head?.appendChild(cssLink);

    // Load the official ArcGIS CDN loader as a classic external script. This
    // exposes `window.$arcgis` (since 4.32) with a Promise-based `import()`
    // that resolves modules from the optimized CDN bundle. Using an external
    // `<script src=…>` keeps the page within strict CSP — no inline JS, no
    // hash maintenance.
    //
    // For v4.x the loader must be a classic script (no `type=module`) — its
    // internal `init.js` reads `document.currentScript.src`, which is `null`
    // inside module scripts per HTML spec.
    //
    // @see https://developers.arcgis.com/javascript/latest/get-started-cdn/
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src = 'https://js.arcgis.com/$_arcgisVersion/';
    web.document.head?.appendChild(script);

    while (arcgisLoader == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    const modulePaths = <String>[
      '@arcgis/core/Map.js',
      '@arcgis/core/views/MapView.js',
      '@arcgis/core/views/SceneView.js',
      '@arcgis/core/widgets/Attribution.js',
      '@arcgis/core/layers/SceneLayer.js',
      '@arcgis/core/layers/GraphicsLayer.js',
      '@arcgis/core/layers/FeatureLayer.js',
      '@arcgis/core/Graphic.js',
      '@arcgis/core/geometry/Point.js',
      '@arcgis/core/config.js',
      '@arcgis/core/core/reactiveUtils.js',
    ];
    final result = await arcgisLoader!.importModules(modulePaths.map((p) => p.toJS).toList().toJS).toDart;
    final modules = result.toDart;

    final esri = JSObject();
    final views = JSObject();
    final widgets = JSObject();
    final layers = JSObject();
    final geometry = JSObject();
    esri['Map'] = modules[0];
    views['MapView'] = modules[1];
    views['SceneView'] = modules[2];
    widgets['Attribution'] = modules[3];
    layers['SceneLayer'] = modules[4];
    layers['GraphicsLayer'] = modules[5];
    layers['FeatureLayer'] = modules[6];
    geometry['Point'] = modules[8];
    esri['views'] = views;
    esri['widgets'] = widgets;
    esri['layers'] = layers;
    esri['geometry'] = geometry;
    esri['Graphic'] = modules[7];
    esri['config'] = modules[9];

    window['esri'] = esri;
    window['SceneLayer'] = modules[4];
    window['GraphicsLayer'] = modules[5];
    window['FeatureLayer'] = modules[6];
    window['Graphic'] = modules[7];
    window['esriConfig'] = modules[9];
    window['reactiveUtils'] = modules[10];
    window['_arcgisModulesReady'] = true.toJS;

  }

  bool _isArcGISAPILoaded() {
    try {
      // Check if our AMD modules are loaded and ready using direct property access
      final isLoaded = arcgisModulesReady.dartify() == true;
      return isLoaded;
    } catch (e, stack) {
      developer.log('Error checking ArcGIS API', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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

      final jsTarget = target.jsify()! as JSObject;

      final options = animationOptions != null ? animationOptions.toMap().jsify()! as JSObject : null;

      await view.goTo(jsTarget, options).toDart;
    } catch (e, stack) {
      developer.log('Error moving camera', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> moveCameraToPoints({required List<LatLng> points, required int mapId, double? padding}) async {
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

      final target = extentData.jsify()! as JSObject;

      final options = padding != null ? {'padding': padding}.jsify()! as JSObject : null;

      await view.goTo(target, options).toDart;
    } catch (e, stack) {
      developer.log('Error moving camera to points', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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
  bool polygonContainsPoint({required String polygonId, required LatLng pointCoordinates, required int mapId}) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    return controller.polygonContainsPoint(
      polygonId: polygonId,
      pointCoordinates: pointCoordinates,
    );
  }

  @override
  Future<void> removeGraphic(int mapId, String layerId, String graphicId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

      // Find the graphics layer
      final layer = view.map.findLayerById(layerId) as JsGraphicsLayer?;
      if (layer == null) {
        throw Exception('Graphics layer with id $layerId not found');
      }

      // Find and remove the graphic using direct API calls
      final items = layer.graphics['items'] as JSArray?;
      if (items != null) {
        for (int i = 0; i < items.toDart.length; i++) {
          final graphic = items.toDart[i]! as JSObject;
          final attributes = graphic['attributes'] as JSObject?;
          if (attributes != null && attributes['id'] == graphicId.toJS) {
            layer.remove(graphic as JsGraphic);
            break;
          }
        }
      }
    } catch (e, stack) {
      developer.log('Error removing graphic', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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
        final layer = view.map.findLayerById(layerId) as JsGraphicsLayer?;
        if (layer == null) return;

        // Remove graphics using direct API calls with filtering logic
        final items = layer.graphics['items'] as JSArray?;
        if (items != null) {
          final graphicsToRemove = <JsGraphic>[];
          for (int i = 0; i < items.toDart.length; i++) {
            final graphic = items.toDart[i]! as JSObject;
            final attributes = graphic['attributes'] as JSObject?;
            if (attributes != null) {
              bool shouldRemove = true;

              // Check remove criteria
              if (removeByAttributeKey != null && removeByAttributeValue != null) {
                if (attributes[removeByAttributeKey] != removeByAttributeValue.toJS) {
                  shouldRemove = false;
                }
              }

              // Check exclude criteria
              if (excludeAttributeKey != null && excludeAttributeValues != null) {
                final attrValue = attributes[excludeAttributeKey];
                for (final excludeValue in excludeAttributeValues) {
                  if (attrValue == excludeValue.toJS) {
                    shouldRemove = false;
                    break;
                  }
                }
              }

              if (shouldRemove) {
                graphicsToRemove.add(graphic as JsGraphic);
              }
            }
          }

          // Remove all matching graphics
          for (final graphic in graphicsToRemove) {
            layer.remove(graphic);
          }
        }
      } else {
        // Remove from all graphics layers using direct API calls
        final layerItems = view.map.layers['items'] as JSArray?;

        if (layerItems != null) {
          for (int layerIndex = 0; layerIndex < layerItems.toDart.length; layerIndex++) {
            final layer = layerItems.toDart[layerIndex]! as JSObject;
            final layerType = layer['type'] as JSString?;

            if (layerType?.toDart == 'graphics') {
              final enhancedLayer = layer as JsGraphicsLayer;
              final items = enhancedLayer.graphics['items'] as JSArray?;
              if (items != null) {
                final graphicsToRemove = <JsGraphic>[];
                for (int i = 0; i < items.toDart.length; i++) {
                  final graphic = items.toDart[i]! as JSObject;
                  final attributes = graphic['attributes'] as JSObject?;
                  if (attributes != null) {
                    bool shouldRemove = true;

                    // Check remove criteria
                    if (removeByAttributeKey != null && removeByAttributeValue != null) {
                      if (attributes[removeByAttributeKey] != removeByAttributeValue.toJS) {
                        shouldRemove = false;
                      }
                    }

                    // Check exclude criteria
                    if (excludeAttributeKey != null && excludeAttributeValues != null) {
                      final attrValue = attributes[excludeAttributeKey];
                      for (final excludeValue in excludeAttributeValues) {
                        if (attrValue == excludeValue.toJS) {
                          shouldRemove = false;
                          break;
                        }
                      }
                    }

                    if (shouldRemove) {
                      graphicsToRemove.add(graphic as JsGraphic);
                    }
                  }
                }

                // Remove all matching graphics
                for (final graphic in graphicsToRemove) {
                  enhancedLayer.remove(graphic);
                }
              }
            }
          }
        }
      }
    } catch (e, stack) {
      developer.log('Error removing graphics', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
    }
  }

  @override
  Future<void> retryLoad(int mapId) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

      // Refresh/reload the map and its layers using direct API calls
      final layerItems = view.map.layers['items'] as JSArray?;

      if (layerItems != null) {
        for (int i = 0; i < layerItems.toDart.length; i++) {
          final layer = layerItems.toDart[i]! as JSObject;
          // Try to call refresh or load methods if available
          final refreshMethod = layer['refresh'] as JSFunction?;
          final loadMethod = layer['load'] as JSFunction?;

          try {
            if (refreshMethod != null) {
              refreshMethod.callAsFunction(layer);
            } else if (loadMethod != null) {
              loadMethod.callAsFunction(layer);
            }
          } catch (e) {
            // Ignore errors from individual layer refresh/load attempts
          }
        }
      }

      // Also refresh the view itself if possible
      final viewRefreshMethod = (view as JSObject)['refresh'] as JSFunction?;
      try {
        if (viewRefreshMethod != null) {
          viewRefreshMethod.callAsFunction(view);
        }
      } catch (e) {
        // Ignore view refresh errors
      }

    } catch (e, stack) {
      developer.log('Error retrying load', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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

    // Set navigation interaction using direct property access
    if (_isSceneViewActive[mapId]!) {
      final enhancedView = view as JsSceneView;
      (enhancedView.navigation as dynamic).enabled = isEnabled;
    } else {
      final enhancedView = view as JsMapView;
      (enhancedView.navigation as dynamic).enabled = isEnabled;
    }

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
  Future<void> setMethodCallHandler({required int mapId, required Future Function(MethodCall p1) onCall}) {
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

      final isCurrentlySceneView = _isSceneViewActive[mapId] ?? false;
      final shouldUse3D = mapStyle == MapStyle.threeD;

      if (shouldUse3D == isCurrentlySceneView) {
        return;
      }

      final container = web.document.getElementById('map-$mapId');
      final sharedMap = _sharedMaps[mapId];
      final mapOptions = _mapOptions[mapId];
      if (container == null || sharedMap == null) {
        developer.log('Container or shared map not found for mapId: $mapId', name: 'arcgis_map_sdk_web', level: 900);
        return;
      }

      if (shouldUse3D) {
        // MapView.zoom and SceneView.zoom aren't directly comparable
        // (tile-LOD vs camera altitude). viewpoint carries scale +
        // rotation through ArcGIS' projection-aware conversion.
        final mapView = _mapViews[mapId]!;
        final viewpoint = mapView.viewpoint;
        mapView.container = null;

        var sceneView = _sceneViews[mapId];
        if (sceneView == null) {
          sceneView = JsSceneView(<String, dynamic>{
            'container': container,
            'map': sharedMap,
            'viewpoint': viewpoint,
          }.jsify()! as JSObject);

          _applyPadding(mapOptions, sceneView);
          _applyDefaultUi(mapOptions, sceneView);
          _sceneViews[mapId] = sceneView;
          _controllers[mapId]?.sceneView = sceneView;
          _setupClickListener(mapId, sceneView);
        } else {
          sceneView.container = container;
          // Matches Esri's "Switch view 2D to 3D" sample.
          sceneView.viewpoint = viewpoint;
        }

        _isSceneViewActive[mapId] = true;
        _controllers[mapId]?.attachDeferredSceneLayers(sharedMap);
      } else {
        final sceneView = _sceneViews[mapId]!;
        final viewpoint = sceneView.viewpoint;
        _controllers[mapId]?.detachSceneLayersFromMap(sharedMap);
        sceneView.container = null;

        var mapView = _mapViews[mapId];
        if (mapView == null) {
          mapView = JsMapView(<String, dynamic>{
            'container': container,
            'map': sharedMap,
            'viewpoint': viewpoint,
            if (mapOptions != null && (mapOptions.minZoom > 0 || mapOptions.maxZoom > 0))
              'constraints': <String, dynamic>{
                if (mapOptions.minZoom > 0) 'minZoom': mapOptions.minZoom,
                if (mapOptions.maxZoom > 0) 'maxZoom': mapOptions.maxZoom,
              },
          }.jsify()! as JSObject);

          _applyPadding(mapOptions, mapView);
          _applyDefaultUi(mapOptions, mapView);
          _mapViews[mapId] = mapView;
          _controllers[mapId]?.mapView = mapView;
          _setupClickListener(mapId, mapView);
        } else {
          mapView.container = container;
          mapView.viewpoint = viewpoint;
        }

        _isSceneViewActive[mapId] = false;
      }

      // Defer stream re-attach until the view is ready. On lazy-create,
      // view.extent/scale are populated asynchronously; eager reads in
      // _streamManager.switchView() would otherwise throw and leave the
      // bounds stream attached to the detached old view.
      final controller = _controllers[mapId];
      final activeView = shouldUse3D ? _sceneViews[mapId] : _mapViews[mapId];
      if (controller != null && activeView != null) {
        reactiveUtils.whenOnce((() => activeView.ready.toJS).toJS).toDart.then((_) {
          controller.switchMapStyle(mapStyle);
        }).catchError((Object e) {
          print('Error during deferred view switch: $e');
        });
      }
    } catch (e, stack) {
      developer.log('Error switching map style', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
    }
  }

  @override
  Future<void> toggleBaseMap(int mapId, BaseMap baseMap) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final basemapId = baseMap.value;

      view.map.basemap = basemapId.toJS;

    } catch (e, stack) {
      developer.log('Error changing basemap', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      rethrow;
    }
  }

  @override
  Future<void> updateFeatureLayer(
      {required int mapId, required String featureLayerId, required List<Graphic> data}) async {
    // Web implementation - would require feature layer data update
  }

  @override
  void updateGraphicSymbol(
      {required int mapId, required String layerId, required String graphicId, required Symbol symbol}) {
    final controller = _controllers[mapId];
    if (controller == null) {
      throw Exception('Map controller not found for mapId: $mapId');
    }

    controller.updateGraphicSymbol(
      layerId: layerId,
      graphicId: graphicId,
      symbol: symbol,
    );
  }

  @override
  Future<void> updateIsAttributionTextVisible(int mapId, bool isAttributionTextVisible) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;

      // Update attribution visibility using direct UI API access
      if (_isSceneViewActive[mapId]!) {
        final enhancedView = view as JsSceneView;
        final ui = enhancedView.ui;
        if (isAttributionTextVisible) {
          ui.add('attribution'.toJS, 'bottom-right'.toJS);
        } else {
          ui.remove('attribution'.toJS);
        }
      } else {
        final enhancedView = view as JsMapView;
        final ui = enhancedView.ui;
        if (isAttributionTextVisible) {
          ui.add('attribution'.toJS, 'bottom-right'.toJS);
        } else {
          ui.remove('attribution'.toJS);
        }
      }
    } catch (e, stack) {
      developer.log('Error updating attribution visibility', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
    }
  }

  @override
  Future<void> updateLocationDisplaySourcePositionManually(int mapId, UserPosition position) async {
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
  Future<bool> zoomIn({required int lodFactor, required int mapId, AnimationOptions? animationOptions}) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final currentZoom = view.zoom;
      final newZoom = currentZoom + lodFactor;

      final options = animationOptions != null ? animationOptions.toMap().jsify()! as JSObject : null;

      final target = {'zoom': newZoom}.jsify()! as JSObject;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e, stack) {
      developer.log('Error zooming in', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      return false;
    }
  }

  @override
  Future<bool> zoomOut({required int lodFactor, required int mapId, AnimationOptions? animationOptions}) async {
    try {
      final view = _isSceneViewActive[mapId]! ? _sceneViews[mapId]! : _mapViews[mapId]!;
      final currentZoom = view.zoom;
      final newZoom = currentZoom - lodFactor;

      final options = animationOptions != null ? animationOptions.toMap().jsify()! as JSObject : null;

      final target = {'zoom': newZoom}.jsify()! as JSObject;

      await view.goTo(target, options).toDart;
      return true;
    } catch (e, stack) {
      developer.log('Error zooming out', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      return false;
    }
  }

  static void _setupClickListener(int mapId, JsView view) {
    final clickHandler = (JSObject event) {
      _handleClick(mapId, view, event);
    }.toJS as JSFunction;

    final eventArray = ['click'.toJS].toJS;
    view.on(eventArray, clickHandler);
  }

  static Future<void> _handleClick(int mapId, JsView view, JSObject event) async {
    final controller = _clickControllers[mapId];
    if (controller == null) return;

    try {
      final hitTestResult = await view.hitTest(event).toDart;
      final results = hitTestResult.results;

      if (results != null && results.toDart.isNotEmpty) {
        final graphic = results.toDart.first.graphic;
        if (graphic != null) {
          final jsAttributes = graphic['attributes'] as JSObject?;
          if (jsAttributes != null) {
            final dartMap = jsAttributes.dartify();
            if (dartMap is Map) {
              controller.add(Attributes(Map<String, dynamic>.from(dartMap)));
              return;
            }
          }
        }
      }

      controller.add(null);
    } catch (e, stack) {
      developer.log('Error in click handler', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
      controller.add(null);
    }
  }

  /// Applies padding from mapOptions to a view.
  static void _applyPadding(ArcgisMapOptions? mapOptions, JsView view) {
    if (mapOptions == null) return;
    final padding = mapOptions.padding;
    if (padding.left > 0 || padding.top > 0 || padding.right > 0 || padding.bottom > 0) {
      final jsPadding = <String, dynamic>{
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      }.jsify()! as JSObject;
      view.padding = jsPadding;
    }
  }

  /// Applies the caller-supplied [DefaultWidget] list to the view's default UI,
  /// replacing ArcGIS' built-in widget set.
  ///
  /// The list is authoritative: passing an empty list strips every default
  /// widget from the view, and only the widgets in the list are displayed.
  /// Each widget is then moved to its configured [WidgetPosition]. Widgets
  /// configured with [WidgetPosition.manual] keep their default slot — the
  /// consumer is expected to position them at the DOM level.
  ///
  /// Note: basemap attribution is required by the Esri (and transitive OSM /
  /// Community Maps) licences. If the caller omits [DefaultWidgetType.attribution]
  /// from the list, it is their responsibility to display the attribution text
  /// elsewhere in the app (e.g. via [ArcgisMapController.attributionText]).
  static void _applyDefaultUi(ArcgisMapOptions? mapOptions, JsView view) {
    if (mapOptions == null) return;
    final widgets = mapOptions.defaultUiList;
    final ui = view.ui;

    // Strip Esri's full default component set so the built-in widgets
    // (zoom, compass, navigation-toggle, attribution) never flash in their
    // default slots while the view is loading — most visible when a
    // SceneView is created lazily on a 2D → 3D switch.
    ui.components = <JSString>[].toJS;

    // Add each configured widget back once the view is ready. Passing the
    // widget name to DefaultUI.add() creates the underlying default widget
    // atomically at the given position — no components/move two-step, so
    // no intermediate slot and no timing race with reactive instantiation.
    reactiveUtils.whenOnce((() => view.ready.toJS).toJS).toDart.then((_) {
      for (final widget in widgets) {
        final position = widget.position == WidgetPosition.manual ? null : widget.position.value.toJS;
        ui.add(widget.viewType.value.toJS, position);
      }
    });
  }

  /// Moves basemap reference layers (labels) into the map's operational
  /// layers at index 0 so that graphics layers render on top of them.
  static Future<void> _moveReferenceLayersBeneathGraphics(JsEsriMap map) async {
    final basemap = map.basemap as JsBasemap;

    if (!basemap.loaded) {
      await basemap.load().toDart;
    }

    final refLayers = basemap.referenceLayers;
    final items = refLayers.toArray();
    if (items.toDart.isEmpty) {
      return;
    }

    map.addMany(items, 0);
    refLayers.removeAll();
  }
}
