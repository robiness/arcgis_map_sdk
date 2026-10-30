import 'package:arcgis_example/main.dart';
import 'package:arcgis_example/pointer_interceptor_web.dart';
import 'package:arcgis_map_sdk/arcgis_map_sdk.dart';
import 'package:flutter/material.dart';

/// A map at Clonee, County Meath, to check against the real ArcGIS API what
/// the SDK does to the basemap's own county boundary lines and labels. The
/// buttons hide and show them, switch between the map and the satellite
/// basemap and between 2D and 3D, so that what was set stays set across the
/// switches.
///
/// A county layer added to this page expects a VectorTileServer-shaped service
/// with the source layers `borders`, `area_labels` and `border_labels`, such
/// as the one in `example/spike/server.py` on the `spike/vector-tiles` branch.
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

  ArcgisMapController? _controller;
  var _is3d = false;
  var _isSatellite = false;
  var _areBasemapBoundariesHidden = false;

  void _toggleMapStyle() {
    setState(() => _is3d = !_is3d);
    _controller?.switchMapStyle(_is3d ? MapStyle.threeD : MapStyle.twoD);
  }

  Future<void> _toggleBasemap() async {
    setState(() => _isSatellite = !_isSatellite);
    await _controller?.toggleBaseMap(
      baseMap: _isSatellite ? BaseMap.osmHybrid : BaseMap.osmLightGray,
    );
  }

  Future<void> _toggleBasemapBoundaries() async {
    setState(
      () => _areBasemapBoundariesHidden = !_areBasemapBoundariesHidden,
    );
    await _controller?.setBasemapStyleLayersVisible(
      styleLayerIds: _basemapBoundaryStyleLayerIds,
      visible: !_areBasemapBoundariesHidden,
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
            initialCenter: const LatLng(53.4105, -6.4400),
            zoom: 12,
            minZoom: 5,
            mapStyle: MapStyle.twoD,
            onMapCreated: (controller) => _controller = controller,
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
                    onPressed: _toggleBasemapBoundaries,
                    child: Text(
                      _areBasemapBoundariesHidden
                          ? 'Show basemap boundaries'
                          : 'Hide basemap boundaries',
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
