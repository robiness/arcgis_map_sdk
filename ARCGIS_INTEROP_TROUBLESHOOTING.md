# ArcGIS JavaScript API - Dart Interop Troubleshooting Guide

This document tracks recurring issues and solutions when integrating ArcGIS Maps SDK for JavaScript with Dart js_interop.

## Table of Contents
- [JavaScript Class Access Issues](#javascript-class-access-issues)
- [Container and Timing Issues](#container-and-timing-issues)
- [CDN vs Webpack Differences](#cdn-vs-webpack-differences)
- [Common Error Patterns](#common-error-patterns)
- [Solutions Reference](#solutions-reference)

---

## JavaScript Class Access Issues

### Problem: "SceneLayer constructor not found"

**Error**: `Exception: SceneLayer constructor not found. Ensure ArcGIS API is loaded.`

**Root Cause**: ArcGIS CDN does NOT automatically expose modules globally. Modules only exist within AMD require() callbacks.

**What Doesn't Work**:
```dart
@JS('window.SceneLayer')  // ❌ This doesn't exist
external JSFunction? get sceneLayerConstructor;
```

**What Works - Solution Pattern**:

✅ **IMPLEMENTED**: The JavaScript bridge has been added to the Dart code in `arcgis_map_sdk_web.dart` around line 365-395. The AMD require() now includes `"esri/layers/SceneLayer"` and exposes it globally as `window.SceneLayer`.

1. **JavaScript Bridge** (implemented in Dart AMD require):
```html
<script src="https://js.arcgis.com/4.33/"></script>
<script>
// Bridge: Expose ArcGIS modules globally for Dart interop
require([
  "esri/layers/SceneLayer",
  "esri/Map",
  "esri/views/SceneView",
  "esri/views/MapView"
], function(SceneLayer, Map, SceneView, MapView) {
  // Make constructors globally available
  window.SceneLayer = SceneLayer;
  window.EsriMap = Map;
  window.EsriSceneView = SceneView;
  window.EsriMapView = MapView;
  
  // Signal readiness to Dart
  window.dispatchEvent(new CustomEvent('arcgis-ready'));
  console.log('ArcGIS modules exposed globally');
});
</script>
```

2. **Dart Binding**:
```dart
@JS('window.SceneLayer')
external JSFunction? get sceneLayerConstructor;

// Usage with null check
final constructor = sceneLayerConstructor;
if (constructor == null) {
  throw Exception('SceneLayer constructor not found. Ensure ArcGIS API is loaded.');
}
final sceneLayer = constructor.callAsFunction(null, options) as JsSceneLayer;
```

3. **Wait for Readiness** (optional):
```dart
// Listen for arcgis-ready event before using constructors
```

---

## Container and Timing Issues

### Problem: "Map container not found for id: map-X"

**Error**: `Exception: Map container not found for id: map-0`

**Root Cause**: ArcGIS initialization runs before Flutter creates the HTML container element.

**Solution - Container Wait Pattern**:
```dart
// Wait for Flutter to create the container element
web.Element? container;

// Wait up to 5 seconds for container to appear
for (int i = 0; i < 50; i++) {
  container = web.document.getElementById('map-$mapId');
  if (container != null) break;
  await Future.delayed(Duration(milliseconds: 100));
}

if (container == null) {
  throw Exception('Map container not found for id: map-$mapId after waiting');
}
```

**Why This Happens**:
1. Dart calls ArcGIS initialization
2. ArcGIS immediately looks for HTML container
3. Flutter hasn't created the HtmlElementView container yet
4. Container lookup fails

---

## CDN vs Webpack Differences

### CDN Approach (Current)
- **Loading**: `<script src="https://js.arcgis.com/4.33/"></script>`
- **Module Access**: AMD require() callbacks only
- **Global Exposure**: Manual bridge required
- **Pros**: No build step, smaller bundle
- **Cons**: Manual bridging needed for Dart interop

### Webpack Approach (Previous)
- **Loading**: Bundled modules in build
- **Module Access**: Direct global exposure possible
- **Global Exposure**: Automatic through webpack config
- **Pros**: Direct global access
- **Cons**: Large bundle size, build complexity

### Key Differences for Dart Interop:
| Aspect | CDN | Webpack |
|--------|-----|---------|
| `window.SceneLayer` | ❌ Requires bridge | ✅ Can be exposed directly |
| Build step | ❌ None | ✅ Required |
| Bundle size | ✅ Smaller | ❌ Larger |
| Dart integration | ❌ Manual bridging | ✅ Direct binding |

---

## Common Error Patterns

### 1. JS Interop Compilation Errors

**Error**: `The operator '[]' isn't defined for the class 'JSObject'`
**Solution**: Use `getProperty()` or external functions instead of `[]` operator

**Error**: `The method 'callAsConstructor' isn't defined`
**Solution**: Use external constructor functions instead:
```dart
@JS('window.SceneLayer')
external JsSceneLayer createSceneLayer(JSObject options);
```

**Error**: `TypeError: Class constructor p cannot be invoked without 'new'`
**Solution**: Use jsEval with wrapper function to ensure 'new' operator:
```dart
final createSceneLayerJS = '''
  (function(options) {
    return new window.SceneLayer(options);
  })
''';
final constructorFn = jsEval(createSceneLayerJS.toJS) as JSFunction;
final sceneLayer = constructorFn.callAsFunction(null, options) as JsSceneLayer;
```

**Error**: `@JS('$arcgis')` constant evaluation error
**Solution**: Escape with `@JS('\$arcgis')` or use different approach

### 2. Module Loading Errors

**Pattern**: `X constructor not found`
**Root Cause**: Module not exposed globally
**Solution**: Add to JavaScript bridge

### 3. Timing Errors

**Pattern**: `Container not found`, `Element not ready`
**Root Cause**: Race condition between Dart and DOM
**Solution**: Add wait loops with timeouts

---

## Solutions Reference

### JavaScript Bridge Template

Use this template in your HTML to expose ArcGIS modules:

```html
<script src="https://js.arcgis.com/4.33/"></script>
<script>
// ArcGIS-Dart Interop Bridge
require([
  "esri/layers/SceneLayer",
  "esri/layers/FeatureLayer",
  "esri/layers/GraphicsLayer",
  "esri/Map",
  "esri/views/SceneView",
  "esri/views/MapView",
  "esri/Graphic",
  "esri/geometry/Point",
  // Add other modules as needed
], function(
  SceneLayer, FeatureLayer, GraphicsLayer,
  Map, SceneView, MapView,
  Graphic, Point
) {
  // Expose globally for Dart js_interop
  window.SceneLayer = SceneLayer;
  window.FeatureLayer = FeatureLayer;
  window.GraphicsLayer = GraphicsLayer;
  window.EsriMap = Map;
  window.EsriSceneView = SceneView;
  window.EsriMapView = MapView;
  window.EsriGraphic = Graphic;
  window.EsriPoint = Point;
  
  // Signal readiness
  window.arcgisModulesReady = true;
  window.dispatchEvent(new CustomEvent('arcgis-ready'));
  console.log('ArcGIS modules exposed globally for Dart interop');
});
</script>
```

### Dart Binding Template

```dart
// External constructor functions (preferred approach)
@JS('window.SceneLayer')
external JsSceneLayer createSceneLayer(JSObject options);

@JS('window.EsriMap')
external JsEsriMap createEsriMap(JSObject options);

@JS('window.EsriSceneView')
external JsSceneView createEsriSceneView(JSObject options);

// Constructor availability check (optional)
@JS('window.SceneLayer')
external JSFunction? get sceneLayerConstructor;

// Usage pattern with error handling (jsEval approach - most reliable)
Future<JsSceneLayer> createSceneLayerSafe(String url, String id) async {
  // Check if constructor exists
  final constructor = sceneLayerConstructor;
  if (constructor == null) {
    throw Exception('SceneLayer constructor not found. Check JavaScript bridge.');
  }
  
  // Create options
  final options = {'url': url, 'id': id}.jsify() as JSObject;
  
  // Use jsEval with wrapper function to ensure 'new' operator
  final createSceneLayerJS = '''
    (function(options) {
      return new window.SceneLayer(options);
    })
  ''';
  final constructorFn = jsEval(createSceneLayerJS.toJS) as JSFunction;
  return constructorFn.callAsFunction(null, options) as JsSceneLayer;
}
```

### Container Wait Helper

```dart
Future<web.Element> waitForContainer(String containerId, {int timeoutSeconds = 5}) async {
  web.Element? container;
  final maxAttempts = timeoutSeconds * 10; // 100ms intervals
  
  for (int i = 0; i < maxAttempts; i++) {
    container = web.document.getElementById(containerId);
    if (container != null) return container;
    await Future.delayed(Duration(milliseconds: 100));
  }
  
  throw Exception('Container $containerId not found after ${timeoutSeconds}s');
}
```

---

## Debugging Tips

1. **Check Browser Console**: Look for ArcGIS loading messages
2. **Verify Global Exposure**: In browser console, check `window.SceneLayer`
3. **Test Module Loading**: Verify `require` works in console
4. **Check Container Timing**: Inspect DOM for container creation
5. **Monitor Events**: Listen for `arcgis-ready` custom event

---

## Version Information

- **ArcGIS JS API**: 4.33
- **Dart SDK**: Latest stable
- **Flutter**: Latest stable
- **Last Updated**: 2025-01-26

---

*This document should be updated whenever new interop issues are discovered or solutions are improved.*