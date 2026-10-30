import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';

/// Basemap reference layers that [moveReferenceLayersBeneathGraphics] moved
/// into a map, with the basemap they came from.
typedef MovedReferenceLayers = ({JsBasemap basemap, JSArray<JsLayer> layers});

/// The reference layers [moveReferenceLayersBeneathGraphics] moved into one
/// map, or null when the map holds none.
class MovedReferenceLayersHolder {
  MovedReferenceLayers? current;
}

/// Moves the reference layers (labels) of [map]'s basemap into its operational
/// layers so that graphics render on top of them: directly beneath the lowest
/// graphics layer, or on top when there is none. Directly beneath it, so they
/// stay above a layer an app added beneath the graphics, e.g. a vector tile
/// layer at index 0.
///
/// The labels [moved] holds for an earlier basemap go back to it first: they
/// would otherwise stay on top of the new basemap's imagery, and since a
/// basemap id always yields the same basemap, that one would come back without
/// labels.
///
/// [moved] changes in the same synchronous step as the map, so a call made
/// before this one completes, e.g. a second basemap change in the same task,
/// finds the labels the map holds. It then holds the layers moved here, or
/// null when the basemap has none. When the map's basemap changed while it
/// loaded, nothing moves here and [moved] stays as the later call leaves it.
Future<void> moveReferenceLayersBeneathGraphics(
  JsEsriMap map,
  MovedReferenceLayersHolder moved,
) async {
  final previous = moved.current;
  if (previous != null) {
    map.removeMany(previous.layers);
    previous.basemap.referenceLayers.addMany(previous.layers);
    moved.current = null;
  }

  final basemap = map.basemap as JsBasemap;

  if (!basemap.loaded) {
    await basemap.load().toDart;
  }

  // The later change moves its own basemap's labels; these would end up on
  // top of that basemap.
  if (!map.basemap.strictEquals(basemap).toDart) {
    return;
  }

  final referenceLayers = basemap.referenceLayers;
  final items = referenceLayers.toArray();
  if (items.toDart.isEmpty) {
    return;
  }

  map.addMany(items, _lowestGraphicsLayerIndex(map));
  referenceLayers.removeAll();
  moved.current = (basemap: basemap, layers: items);
}

int _lowestGraphicsLayerIndex(JsEsriMap map) {
  final layers = map.layers;
  for (final layer in layers.toArray().toDart) {
    if (layer.type == 'graphics') {
      return layers.indexOf(layer);
    }
  }
  return layers.length;
}
