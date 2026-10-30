import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';

/// Basemap reference layers that [moveReferenceLayersBeneathGraphics] moved
/// into a map, with the basemap they came from.
typedef MovedReferenceLayers = ({JsBasemap basemap, JSArray<JsLayer> layers});

/// Moves the reference layers (labels) of [map]'s basemap into its operational
/// layers so that graphics render on top of them: directly beneath the lowest
/// graphics layer, or on top when there is none. Directly beneath it, so they
/// stay above a layer an app added beneath the graphics, e.g. a vector tile
/// layer at index 0.
///
/// The labels moved for an earlier basemap, [previous], go back to it first:
/// they would otherwise stay on top of the new basemap's imagery, and since a
/// basemap id always yields the same basemap, that one would come back without
/// labels.
///
/// Returns the moved layers, to pass as [previous] after the next basemap
/// change, or null when nothing was moved: the basemap has no reference
/// layers, or the map's basemap changed while it loaded.
Future<MovedReferenceLayers?> moveReferenceLayersBeneathGraphics(
  JsEsriMap map, {
  MovedReferenceLayers? previous,
}) async {
  if (previous != null) {
    map.removeMany(previous.layers);
    previous.basemap.referenceLayers.addMany(previous.layers);
  }

  final basemap = map.basemap as JsBasemap;

  if (!basemap.loaded) {
    await basemap.load().toDart;
  }

  // The later change moves its own basemap's labels; these would end up on
  // top of that basemap.
  if (!map.basemap.strictEquals(basemap).toDart) {
    return null;
  }

  final referenceLayers = basemap.referenceLayers;
  final items = referenceLayers.toArray();
  if (items.toDart.isEmpty) {
    return null;
  }

  map.addMany(items, _lowestGraphicsLayerIndex(map));
  referenceLayers.removeAll();
  return (basemap: basemap, layers: items);
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
