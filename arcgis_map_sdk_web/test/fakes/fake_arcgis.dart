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
  Completer<void>? _held;
  JSObject? _loadError;
  bool _loaded = false;

  @override
  JsLayer _wrap() {
    return createJSInteropWrapper<FakeVectorTileLayer>(this) as JsLayer;
  }

  /// Makes every following `load()` wait until the returned completer
  /// completes, or until [completeLoad] or [failLoad].
  Completer<void> holdLoad() => _held = Completer<void>();

  void completeLoad() => _held!.complete();

  /// Rejects the held loads, and every later one, as ArcGIS does: with an
  /// error object that has [name] and [message].
  void failLoad(String name, String message) {
    _loadError = {'name': name, 'message': message}.jsify()! as JSObject;
    _held!.complete();
  }

  @override
  JSPromise<JSObject> load() {
    loadCount++;
    return JSPromise<JSObject>(
      (JSFunction resolve, JSFunction reject) {
        _settle().then((error) {
          if (error == null) {
            _loaded = true;
            resolve.callAsFunction(null, js);
          } else {
            reject.callAsFunction(null, error);
          }
        });
      }.toJS,
    );
  }

  /// What the load rejects with, or null when it resolves.
  Future<JSObject?> _settle() async {
    if (failsToLoad) {
      return JsError('$id failed to load');
    }
    await _held?.future;
    return _loadError;
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
}

/// Puts a fake `esri.layers.VectorTileLayer` constructor on the page for the
/// rest of the test. The layers it constructs join the returned list, each
/// holding its load until [FakeVectorTileLayer.completeLoad] or
/// [FakeVectorTileLayer.failLoad].
List<FakeVectorTileLayer> installFakeVectorTileLayers() {
  final previous = globalContext['esri'];
  addTearDown(() => globalContext['esri'] = previous);

  final constructed = <FakeVectorTileLayer>[];
  final layers = JSObject();
  layers['VectorTileLayer'] = (JSObject properties) {
    final layer = FakeVectorTileLayer(
      id: (properties['id']! as JSString).toDart,
      styleLayerIds: const {},
      properties: properties.dartify(),
    )..holdLoad();
    constructed.add(layer);
    return layer.js;
  }.toJS;
  final esri = JSObject();
  esri['layers'] = layers;
  globalContext['esri'] = esri;
  return constructed;
}
