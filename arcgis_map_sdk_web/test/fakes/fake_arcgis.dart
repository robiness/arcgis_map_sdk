/// Fakes of the ArcGIS objects the web plugin reads and changes.
///
/// Each fake is a Dart object with a JS face in its `js`. The face is created
/// once: `indexOf`, `remove` and `==` of the fakes' collections need the same
/// JS object every time.
library;

import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';

@JSExport()
class FakeLayer {
  FakeLayer({required this.id, this.type = 'graphics'});

  final String id;
  final String type;
  bool visible = true;
  bool destroyed = false;

  late final JsLayer js = createJSInteropWrapper(this) as JsLayer;

  JSPromise<JSObject> load() => Future<JSObject>.value(js).toJS;

  void destroy() {
    destroyed = true;
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

  late final JsBasemap js = createJSInteropWrapper(this) as JsBasemap;

  List<String> get referenceLayerIds => _referenceLayers.layerIds;

  bool get loaded => _loaded;

  JsCollection<JsLayer> get baseLayers => _baseLayers.js;

  JsCollection<JsLayer> get referenceLayers => _referenceLayers.js;

  JSPromise<JSObject> load() {
    return Future<JSObject>(() {
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
