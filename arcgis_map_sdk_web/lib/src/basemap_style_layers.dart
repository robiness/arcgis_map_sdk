import 'dart:developer' as developer;
import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';

/// The last visibility of every basemap style layer id an app gave, which it
/// applies to the vector tile layers of whichever basemap is current.
///
/// Hiding a style layer does not carry over to another basemap, and a basemap
/// id always yields the same basemap object, which keeps what was set on it.
/// So every id stays recorded, shown or hidden, and [applyTo] sets all of them
/// on the layers of a basemap that has just become current: a basemap that
/// comes back then matches the last call, not the last call made while it was
/// current.
class BasemapStyleLayers {
  final Map<String, bool> _visible = {};

  /// Records [visible] for [styleLayerIds] at once, then [applyTo] the layers
  /// [layers] completes with.
  ///
  /// The layers are a future because the current basemap may still be loading.
  /// Recording before waiting for them keeps the calls in the order they were
  /// made: a call still waiting does not overwrite a later one, and one whose
  /// layers fail to arrive still counts.
  Future<void> setVisible(
    List<String> styleLayerIds, {
    required bool visible,
    required Future<Iterable<JsLayer>> layers,
  }) async {
    for (final id in styleLayerIds) {
      _visible[id] = visible;
    }
    await applyTo(await layers);
  }

  /// Sets every recorded id on the vector tile layers among [layers], once
  /// they have loaded. Ids a layer lacks are skipped; a layer that fails is
  /// logged and skipped.
  Future<void> applyTo(Iterable<JsLayer> layers) {
    return Future.wait([
      for (final layer in layers)
        if (layer.type == 'vector-tile') _apply(layer as JsVectorTileLayer),
    ]);
  }

  Future<void> _apply(JsVectorTileLayer layer) async {
    try {
      await layer.load().toDart;
      // Read after the load, so a call made meanwhile is not overwritten.
      for (final MapEntry(key: id, value: visible) in _visible.entries) {
        if (layer.getStyleLayer(id) != null) {
          layer.setStyleLayerVisibility(id, visible ? 'visible' : 'none');
        }
      }
    } catch (e, stack) {
      developer.log(
        'Error changing the style layers of ${layer.id}',
        name: 'arcgis_map_sdk_web',
        error: e,
        stackTrace: stack,
        level: 1000,
      );
    }
  }
}

/// The layers of [basemap] once it has loaded: its base layers, its reference
/// layers, then [movedReferenceLayers], the reference layers the SDK moved
/// into the map to draw them beneath the graphics.
Future<List<JsLayer>> basemapLayers(
  JsBasemap basemap, {
  JSArray<JsLayer>? movedReferenceLayers,
}) async {
  await basemap.load().toDart;
  return [
    ...basemap.baseLayers.toArray().toDart,
    ...basemap.referenceLayers.toArray().toDart,
    ...?movedReferenceLayers?.toDart,
  ];
}
