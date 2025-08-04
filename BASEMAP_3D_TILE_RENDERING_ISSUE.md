# 3D Basemap Tile Rendering Issue

## Problem Statement

**Issue**: Basemap tiles in 3D SceneView are not rendered correctly on a random basis. Sometimes only the heightmap (elevation data) is displayed along with labels and other layers, but the actual basemap content (streets, imagery, proper colors) is missing, showing dark blue/black tiles instead.

**Environment**: 
- ArcGIS Maps SDK for Flutter (Web implementation)
- ArcGIS JavaScript API 4.33
- SceneView (3D mode)

## Symptoms

### What Works
- ✅ Heightmap/elevation data renders correctly
- ✅ Labels are displayed
- ✅ Other layers (graphics, feature layers) render properly
- ✅ No network errors in browser console
- ✅ Official ArcGIS JavaScript API examples work flawlessly

### What Fails
- ❌ Basemap tiles show as dark blue/black instead of proper content
- ❌ Streets, imagery, and basemap styling missing
- ❌ Issue occurs randomly/intermittently
- ❌ Problem is specific to Flutter SDK implementation

## Working Reference

The official ArcGIS JavaScript API example works perfectly:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="initial-scale=1,maximum-scale=1,user-scalable=no" />
    <title>Intro to SceneView - Create a 3D map</title>
    <style>
      html, body, #viewDiv {
        padding: 0;
        margin: 0;
        height: 100%;
        width: 100%;
      }
    </style>
    <link rel="stylesheet" href="https://js.arcgis.com/4.33/esri/themes/light/main.css" />
    <script src="https://js.arcgis.com/4.33/"></script>
    <script type="module">
      const [Map, SceneView] = await $arcgis.import([
        "@arcgis/core/Map.js",
        "@arcgis/core/views/SceneView.js",
      ]);

      const map = new Map({
        basemap: "topo-3d",
        ground: "world-elevation",
      });

      const view = new SceneView({
        container: "viewDiv",
        map: map,
        camera: {
          position: {
            spatialReference: { latestWkid: 3857, wkid: 102100 },
            x: -11262192.883555487,
            y: 2315246.351026253,
            z: 18161244.728082635,
          },
          heading: 0,
          tilt: 0.49,
        },
      });
    </script>
  </head>
  <body>
    <div id="viewDiv"></div>
  </body>
</html>
```

**Key Differences in Working Example**:
- Uses `basemap: "topo-3d"` directly
- Uses `ground: "world-elevation"` 
- Simple, direct initialization without complex wrapper logic

## Current Flutter Implementation Analysis

### Basemap Initialization

**File**: `arcgis_map_web_controller.dart:24-30`
```dart
late JsEsriMap? _map = const EsriMap().init(
  basemap: 'topo-3d',  // Hardcoded, not using user's basemap choice
  ground: _mapOptions.mapStyle == MapStyle.threeD
      ? _mapOptions.ground?.value
      : null,
  vectorTileLayerUrls: _mapOptions.vectorTilesUrls,
);
```

**Issues Identified**:
1. **Hardcoded Basemap**: Always uses `'topo-3d'` regardless of user's basemap selection
2. **Basemap Toggle Logic**: The basemap switching logic may conflict with initial hardcoded value
3. **Complex Initialization**: Multiple layers of abstraction compared to working example

### SceneView Creation

**File**: `arcgis_map_web_controller.dart:287-305`
```dart
JsSceneView _createJsSceneView() {
  return SceneView().init(
    map: _map,
    position: <double>[
      _mapOptions.initialCenter.longitude,
      _mapOptions.initialCenter.latitude,
    ],
    zoom: _mapOptions.zoom,
    tilt: _mapOptions.tilt,
    padding: _activePadding ?? _mapOptions.padding,
    rotationEnabled: _mapOptions.rotationEnabled,
    minZoom: _mapOptions.minZoom,
    maxZoom: _mapOptions.maxZoom,
    xMin: _mapOptions.xMin,
    xMax: _mapOptions.xMax,
    yMin: _mapOptions.yMin,
    yMax: _mapOptions.yMax,
    heading: _mapOptions.heading,
  );
}
```

## Potential Root Causes

### 1. **Basemap Initialization Race Condition**
- The map is initialized with hardcoded `'topo-3d'` basemap
- User's basemap choice is applied later via `toggleBaseMap()`
- This may cause tile loading conflicts or incomplete basemap switches

### 2. **WebGL Context Issues**
- The `_destroyWebglContext()` method may be causing tile rendering problems
- WebGL context loss/restore cycle might not properly reload basemap tiles

### 3. **Tile Loading Timing**
- Basemap tiles may not be fully loaded before SceneView initialization
- The `_baseMapLoaded` completer may not be sufficient for 3D tile loading

### 4. **JavaScript Interop Complications**
- Multiple layers of abstraction between Flutter and ArcGIS JavaScript API
- Potential issues with `jsify()` conversions or JavaScript object references

### 5. **Basemap Toggle Implementation**
The basemap switching logic has complex watch handles and recreation logic that may interfere with proper tile loading in 3D.

## Investigation Steps

### Phase 1: Basemap Initialization ✅ COMPLETED
- [x] **TESTED**: Removed hardcoded `'topo-3d'` and used user's basemap from start
- [x] **RESULT**: ❌ **NO IMPROVEMENT** - Issue persists even with `topo-3d` basemap
- [x] **CONCLUSION**: Problem is NOT related to basemap switching or hardcoded initialization
- [ ] Compare tile loading behavior between direct JavaScript API usage and Flutter wrapper
- [ ] Monitor basemap loading events and tile request timing

### Phase 2: Tile Loading Synchronization ✅ IMPLEMENTED
- [x] **IMPLEMENTED**: Comprehensive basemap loading detection in `_waitForBasemapFullyLoaded()`
- [x] **IMPLEMENTED**: View readiness check in `_waitForViewReady()`
- [x] **IMPLEMENTED**: Enhanced loading sequence: Basemap → View → Default UI
- [x] **ADDED**: Debug logging with emojis for easy identification
- [x] **ADDED**: Timeout safety nets (10s for basemap, 5s for view)
- [x] **ADDED**: Additional delays for tile rendering (500ms + 300ms)
- [ ] **TESTING REQUIRED**: Verify if this resolves the random tile rendering issue

### Phase 3: WebGL Context Management  
- [ ] Test if disabling WebGL context destruction fixes the issue
- [ ] Investigate if WebGL context restore properly reloads basemap tiles
- [ ] Check for WebGL resource limits or memory issues

### Phase 4: Simplification
- [ ] Create minimal reproduction case similar to working HTML example
- [ ] Remove complex abstraction layers temporarily
- [ ] Test direct JavaScript API calls vs Flutter wrapper

## Workarounds

### Temporary Solution 1: Force Basemap Refresh
```dart
// After SceneView initialization, force basemap reload
await Future.delayed(Duration(milliseconds: 1000));
controller.toggleBaseMap(baseMap: currentBasemap);
```

### Temporary Solution 2: Use Working Basemap
```dart
// Use known working basemap for 3D
basemap: BaseMap.arcgisTopographic,  // Known to work well in 3D
```

## Next Steps

1. **Immediate**: Test with simplified basemap initialization (remove hardcoded `'topo-3d'`)
2. **Short-term**: Implement comprehensive tile loading detection
3. **Long-term**: Refactor basemap management to match working JavaScript patterns

## Related Files

- `arcgis_map_web_controller.dart` - Main controller with basemap initialization
- `layer_controller.dart` - Basemap toggle and label management logic
- `esri_map.dart` - Map initialization component
- `scene_view.dart` - SceneView component initialization

## Fix 2 Implementation Details

### **What Was Changed**

1. **Enhanced Basemap Loading Detection** (`_waitForBasemapFullyLoaded()`):
   - Waits for `basemap.loaded` property
   - Checks all `baseLayers` are individually loaded
   - 10-second timeout safety net
   - Additional 500ms delay for tile rendering

2. **View Readiness Check** (`_waitForViewReady()`):
   - Waits for `view.ready` property  
   - 5-second timeout safety net
   - Additional 300ms delay for tile rendering

3. **Improved Loading Sequence**:
   ```dart
   // OLD: Create view immediately
   _sceneView = _createJsSceneView();
   
   // NEW: Wait for basemap → Create view → Wait for view ready
   await _waitForBasemapFullyLoaded();
   _sceneView = _createJsSceneView();
   await _waitForViewReady(_sceneView!);
   ```

4. **Debug Logging**:
   - 🗺️ Basemap loading progress
   - 👁️ View readiness status  
   - ✅ Success confirmations
   - ⚠️ Warning messages
   - ❌ Error handling

### **Expected Outcome**
This should eliminate race conditions where SceneView is created before basemap tiles are fully loaded and ready for rendering.

### **Critical Bug Fix Applied**
During testing, discovered that the new loading sequence caused null pointer crashes because methods like `onClickListener()`, `getZoom()`, etc. were being called before `_activeView` was initialized. Added null checks to all affected methods:

- `onClickListener()` - Returns empty stream if view not ready
- `getZoom()` - Returns empty stream if view not ready  
- `centerPosition()` - Returns empty stream if view not ready
- `getBounds()` - Returns empty stream if view not ready
- `visibleGraphics()` - Returns empty stream if view not ready
- `getVisibleGraphicIds()` - Returns empty list if view not ready
- `attributionText()` - Returns empty stream if view not ready

## Status

- **Discovered**: 2025-01-31
- **Priority**: High (affects core 3D functionality)
- **Fix 1**: ❌ Failed (hardcoded basemap issue)
- **Fix 2**: ✅ Implemented (comprehensive tile loading detection)
- **Testing**: 🔄 In Progress
- **Impact**: Random 3D basemap rendering failures in production

---

*This document will be updated as investigation progresses and solutions are identified.*