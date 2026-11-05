/// Fakes of the ArcGIS objects the web plugin reads and changes.
///
/// Each fake is a Dart object with a JS face in its `js`. The face is created
/// once: `indexOf`, `remove` and `==` of the fakes' collections need the same
/// JS object every time.
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';
import 'package:flutter_test/flutter_test.dart';

@JSExport()
class FakeLayer {
  FakeLayer({required this.id, this.type = 'graphics'});

  final String id;
  final String type;
  bool visible = true;
  bool destroyed = false;
  int loadCount = 0;

  late final JsLayer js = _wrap();

  // What a wrapper exports follows the static type of the wrapped object, so
  // a subclass wraps itself.
  JsLayer _wrap() => createJSInteropWrapper(this) as JsLayer;

  JSPromise<JSObject> load() {
    loadCount++;
    return Future<JSObject>.value(js).toJS;
  }

  void destroy() {
    destroyed = true;
  }
}

/// A graphics layer that, like ArcGIS, sets the `layer` of each graphic it
/// takes and clears it when the graphic leaves.
@JSExport()
class FakeGraphicsLayer extends FakeLayer {
  FakeGraphicsLayer({required super.id});

  final List<JsGraphic> _graphics = [];

  late final FakeGraphicCollection _collection = FakeGraphicCollection(this);

  /// The name of every call that adds or removes graphics, in order.
  final List<String> calls = [];

  @override
  JsLayer _wrap() {
    return createJSInteropWrapper<FakeGraphicsLayer>(this) as JsLayer;
  }

  /// The `id` in the attributes of each graphic, in the layer's order.
  List<String?> get graphicIds => [
        for (final graphic in _graphics)
          (graphic.attributes?['id'] as JSString?)?.toDart,
      ];

  /// How often the graphics were gone through.
  int get toArrayCount => _collection.toArrayCount;

  JsCollection<JsGraphic> get graphics => _collection.js;

  void add(JsGraphic graphic) {
    calls.add('add');
    _take(graphic);
  }

  void addMany(JSArray<JsGraphic> graphics) {
    calls.add('addMany');
    graphics.toDart.forEach(_take);
  }

  JsGraphic? remove(JsGraphic graphic) {
    calls.add('remove');
    return _release(graphic);
  }

  JSArray<JsGraphic> removeMany(JSArray<JsGraphic> graphics) {
    calls.add('removeMany');
    return [
      for (final graphic in graphics.toDart)
        if (_release(graphic) case final removed?) removed,
    ].toJS;
  }

  void removeAll() {
    calls.add('removeAll');
    [..._graphics].forEach(_release);
  }

  /// Puts [graphic] into the layer as code would that reaches the layer
  /// directly.
  void addDirectly(JsGraphic graphic) => _take(graphic);

  /// Takes the graphic [id] out of the layer as code would that reaches the
  /// layer directly.
  void removeDirectly(String id) {
    _release(_graphics[graphicIds.indexOf(id)]);
  }

  void _take(JsGraphic graphic) {
    _graphics.add(graphic);
    graphic['layer'] = js;
  }

  JsGraphic? _release(JsGraphic graphic) {
    final index =
        _graphics.indexWhere((item) => item.strictEquals(graphic).toDart);
    if (index < 0) return null;
    graphic['layer'] = null;
    return _graphics.removeAt(index);
  }
}

/// The `graphics` of a [FakeGraphicsLayer].
@JSExport()
class FakeGraphicCollection {
  FakeGraphicCollection(this._layer);

  final FakeGraphicsLayer _layer;

  int toArrayCount = 0;

  late final JsCollection<JsGraphic> js =
      createJSInteropWrapper(this) as JsCollection<JsGraphic>;

  int get length => _layer._graphics.length;

  /// A copy, as ArcGIS returns.
  JSArray<JsGraphic> toArray() {
    toArrayCount++;
    return [..._layer._graphics].toJS;
  }
}

/// A vector tile layer that has the style layers [styleLayerIds].
///
/// Like a real one it refuses `setStyleLayerVisibility` until it has loaded.
/// [visibility] records every call, also for an id the layer lacks, which the
/// real layer ignores, so a test can see a call that should not have been made.
@JSExport()
class FakeVectorTileLayer extends FakeLayer {
  FakeVectorTileLayer({
    required super.id,
    required this.styleLayerIds,
    this.failsToLoad = false,
    this.properties,
  }) : super(type: 'vector-tile');

  final Set<String> styleLayerIds;
  final bool failsToLoad;

  /// What the layer was constructed with, dartified.
  final Object? properties;

  final Map<String, String> visibility = {};

  /// The styles `loadStyle` was given, dartified.
  final List<Object?> loadStyleCalls = [];

  Completer<void>? _held;
  ({JSAny? reason})? _rejection;
  bool _loaded = false;
  final List<String> _loadStyleFailures = [];

  @override
  JsLayer _wrap() {
    return createJSInteropWrapper<FakeVectorTileLayer>(this) as JsLayer;
  }

  /// Makes every following `load()` wait until the returned completer
  /// completes, or until [completeLoad], [failLoad] or [rejectLoad].
  Completer<void> holdLoad() => _held = Completer<void>();

  void completeLoad() => _held!.complete();

  /// Rejects the held loads, and every later one, as ArcGIS does: with an
  /// error object that has [name] and [message].
  void failLoad(String name, String message) {
    rejectLoad({'name': name, 'message': message}.jsify());
  }

  /// Rejects the held loads, and every later one, with [reason].
  void rejectLoad(JSAny? reason) {
    _rejection = (reason: reason);
    _held!.complete();
  }

  @override
  JSPromise<JSObject> load() {
    loadCount++;
    return JSPromise<JSObject>(
      (JSFunction resolve, JSFunction reject) {
        _settle().then((rejection) {
          if (rejection == null) {
            _loaded = true;
            resolve.callAsFunction(null, js);
          } else {
            reject.callAsFunction(null, rejection.reason);
          }
        });
      }.toJS,
    );
  }

  /// What the load rejects with, or null when it resolves.
  Future<({JSAny? reason})?> _settle() async {
    if (failsToLoad) {
      return (reason: JsError('$id failed to load'));
    }
    await _held?.future;
    return _rejection;
  }

  JSObject? getStyleLayer(String layerId) {
    return styleLayerIds.contains(layerId) ? JSObject() : null;
  }

  void setStyleLayerVisibility(String layerId, String visibility) {
    if (!_loaded) {
      throw StateError('$id is not loaded');
    }
    this.visibility[layerId] = visibility;
  }

  /// Makes the next `loadStyle` reject as ArcGIS does, with an error object
  /// named [name], such as `AbortError` for a swap a later one overtook. Each
  /// call fails one more `loadStyle`.
  void failNextLoadStyle(String name) => _loadStyleFailures.add(name);

  JSPromise<JSAny?> loadStyle(JSAny style) {
    loadStyleCalls.add(style.dartify());
    final failure =
        _loadStyleFailures.isEmpty ? null : _loadStyleFailures.removeAt(0);
    return JSPromise<JSAny?>(
      (JSFunction resolve, JSFunction reject) {
        if (failure == null) {
          resolve.callAsFunction(null, js);
        } else {
          reject.callAsFunction(
            null,
            {'name': failure, 'message': 'loadStyle failed'}.jsify(),
          );
        }
      }.toJS,
    );
  }
}

@JSExport()
class FakeCollection {
  FakeCollection(List<FakeLayer> items)
      : _items = [for (final item in items) item.js];

  final List<JsLayer> _items;

  late final JsCollection<JsLayer> js =
      createJSInteropWrapper(this) as JsCollection<JsLayer>;

  List<String> get layerIds => [for (final item in _items) item.id];

  int get length => _items.length;

  /// A copy, as ArcGIS returns: `toJS` of a list shares its array.
  JSArray<JsLayer> toArray() => [..._items].toJS;

  int indexOf(JsLayer layer) =>
      _items.indexWhere((item) => item.strictEquals(layer).toDart);

  void add(JsLayer layer, [int? index]) {
    _items.insert(index ?? _items.length, layer);
  }

  void addMany(JSArray<JsLayer> layers, [int? index]) {
    _items.insertAll(index ?? _items.length, layers.toDart);
  }

  JsLayer? remove(JsLayer layer) {
    final index = indexOf(layer);
    return index < 0 ? null : _items.removeAt(index);
  }

  JSArray<JsLayer> removeMany(JSArray<JsLayer> layers) {
    return [
      for (final layer in layers.toDart)
        if (remove(layer) case final removed?) removed,
    ].toJS;
  }

  void removeAll() {
    _items.clear();
  }
}

/// Like a basemap made from an id, it has its layers only once it is loaded.
@JSExport()
class FakeBasemap {
  FakeBasemap({
    List<FakeLayer> baseLayers = const [],
    List<FakeLayer> referenceLayers = const [],
    bool loaded = false,
  })  : _baseLayersOnLoad = baseLayers,
        _referenceLayersOnLoad = referenceLayers,
        _baseLayers = FakeCollection(loaded ? baseLayers : const []),
        _referenceLayers = FakeCollection(loaded ? referenceLayers : const []),
        _loaded = loaded;

  final List<FakeLayer> _baseLayersOnLoad;
  final List<FakeLayer> _referenceLayersOnLoad;
  final FakeCollection _baseLayers;
  final FakeCollection _referenceLayers;
  bool _loaded;
  Completer<void>? _held;

  late final JsBasemap js = createJSInteropWrapper(this) as JsBasemap;

  /// Makes every following `load()` wait until the returned completer
  /// completes.
  Completer<void> holdLoad() => _held = Completer<void>();

  List<String> get referenceLayerIds => _referenceLayers.layerIds;

  bool get loaded => _loaded;

  JsCollection<JsLayer> get baseLayers => _baseLayers.js;

  JsCollection<JsLayer> get referenceLayers => _referenceLayers.js;

  JSPromise<JSObject> load() {
    return Future<JSObject>(() async {
      await _held?.future;
      if (!_loaded) {
        _loaded = true;
        _baseLayers.addMany(_faces(_baseLayersOnLoad));
        _referenceLayers.addMany(_faces(_referenceLayersOnLoad));
      }
      return js;
    }).toJS;
  }

  static JSArray<JsLayer> _faces(List<FakeLayer> layers) =>
      [for (final layer in layers) layer.js].toJS;
}

@JSExport()
class FakeMap {
  FakeMap({List<FakeLayer> layers = const [], FakeBasemap? basemap})
      : _layers = FakeCollection(layers),
        basemap = basemap?.js;

  final FakeCollection _layers;
  JsBasemap? basemap;

  late final JsEsriMap js = createJSInteropWrapper(this) as JsEsriMap;

  List<String> get layerIds => _layers.layerIds;

  JsCollection<JsLayer> get layers => _layers.js;

  void add(JsLayer layer, [int? index]) => _layers.add(layer, index);

  void addMany(JSArray<JsLayer> layers, [int? index]) =>
      _layers.addMany(layers, index);

  JsLayer? remove(JsLayer layer) => _layers.remove(layer);

  JSArray<JsLayer> removeMany(JSArray<JsLayer> layers) =>
      _layers.removeMany(layers);

  JsLayer? findLayerById(String id) {
    for (final layer in _layers._items) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }
}

@JSExport()
class FakeView {
  FakeView(FakeMap map) : _map = map;

  final FakeMap _map;

  late final JsView js = createJSInteropWrapper(this) as JsView;

  JsEsriMap get map => _map.js;

  final Map<String, List<JSFunction>> _handlers = {};

  /// Every `toMap` call, in order.
  final List<({double x, double y})> toMapCalls = [];

  /// Where the map is under a screen point, or null where there is none.
  ({double latitude, double longitude})? Function(double x, double y)
      mapPointAt = (x, y) => null;

  /// Makes `toMap` throw, as it does for a view that is not ready.
  bool toMapThrows = false;

  /// Makes `toMap` return a point without `latitude` and `longitude`, as for
  /// a spatial reference that is neither WGS 84 nor Web Mercator.
  bool mapPointLacksCoordinates = false;

  /// The callbacks now attached to the event [name].
  List<JSFunction> handlersFor(String name) =>
      List.of(_handlers[name] ?? const []);

  /// Calls the callbacks attached to [name] with [event].
  void emit(String name, JSObject event) {
    for (final callback in handlersFor(name)) {
      callback.callAsFunction(null, event);
    }
  }

  JsHandle on(JSAny events, JSFunction callback) {
    final names = [
      for (final name in (events as JSArray<JSString>).toDart) name.toDart,
    ];
    for (final name in names) {
      (_handlers[name] ??= []).add(callback);
    }
    return _FakeHandle(() {
      for (final name in names) {
        _handlers[name]?.remove(callback);
      }
    }).js;
  }

  JsPoint? toMap(JSObject screenPoint) {
    final x = (screenPoint['x']! as JSNumber).toDartDouble;
    final y = (screenPoint['y']! as JSNumber).toDartDouble;
    toMapCalls.add((x: x, y: y));
    if (toMapThrows) throw StateError('toMap failed');
    if (mapPointLacksCoordinates) {
      return {'x': x, 'y': y}.jsify()! as JsPoint;
    }
    final point = mapPointAt(x, y);
    if (point == null) return null;
    return {'latitude': point.latitude, 'longitude': point.longitude}.jsify()!
        as JsPoint;
  }
}

@JSExport()
class _FakeHandle {
  _FakeHandle(this._onRemove);

  final void Function() _onRemove;

  late final JsHandle js = createJSInteropWrapper(this) as JsHandle;

  void remove() => _onRemove();
}

/// An ArcGIS pointer event: `{x, y, buttons, native: {timeStamp}}`.
JSObject pointerEvent({
  required double x,
  required double y,
  int buttons = 0,
  double timeStamp = 0,
}) {
  return {
    'x': x,
    'y': y,
    'buttons': buttons,
    'native': {'timeStamp': timeStamp},
  }.jsify()! as JSObject;
}

/// Puts a fake `esri.layers.VectorTileLayer` constructor on the page for the
/// rest of the test. The layers it constructs join the returned list, each
/// holding its load until [FakeVectorTileLayer.completeLoad] or
/// [FakeVectorTileLayer.failLoad].
List<FakeVectorTileLayer> installFakeVectorTileLayers() {
  final constructed = <FakeVectorTileLayer>[];
  JsLayer construct(JSObject properties) {
    final layer = FakeVectorTileLayer(
      id: (properties['id']! as JSString).toDart,
      styleLayerIds: const {},
      properties: properties.dartify(),
    )..holdLoad();
    constructed.add(layer);
    return layer.js;
  }

  _installLayerConstructor('VectorTileLayer', construct.toJS);
  return constructed;
}

/// Puts a fake `esri.layers.GraphicsLayer` constructor on the page for the
/// rest of the test. The layers it constructs join the returned list.
List<FakeGraphicsLayer> installFakeGraphicsLayers() {
  final constructed = <FakeGraphicsLayer>[];
  JsLayer construct(JSObject properties) {
    final layer = FakeGraphicsLayer(id: (properties['id']! as JSString).toDart);
    constructed.add(layer);
    return layer.js;
  }

  _installLayerConstructor('GraphicsLayer', construct.toJS);
  return constructed;
}

/// Puts a fake `esri.layers.SceneLayer` constructor on the page for the rest
/// of the test. The layers it constructs join the returned list.
List<FakeLayer> installFakeSceneLayers() {
  final constructed = <FakeLayer>[];
  JsLayer construct(JSObject properties) {
    final layer = FakeLayer(
      id: (properties['id']! as JSString).toDart,
      type: 'scene',
    );
    constructed.add(layer);
    return layer.js;
  }

  _installLayerConstructor('SceneLayer', construct.toJS);
  return constructed;
}

/// Puts a fake `esri.Graphic` constructor on the page for the rest of the
/// test. The graphic it constructs is a plain object with the properties it
/// was given, and in no layer.
void installFakeGraphics() {
  JSObject construct(JSObject properties) {
    properties['layer'] = null;
    return properties;
  }

  _installOnEsri('Graphic', construct.toJS);
}

/// Makes `esri.layers.<name>` the only layer constructor on the page for the
/// rest of the test.
void _installLayerConstructor(String name, JSFunction constructor) {
  final layers = JSObject();
  layers[name] = constructor;
  _installOnEsri('layers', layers);
}

/// Makes [value] `esri.<name>` on the page for the rest of the test, beside
/// the other fakes installed on `esri`.
void _installOnEsri(String name, JSAny value) {
  final previous = globalContext['esri'] as JSObject?;
  addTearDown(() => globalContext['esri'] = previous);

  final esri = JSObject();
  for (final member in ['Graphic', 'layers']) {
    if (previous?[member] case final fake?) esri[member] = fake;
  }
  esri[name] = value;
  globalContext['esri'] = esri;
}
