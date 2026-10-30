import 'package:arcgis_example/main.dart';
import 'package:arcgis_example/pointer_interceptor_web.dart';
import 'package:arcgis_map_sdk/arcgis_map_sdk.dart';
import 'package:flutter/material.dart';

/// A map at Clonee, County Meath, to check against the real ArcGIS API a
/// county layer drawn from a vector tile style, and what the SDK does to the
/// basemap's own county boundary lines and labels. Once the county layer has
/// loaded, the basemap's are hidden. The buttons hide and show them and the
/// county layer, switch between the map and the satellite basemap, the county
/// layer following with its own palette, and between 2D and 3D, to check that
/// what was set stays set across the switches.
///
/// The county layer expects a VectorTileServer-shaped service at
/// `VECTOR_TILE_SERVICE_URL` with the source layers `borders`, `area_labels`
/// and `border_labels`, such as the one in `example/spike/server.py` on the
/// `spike/vector-tiles` branch. Its requests carry `VECTOR_TILE_TOKEN` as a
/// bearer token.
class VectorTileStyleExamplePage extends StatefulWidget {
  const VectorTileStyleExamplePage({super.key});

  @override
  State<VectorTileStyleExamplePage> createState() =>
      _VectorTileStyleExamplePageState();
}

class _VectorTileStyleExamplePageState
    extends State<VectorTileStyleExamplePage> {
  /// The boundary lines and county labels of `osm/light-gray` and
  /// `osm/hybrid`; each id is in one of the two basemaps.
  static const _basemapBoundaryStyleLayerIds = [
    'administrative boundary/level 5/casing',
    'administrative boundary/level 6/casing',
    'administrative boundary/level 5/line',
    'administrative boundary/level 6/line',
    'administrative boundary/level 5',
    'administrative boundary/level 6',
    'administrative label/county level 5',
    'administrative label/county level 6',
  ];

  static const _vectorTileServiceUrl = String.fromEnvironment(
    'VECTOR_TILE_SERVICE_URL',
    defaultValue: 'http://localhost:8765/boundaries/county/VectorTileServer',
  );
  static const _vectorTileToken = String.fromEnvironment(
    'VECTOR_TILE_TOKEN',
    defaultValue: 'spike-token',
  );
  static const _clonee = LatLng(53.4105, -6.4400);

  ArcgisMapController? _controller;
  var _is3d = false;
  var _isSatellite = false;
  var _areBasemapBoundariesHidden = false;

  /// Whether the county layer was added, from the start of its load on; a
  /// style set during the load waits for it.
  var _hasCountyLayer = false;
  var _areCountiesHidden = false;

  /// A dark line with a white halo on the map, a white line with a dark halo
  /// on satellite.
  static Map<String, Object?> _countyStyle({required bool satellite}) {
    final line = satellite ? '#ffffff' : '#333333';
    final halo = satellite ? '#333333' : '#ffffff';
    const font = ['Arial Unicode MS Regular'];
    final labelPaint = {
      'text-color': line,
      'text-halo-color': halo,
      'text-halo-width': 1.5,
    };
    return {
      'version': 8,
      'sources': {
        'counties': {'type': 'vector', 'url': _vectorTileServiceUrl},
      },
      'glyphs': 'https://basemaps.arcgis.com/arcgis/rest/services/'
          'OpenStreetMap_v2/VectorTileServer/resources/fonts/'
          '{fontstack}/{range}.pbf',
      'layers': [
        {
          'id': 'border halo',
          'type': 'line',
          'source': 'counties',
          'source-layer': 'borders',
          'layout': {'line-join': 'round', 'line-cap': 'round'},
          'paint': {'line-color': halo, 'line-width': 5},
        },
        {
          'id': 'border',
          'type': 'line',
          'source': 'counties',
          'source-layer': 'borders',
          'layout': {'line-join': 'round', 'line-cap': 'round'},
          'paint': {'line-color': line, 'line-width': 2},
        },
        {
          'id': 'area label',
          'type': 'symbol',
          'source': 'counties',
          'source-layer': 'area_labels',
          'maxzoom': 13,
          'layout': {
            'text-field': '{name} · {code}',
            'text-font': font,
            'text-size': 14,
          },
          'paint': labelPaint,
        },
        {
          'id': 'border label',
          'type': 'symbol',
          'source': 'counties',
          'source-layer': 'border_labels',
          'minzoom': 13,
          'layout': {
            'text-field': '{name}',
            'text-font': font,
            'text-size': 12,
          },
          'paint': labelPaint,
        },
      ],
    };
  }

  Future<void> _onMapCreated(ArcgisMapController controller) async {
    _controller = controller;
    controller.setRequestHeaders(
      urlPrefix: '${Uri.parse(_vectorTileServiceUrl).origin}/',
      headers: () async => {'Authorization': 'Bearer $_vectorTileToken'},
    );
    await controller.addGraphicsLayer(
      layerId: 'pins',
      options: GraphicsLayerOptions(
        fields: [
          Field(name: 'oid', type: 'oid'),
          Field(name: 'id', type: 'string'),
        ],
      ),
    );
    await controller.addGraphic(
      layerId: 'pins',
      graphic: PointGraphic(
        latitude: _clonee.latitude,
        longitude: _clonee.longitude,
        attributes: Attributes({'id': 'clonee'}),
        symbol: const SimpleMarkerSymbol(
          color: Colors.red,
          outlineColor: Colors.white,
          radius: 8,
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _hasCountyLayer = true);
    try {
      await controller.addVectorTileLayer(
        layerId: 'counties',
        style: _countyStyle(satellite: _isSatellite),
        index: 0,
      );
    } catch (e) {
      if (mounted) setState(() => _hasCountyLayer = false);
      _showError(e);
      return;
    }
    await _setBasemapBoundariesHidden(true);
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$error')));
  }

  void _toggleMapStyle() {
    setState(() => _is3d = !_is3d);
    _controller?.switchMapStyle(_is3d ? MapStyle.threeD : MapStyle.twoD);
  }

  Future<void> _toggleBasemap() async {
    setState(() => _isSatellite = !_isSatellite);
    if (_hasCountyLayer) _followBasemapWithCountyStyle();
    await _controller?.toggleBaseMap(
      baseMap: _isSatellite ? BaseMap.osmHybrid : BaseMap.osmLightGray,
    );
  }

  Future<void> _followBasemapWithCountyStyle() async {
    try {
      await _controller?.setVectorTileStyle(
        layerId: 'counties',
        style: _countyStyle(satellite: _isSatellite),
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _toggleCounties() {
    setState(() => _areCountiesHidden = !_areCountiesHidden);
    _controller?.setLayerVisibility(
      layerId: 'counties',
      visible: !_areCountiesHidden,
    );
  }

  Future<void> _setBasemapBoundariesHidden(bool hidden) async {
    if (!mounted) return;
    setState(() => _areBasemapBoundariesHidden = hidden);
    await _controller?.setBasemapStyleLayersVisible(
      styleLayerIds: _basemapBoundaryStyleLayerIds,
      visible: !hidden,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          ArcgisMap(
            apiKey: arcGisApiKey,
            basemap: BaseMap.osmLightGray,
            ground: Ground.worldElevation,
            showLabelsBeneathGraphics: true,
            initialCenter: _clonee,
            zoom: 12,
            minZoom: 5,
            mapStyle: MapStyle.twoD,
            onMapCreated: _onMapCreated,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PointerInterceptorWeb(
                  child: ElevatedButton(
                    onPressed: _toggleMapStyle,
                    child: Text(_is3d ? '2D' : '3D'),
                  ),
                ),
                PointerInterceptorWeb(
                  child: ElevatedButton(
                    onPressed: _toggleBasemap,
                    child: Text(_isSatellite ? 'Map' : 'Satellite'),
                  ),
                ),
                PointerInterceptorWeb(
                  child: ElevatedButton(
                    onPressed: () => _setBasemapBoundariesHidden(
                      !_areBasemapBoundariesHidden,
                    ),
                    child: Text(
                      _areBasemapBoundariesHidden
                          ? 'Show basemap boundaries'
                          : 'Hide basemap boundaries',
                    ),
                  ),
                ),
                PointerInterceptorWeb(
                  child: ElevatedButton(
                    onPressed: _hasCountyLayer ? _toggleCounties : null,
                    child: Text(
                      _areCountiesHidden ? 'Show counties' : 'Hide counties',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
