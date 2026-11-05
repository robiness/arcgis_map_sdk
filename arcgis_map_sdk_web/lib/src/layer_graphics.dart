import 'dart:js_interop';

import 'package:arcgis_map_sdk_web/js_interop/interop.dart';

/// A graphic with the string `id` in its attributes, or null where it has
/// none.
typedef IdentifiedGraphic = ({JsGraphic graphic, String? id});

/// The graphics of one graphics layer, found by the `id` in their attributes
/// without going through the layer.
///
/// The index follows what is added and removed here, by the id a graphic had
/// when it joined the layer. A lookup that finds it out of step with the
/// layer goes through the layer once and indexes it anew: when the graphic it
/// has for an id has left the layer by other means, or when the layer holds
/// graphics it lacks, such as a second graphic with a taken id or one added
/// to the layer directly.
class LayerGraphics {
  LayerGraphics(this.layer) {
    _reindex();
  }

  final JsGraphicsLayer layer;

  final Map<String, JsGraphic> _byId = {};

  /// The graphic with [id], the first in the layer where several share it,
  /// or null.
  JsGraphic? find(String id) {
    if (!_knows(id)) _reindex();
    return _byId[id];
  }

  void add(IdentifiedGraphic graphic) {
    layer.add(graphic.graphic);
    _index(graphic);
  }

  /// Adds [graphics] in one call, in their order.
  void addMany(List<IdentifiedGraphic> graphics) {
    if (graphics.isEmpty) return;
    layer.addMany([for (final added in graphics) added.graphic].toJS);
    graphics.forEach(_index);
  }

  /// Removes the graphic with [id], the first where several share it.
  void remove(String id) {
    final graphic = find(id);
    if (graphic == null) return;
    layer.remove(graphic);
    _byId.remove(id);
  }

  /// Removes the graphics with [ids] in one call. Ids the layer lacks are
  /// skipped.
  void removeMany(Iterable<String> ids) {
    final wanted = ids.toSet();
    if (!wanted.every(_knows)) _reindex();
    _remove([
      for (final id in wanted)
        if (_byId[id] case final graphic?) (graphic: graphic, id: id),
    ]);
  }

  /// Removes in one call every graphic with attributes that pass [test].
  void removeWhere(bool Function(JSObject attributes) test) {
    _remove([
      for (final graphic in layer.graphics.toArray().toDart)
        if (graphic.attributes case final attributes? when test(attributes))
          (graphic: graphic, id: stringAttribute(attributes, 'id')),
    ]);
  }

  void _remove(List<IdentifiedGraphic> graphics) {
    if (graphics.isEmpty) return;
    layer.removeMany([for (final removed in graphics) removed.graphic].toJS);
    for (final (:graphic, :id) in graphics) {
      if (id != null && _byId[id].strictEquals(graphic).toDart) {
        _byId.remove(id);
      }
    }
  }

  void _index(IdentifiedGraphic added) {
    final (:graphic, :id) = added;
    if (id == null) return;
    final indexed = _byId[id];
    if (indexed == null || !_holds(indexed)) {
      _byId[id] = graphic;
    }
  }

  void _reindex() {
    _byId.clear();
    for (final graphic in layer.graphics.toArray().toDart) {
      final attributes = graphic.attributes;
      final id = attributes == null ? null : stringAttribute(attributes, 'id');
      if (id != null) {
        _byId.putIfAbsent(id, () => graphic);
      }
    }
  }

  /// Whether the index can answer for [id] without going through the layer:
  /// the graphic it has is still there, or, lacking one, it has every
  /// graphic of the layer.
  bool _knows(String id) {
    final graphic = _byId[id];
    return graphic == null
        ? layer.graphics.length == _byId.length
        : _holds(graphic);
  }

  bool _holds(JsGraphic graphic) => graphic.layer.strictEquals(layer).toDart;
}

/// The value under [key] in [attributes], where it is a string.
String? stringAttribute(JSObject attributes, String key) {
  final value = attributes[key];
  return value.typeofEquals('string') ? (value! as JSString).toDart : null;
}
