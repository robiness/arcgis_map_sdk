import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';

class GraphicsLayer {
  GraphicsLayer({
    this.id,
    this.data,
    this.onPressed,
    this.options,
    this.onChanged,
  });

  final String? id;
  final List<Graphic>? data;
  final void Function()? onPressed;
  final void Function(LatLng)? onChanged;
  GraphicsLayerOptions? options;
}

class GraphicsLayerOptions {
  GraphicsLayerOptions({
    required this.fields,
    this.elevationMode = ElevationMode.onTheGround,
    this.featureReduction,
    this.opacity = 1,
    this.effect,
  });

  final List<Field> fields;
  final ElevationMode elevationMode;
  final Object? featureReduction;

  /// The opacity of the whole layer, from 0 to 1. Only supported on web.
  final double opacity;

  /// A CSS-filter-like effect applied to the whole layer, e.g.
  /// `drop-shadow(0px 1px 2px #00000059)`. Only supported on web, and only
  /// in a 2D MapView; a SceneView ignores it.
  ///
  /// https://developers.arcgis.com/javascript/latest/api-reference/esri-layers-GraphicsLayer.html#effect
  final String? effect;
}
