import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:async/async.dart';

class WebStreamManager {
  WebStreamManager({required this.mapId});

  final int mapId;

  // StreamGroup management like the old implementation
  final StreamGroup<double> _zoomStreamGroup = StreamGroup.broadcast();
  final StreamGroup<LatLng> _centerPositionStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<BoundingBox> _boundsStreamGroup = StreamGroup.broadcast();
  final StreamGroup<String> _attributionTextStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<Attributes?> _onClickStreamGroup = StreamGroup.broadcast();
  final StreamGroup<List<String>> _visibleGraphicsStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<bool> _graphicHoveredStreamGroup = StreamGroup.broadcast();

  // Event handles for cleanup
  final List<JsHandle> _eventHandles = [];

  // Stream controllers for direct control
  final StreamController<bool> _graphicHoveredController =
      StreamController.broadcast();

  // Track which streams have been initialized for each view
  final Set<String> _initializedStreams = {};

  Future<void> initialize() async {
    print('WebStreamManager initialized for mapId: $mapId');
  }

  // Zoom Stream Management
  Stream<double> getZoom(JsView view) {
    final streamKey = 'zoom_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupZoomStream(view);
      _initializedStreams.add(streamKey);
    }

    return _zoomStreamGroup.stream;
  }

  void _setupZoomStream(JsView view) {
    final controller = StreamController<double>.broadcast();

    // Initial value
    controller.add(view.zoom);

    // watch() is for property changes; on() is only for events like 'click'
    final handler = (JSAny? newValue, JSAny? oldValue, JSAny? propertyName,
            JSAny? target) {
      controller.add(view.zoom);
    }.toJS as JSFunction;

    final handle = view.watch('zoom', handler);
    _eventHandles.add(handle);

    _zoomStreamGroup.add(controller.stream);
  }

  // Center Position Stream Management
  Stream<LatLng> centerPosition(JsView view) {
    final streamKey = 'center_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupCenterStream(view);
      _initializedStreams.add(streamKey);
    }

    return _centerPositionStreamGroup.stream;
  }

  void _setupCenterStream(JsView view) {
    final controller = StreamController<LatLng>.broadcast();

    // Initial value
    final center = view.center;
    controller.add(LatLng(center.latitude, center.longitude));

    // watch() is for property changes; on() is only for events like 'click'
    final handler = (JSAny? newValue, JSAny? oldValue, JSAny? propertyName,
            JSAny? target) {
      final newCenter = view.center;
      controller.add(LatLng(newCenter.latitude, newCenter.longitude));
    }.toJS as JSFunction;

    final handle = view.watch('center', handler);
    _eventHandles.add(handle);

    _centerPositionStreamGroup.add(controller.stream);
  }

  // Bounds Stream Management
  Stream<BoundingBox> getBounds(JsView view) {
    final streamKey = 'bounds_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupBoundsStream(view);
      _initializedStreams.add(streamKey);
    }

    return _boundsStreamGroup.stream;
  }

  void _setupBoundsStream(JsView view) {
    final controller = StreamController<BoundingBox>.broadcast();

    // Initial value
    final extent = view.extent;
    if (extent != null) {
      final initialBounds = _extentToBoundingBox(extent);
      controller.add(initialBounds);
    }

    // watch() is for property changes; on() is only for events like 'click'
    final handler = (JSAny? newValue, JSAny? oldValue, JSAny? propertyName,
            JSAny? target) {
      final newExtent = view.extent;
      if (newExtent != null) {
        final newBounds = _extentToBoundingBox(newExtent);
        controller.add(newBounds);
      }
    }.toJS as JSFunction;

    final handle = view.watch('extent', handler);
    _eventHandles.add(handle);

    _boundsStreamGroup.add(controller.stream);
  }

  BoundingBox _extentToBoundingBox(JsExtent extent) {
    final sr = extent.spatialReference;
    print('[BOUNDS DEBUG] xmin=${extent.xmin}, ymin=${extent.ymin}, '
        'xmax=${extent.xmax}, ymax=${extent.ymax}');
    print('[BOUNDS DEBUG] center lat=${extent.center.latitude}, '
        'lng=${extent.center.longitude}');
    print('[BOUNDS DEBUG] height=${extent.height}, width=${extent.width}');
    print('[BOUNDS DEBUG] spatialReference=${jsonStringify(sr)}');

    final topRightProps = <String, dynamic>{
      'x': extent.xmax,
      'y': extent.ymax,
    }.jsify() as JSObject;
    topRightProps['spatialReference'] = sr;
    final topRight = JsPoint(topRightProps);

    final lowerLeftProps = <String, dynamic>{
      'x': extent.xmin,
      'y': extent.ymin,
    }.jsify() as JSObject;
    lowerLeftProps['spatialReference'] = sr;
    final lowerLeft = JsPoint(lowerLeftProps);

    print('[BOUNDS DEBUG] topRight lat=${topRight.latitude}, '
        'lng=${topRight.longitude}');
    print('[BOUNDS DEBUG] lowerLeft lat=${lowerLeft.latitude}, '
        'lng=${lowerLeft.longitude}');

    return BoundingBox(
      height: extent.height,
      width: extent.width,
      topRight: LatLng(topRight.latitude, topRight.longitude),
      lowerLeft: LatLng(lowerLeft.latitude, lowerLeft.longitude),
    );
  }

  // Attribution Text Stream Management
  Stream<String> attributionText(JsView view) {
    final streamKey = 'attribution_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupAttributionStream(view);
      _initializedStreams.add(streamKey);
    }

    return _attributionTextStreamGroup.stream;
  }

  void _setupAttributionStream(JsView view) {
    final controller = StreamController<String>.broadcast();

    // Create attribution widget and get text
    final attribution = JsAttribution({'view': view}.jsify() as JSObject);

    // Initial value
    controller.add(attribution.attributionText);

    // For now, we'll just return the initial value as attribution doesn't change often
    // In a full implementation, you could watch for map layer changes

    _attributionTextStreamGroup.add(controller.stream);
  }

  // Click Listener Stream Management
  Stream<Attributes?> onClickListener(JsView view) {
    final streamKey = 'click_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupClickStream(view);
      _initializedStreams.add(streamKey);
    }

    return _onClickStreamGroup.stream;
  }

  void _setupClickStream(JsView view) {
    final controller = StreamController<Attributes?>.broadcast();

    // Set up click event handler
    final clickHandler = (JSObject event) {
      _handleClickEvent(event, controller, view);
    }.toJS as JSFunction;

    final handle = view.on(['click'.toJS].toJS, clickHandler);
    _eventHandles.add(handle);

    _onClickStreamGroup.add(controller.stream);
  }

  Future<void> _handleClickEvent(JSObject event,
      StreamController<Attributes?> controller, JsView view) async {
    try {
      // All view types have the same hitTest method
      final hitTestPromise = view.hitTest(event);

      final hitTestResult = await hitTestPromise.toDart;
      final results = hitTestResult.results;

      if (results != null && results.toDart.isNotEmpty) {
        final firstResult = results.toDart[0];
        final graphic = firstResult.graphic;

        if (graphic != null) {
          // final attributes = graphic.attributes as JsAttributes?;
          // if (attributes != null) {
          //   // Convert JSObject attributes to Dart Attributes
          //   // This is a simplified conversion
          //   final dartAttributes = Attributes({
          //     'id': attributes.id ?? '',
          //     // Add other attribute conversions as needed
          //   });
          //   controller.add(dartAttributes);
          //   return;
          // }
        }
      }

      // No hit or no attributes
      controller.add(null);
    } catch (e) {
      print('Error in click handler: $e');
      controller.add(null);
    }
  }

  // Visible Graphics Stream Management
  Stream<List<String>> visibleGraphics(JsView view) {
    final streamKey = 'visible_graphics_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupVisibleGraphicsStream(view);
      _initializedStreams.add(streamKey);
    }

    return _visibleGraphicsStreamGroup.stream;
  }

  void _setupVisibleGraphicsStream(JsView view) {
    final controller = StreamController<List<String>>.broadcast();

    // This would require complex visibility calculations
    // For now, return empty list as placeholder
    controller.add([]);

    // In a full implementation, you could watch for extent changes
    // and calculate which graphics are visible

    _visibleGraphicsStreamGroup.add(controller.stream);
  }

  // Graphic Hovered Stream Management
  Stream<bool> isGraphicHoveredStream(JsView view) {
    final streamKey = 'hover_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupHoverStream(view);
      _initializedStreams.add(streamKey);
    }

    return _graphicHoveredStreamGroup.stream;
  }

  void _setupHoverStream(JsView view) {
    final controller = StreamController<bool>.broadcast();

    // Set up mouse move handler for hover detection
    final moveHandler = (JSObject event) {
      _handleHoverEvent(event, controller, view);
    }.toJS as JSFunction;

    final handle = view.on(['pointer-move'.toJS].toJS, moveHandler);
    _eventHandles.add(handle);

    _graphicHoveredStreamGroup.add(controller.stream);
  }

  Future<void> _handleHoverEvent(
      JSObject event, StreamController<bool> controller, JsView view) async {
    try {
      // All view types have the same hitTest method
      final hitTestPromise = view.hitTest(event);

      final hitTestResult = await hitTestPromise.toDart;
      final results = hitTestResult.results;

      final hasGraphic = results != null &&
          results.toDart.isNotEmpty &&
          results.toDart[0].graphic != null;

      controller.add(hasGraphic);
    } catch (e) {
      controller.add(false);
    }
  }

  // View Switch Management
  void switchView(JsView newView) {
    // When switching views (2D/3D), we need to recreate streams for the new view
    // Clear current stream initialization tracking
    _initializedStreams.clear();

    // Clean up old event handlers
    for (final handle in _eventHandles) {
      handle.remove();
    }
    _eventHandles.clear();

    print('Stream manager switched to new view');
  }

  // Stream Refresh Methods (for compatibility with old architecture)
  void refreshZoomStreams(JsView view) {
    _setupZoomStream(view);
  }

  void refreshCenterPositionStreams(JsView view) {
    _setupCenterStream(view);
  }

  void refreshBoundsStreams(JsView view) {
    _setupBoundsStream(view);
  }

  void refreshAttributionStreams(JsView view) {
    _setupAttributionStream(view);
  }

  void refreshOnClickStreams(JsView view) {
    _setupClickStream(view);
  }

  void refreshVisibleGraphicsStreams(JsView view) {
    _setupVisibleGraphicsStream(view);
  }

  // Dispose and cleanup
  void dispose() {
    // Close all stream groups
    _zoomStreamGroup.close();
    _centerPositionStreamGroup.close();
    _boundsStreamGroup.close();
    _attributionTextStreamGroup.close();
    _onClickStreamGroup.close();
    _visibleGraphicsStreamGroup.close();
    _graphicHoveredStreamGroup.close();

    // Close direct controllers
    _graphicHoveredController.close();

    // Remove all event handlers
    for (final handle in _eventHandles) {
      handle.remove();
    }
    _eventHandles.clear();

    // Clear tracking
    _initializedStreams.clear();

    print('WebStreamManager disposed for mapId: $mapId');
  }
}
