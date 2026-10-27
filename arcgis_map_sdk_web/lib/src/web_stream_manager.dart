import 'dart:async';
import 'dart:developer' as developer;
import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:async/async.dart';

class WebStreamManager {
  WebStreamManager({required this.mapId});

  final int mapId;

  // StreamGroup management like the old implementation
  final StreamGroup<double> _zoomStreamGroup = StreamGroup.broadcast();
  final StreamGroup<double> _scaleStreamGroup = StreamGroup.broadcast();
  final StreamGroup<LatLng> _centerPositionStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<BoundingBox> _boundsStreamGroup = StreamGroup.broadcast();
  final StreamGroup<String> _attributionTextStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<Attributes?> _onClickStreamGroup = StreamGroup.broadcast();
  final StreamGroup<List<String>> _visibleGraphicsStreamGroup =
      StreamGroup.broadcast();
  final StreamGroup<bool> _graphicHoveredStreamGroup = StreamGroup.broadcast();
  final StreamGroup<Attributes?> _hoveredGraphicStreamGroup =
      StreamGroup.broadcast();

  // Event handles for cleanup
  final List<JsHandle> _eventHandles = [];

  // Stream controllers for direct control
  final StreamController<bool> _graphicHoveredController =
      StreamController.broadcast();

  // Track which streams have been initialized for each view
  final Set<String> _initializedStreams = {};

  Future<void> initialize() async {
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

    // Initial value (reactiveUtils.watch does not fire on initial state)
    controller.add(view.zoom);

    final getter = (() => view.zoom.toJS).toJS;
    final callback = (JSAny? newValue, JSAny? oldValue) {
      controller.add(view.zoom);
    }.toJS as JSFunction;

    final handle = reactiveUtils.watch(getter, callback);
    _eventHandles.add(handle);

    _zoomStreamGroup.add(controller.stream);
  }

  // Scale Stream Management
  Stream<double> getScale(JsView view) {
    final streamKey = 'scale_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupScaleStream(view);
      _initializedStreams.add(streamKey);
    }

    return _scaleStreamGroup.stream;
  }

  void _setupScaleStream(JsView view) {
    // The current scale goes out once the group listens: added any earlier,
    // a broadcast controller drops it, and reactiveUtils.watch only reports
    // changes. A view taken over on a switch between 2D and 3D reports its
    // scale at once too.
    late final StreamController<double> controller;
    controller = StreamController<double>.broadcast(
      onListen: () => controller.add(view.scale),
    );

    final getter = (() => view.scale.toJS).toJS;
    final callback = (JSAny? newValue, JSAny? oldValue) {
      controller.add(view.scale);
    }.toJS as JSFunction;

    final handle = reactiveUtils.watch(getter, callback);
    _eventHandles.add(handle);

    _scaleStreamGroup.add(controller.stream);
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

    // Initial value (reactiveUtils.watch does not fire on initial state)
    final center = view.center;
    controller.add(LatLng(center.latitude, center.longitude));

    final getter = (() => view.center).toJS;
    final callback = (JSAny? newValue, JSAny? oldValue) {
      final newCenter = view.center;
      controller.add(LatLng(newCenter.latitude, newCenter.longitude));
    }.toJS as JSFunction;

    final handle = reactiveUtils.watch(getter, callback);
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

    // Initial value (reactiveUtils.watch does not fire on initial state)
    final extent = view.extent;
    if (extent != null) {
      final initialBounds = _extentToBoundingBox(extent);
      controller.add(initialBounds);
    }

    final getter = (() => view.extent).toJS;
    final callback = (JSAny? newValue, JSAny? oldValue) {
      final newExtent = view.extent;
      if (newExtent != null) {
        final newBounds = _extentToBoundingBox(newExtent);
        controller.add(newBounds);
      }
    }.toJS as JSFunction;

    final handle = reactiveUtils.watch(getter, callback);
    _eventHandles.add(handle);

    _boundsStreamGroup.add(controller.stream);
  }

  BoundingBox _extentToBoundingBox(JsExtent extent) {
    final sr = extent.spatialReference;

    final topRightProps = <String, dynamic>{
      'x': extent.xmax,
      'y': extent.ymax,
    }.jsify()! as JSObject;
    topRightProps['spatialReference'] = sr;
    final topRight = JsPoint(topRightProps);

    final lowerLeftProps = <String, dynamic>{
      'x': extent.xmin,
      'y': extent.ymin,
    }.jsify()! as JSObject;
    lowerLeftProps['spatialReference'] = sr;
    final lowerLeft = JsPoint(lowerLeftProps);


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
    final attribution = JsAttribution({'view': view}.jsify()! as JSObject);
    final controller = StreamController<String>.broadcast();

    // Skip the empty initial read (layers may not be loaded yet) and rely on
    // the watcher to emit the first real value. Otherwise subscribers that
    // take the first event (e.g. `.take(1)`) would latch onto an empty string.
    final initial = attribution.attributionText;
    if (initial.isNotEmpty) controller.add(initial);

    final getter = (() => attribution.attributionText.toJS).toJS;
    final callback = (JSAny? newValue, JSAny? oldValue) {
      if (controller.isClosed) return;
      final text = attribution.attributionText;
      if (text.isNotEmpty) controller.add(text);
    }.toJS as JSFunction;

    final handle = reactiveUtils.watch(getter, callback);
    _eventHandles.add(handle);

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
    } catch (e, stack) {
      developer.log('Error in click handler', name: 'arcgis_map_sdk_web', error: e, stackTrace: stack, level: 1000);
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
    _ensureHoverStreams(view);
    return _graphicHoveredStreamGroup.stream;
  }

  Stream<Attributes?> hoveredGraphicStream(JsView view) {
    _ensureHoverStreams(view);
    return _hoveredGraphicStreamGroup.stream;
  }

  /// Both hover streams share one pointer-move handler, so a pointer move
  /// costs one hit test however many of them are listened to.
  void _ensureHoverStreams(JsView view) {
    final streamKey = 'hover_${view.hashCode}';

    if (!_initializedStreams.contains(streamKey)) {
      _setupHoverStream(view);
      _initializedStreams.add(streamKey);
    }
  }

  void _setupHoverStream(JsView view) {
    final hovered = StreamController<bool>.broadcast();
    final hoveredGraphic = StreamController<Attributes?>.broadcast();

    // Set up mouse move handler for hover detection
    final moveHandler = (JSObject event) {
      _handleHoverEvent(event, hovered, hoveredGraphic, view);
    }.toJS as JSFunction;

    final handle = view.on(['pointer-move'.toJS].toJS, moveHandler);
    _eventHandles.add(handle);

    _graphicHoveredStreamGroup.add(hovered.stream);
    _hoveredGraphicStreamGroup.add(hoveredGraphic.stream);
  }

  Future<void> _handleHoverEvent(
    JSObject event,
    StreamController<bool> hovered,
    StreamController<Attributes?> hoveredGraphic,
    JsView view,
  ) async {
    try {
      // All view types have the same hitTest method
      final hitTestPromise = view.hitTest(event);

      final hitTestResult = await hitTestPromise.toDart;
      final results = hitTestResult.results;

      // Only graphics the app added count: the basemap's vector tiles are
      // hit too, which would make the whole map look hoverable.
      final graphic = results?.toDart
          .where((result) => result.layer?.type == 'graphics')
          .firstOrNull
          ?.graphic;

      hovered.add(graphic != null);
      hoveredGraphic.add(_attributesOf(graphic));
    } catch (e) {
      hovered.add(false);
      hoveredGraphic.add(null);
    }
  }

  static Attributes? _attributesOf(JSObject? graphic) {
    final jsAttributes = graphic?['attributes'] as JSObject?;
    final data = jsAttributes.dartify();
    if (data is! Map) return null;
    return Attributes(Map<String, dynamic>.from(data));
  }

  // View Switch Management
  void switchView(JsView newView) {
    // Snapshot which stream types were active on the old view before we wipe
    // tracking state, so we can re-attach watchers on the new view. Without
    // this re-attach, switching 2D <-> 3D removes the old watchers but never
    // installs new ones, leaving zoom/center/bounds streams silent for the
    // rest of the session.
    final hadZoom = _initializedStreams.any((k) => k.startsWith('zoom_'));
    final hadScale = _initializedStreams.any((k) => k.startsWith('scale_'));
    final hadCenter = _initializedStreams.any((k) => k.startsWith('center_'));
    final hadBounds = _initializedStreams.any((k) => k.startsWith('bounds_'));
    final hadAttribution =
        _initializedStreams.any((k) => k.startsWith('attribution_'));
    final hadClick = _initializedStreams.any((k) => k.startsWith('click_'));
    final hadVisibleGraphics =
        _initializedStreams.any((k) => k.startsWith('visible_graphics_'));
    final hadHover = _initializedStreams.any((k) => k.startsWith('hover_'));

    _initializedStreams.clear();

    // Clean up old event handlers
    for (final handle in _eventHandles) {
      handle.remove();
    }
    _eventHandles.clear();

    // Re-attach previously active streams to the new view (going through the
    // public getters keeps the dedup tracking consistent).
    if (hadZoom) getZoom(newView);
    if (hadScale) getScale(newView);
    if (hadCenter) centerPosition(newView);
    if (hadBounds) getBounds(newView);
    if (hadAttribution) attributionText(newView);
    if (hadClick) onClickListener(newView);
    if (hadVisibleGraphics) visibleGraphics(newView);
    if (hadHover) isGraphicHoveredStream(newView);

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
    _scaleStreamGroup.close();
    _centerPositionStreamGroup.close();
    _boundsStreamGroup.close();
    _attributionTextStreamGroup.close();
    _onClickStreamGroup.close();
    _visibleGraphicsStreamGroup.close();
    _graphicHoveredStreamGroup.close();
    _hoveredGraphicStreamGroup.close();

    // Close direct controllers
    _graphicHoveredController.close();

    // Remove all event handlers
    for (final handle in _eventHandles) {
      handle.remove();
    }
    _eventHandles.clear();

    // Clear tracking
    _initializedStreams.clear();

  }
}
