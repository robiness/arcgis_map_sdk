import 'dart:js_interop';

import 'package:arcgis_map_sdk_platform_interface/arcgis_map_sdk_platform_interface.dart';
import 'package:arcgis_map_sdk_web/arcgis_map_web_js.dart';
import 'package:arcgis_map_sdk_web/src/web_layer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_js_interop.dart';

void main() {
  group('WebLayerController Tests', () {
    late WebLayerController controller;
    late FakeJsView fakeView;
    late JSObject jsView;

    setUp(() {
      controller = WebLayerController(mapId: 1);
      fakeView = MockJsInteropFactory.createMockView(isSceneView: false);
      jsView = createJSInteropWrapper<FakeJsView>(fakeView);
    });

    group('moveCamera', () {
      test('should call goTo with correct center coordinates', () async {
        // Arrange
        const testPoint = LatLng(34.0522, -118.2437); // Los Angeles
        const testZoom = 10.0;

        // Act
        await controller.moveCamera(
          point: testPoint,
          zoomLevel: testZoom,
          view: jsView as JsView,
          isSceneView: false,
        );

        // Assert
        final capturedCalls = fakeView.getCapturedCalls();
        expect(capturedCalls, hasLength(1));

        final goToCall = fakeView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);
        expect(goToCall!['method'], equals('goTo'));

        // Verify the target parameters
        final target = goToCall['target'] as Map<String, dynamic>;
        expect(target['center'], equals([testPoint.longitude, testPoint.latitude]));
        expect(target['zoom'], equals(testZoom));
      });

      test('should call goTo without zoom when zoomLevel is null', () async {
        // Arrange
        const testPoint = LatLng(40.7128, -74.0060); // New York

        // Act
        await controller.moveCamera(
          point: testPoint,
          zoomLevel: null,
          view: jsView as JsView,
          isSceneView: false,
        );

        // Assert
        final goToCall = fakeView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);

        final target = goToCall!['target'] as Map<String, dynamic>;
        expect(target['center'], equals([testPoint.longitude, testPoint.latitude]));
        expect(target.containsKey('zoom'), isFalse);
      });

      test('should include camera properties for 3D scene view', () async {
        // Arrange
        final fakeSceneView = MockJsInteropFactory.createMockView(isSceneView: true);
        final jsSceneView = createJSInteropWrapper<FakeJsView>(fakeSceneView);
        
        const testPoint = LatLng(51.5074, -0.1278); // London
        const testZoom = 15.0;
        const testHeading = 45;
        const testTilt = 60;

        // Act
        await controller.moveCamera(
          point: testPoint,
          zoomLevel: testZoom,
          threeDHeading: testHeading,
          threeDTilt: testTilt,
          view: jsSceneView as JsView,
          isSceneView: true,
        );

        // Assert
        final goToCall = fakeSceneView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);

        final target = goToCall!['target'] as Map<String, dynamic>;
        expect(target['center'], equals([testPoint.longitude, testPoint.latitude]));
        expect(target['zoom'], equals(testZoom));
        
        // Verify 3D camera properties
        expect(target.containsKey('camera'), isTrue);
        final cameraObj = target['camera'];
        final camera = Map<String, dynamic>.from(cameraObj as Map);
        final positionObj = camera['position'];
        final position = Map<String, dynamic>.from(positionObj as Map);
        expect(position['longitude'], equals(testPoint.longitude));
        expect(position['latitude'], equals(testPoint.latitude));
        expect(position['z'], equals(10000)); // Default altitude
        expect(camera['heading'], equals(testHeading));
        expect(camera['tilt'], equals(testTilt));
      });

      test('should pass animation options when provided', () async {
        // Arrange
        const testPoint = LatLng(48.8566, 2.3522); // Paris
        final animationOptions = AnimationOptions(
          duration: 2000.0,
          animationCurve: AnimationCurve.easeInOut,
        );

        // Act
        await controller.moveCamera(
          point: testPoint,
          animationOptions: animationOptions,
          view: jsView as JsView,
          isSceneView: false,
        );

        // Assert
        final goToCall = fakeView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);
        expect(goToCall!['options'], isNotNull);

        final options = goToCall['options'] as Map<String, dynamic>;
        expect(options['duration'], equals(2000.0));
        expect(options['animationCurve'], equals('easeInOut')); // Uses .name property
      });

      test('should clear previous captured calls', () async {
        // Arrange
        const testPoint1 = LatLng(35.6762, 139.6503); // Tokyo
        const testPoint2 = LatLng(-33.8688, 151.2093); // Sydney

        // Act
        await controller.moveCamera(
          point: testPoint1,
          view: jsView as JsView,
          isSceneView: false,
        );

        fakeView.clearCapturedCalls();

        await controller.moveCamera(
          point: testPoint2,
          view: jsView as JsView,
          isSceneView: false,
        );

        // Assert
        final capturedCalls = fakeView.getCapturedCalls();
        expect(capturedCalls, hasLength(1));

        final lastCall = fakeView.getLastCall();
        final target = lastCall!['target'] as Map<String, dynamic>;
        expect(target['center'], equals([testPoint2.longitude, testPoint2.latitude]));
      });
    });

    group('zoomIn', () {
      test('should increase zoom by lodFactor', () async {
        // Arrange
        const initialZoom = 5.0;
        const lodFactor = 2;
        fakeView.zoom = initialZoom;

        // Act
        final result = await controller.zoomIn(
          lodFactor: lodFactor,
          view: jsView as JsView,
        );

        // Assert
        expect(result, isTrue);

        final goToCall = fakeView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);

        final target = goToCall!['target'] as Map<String, dynamic>;
        expect(target['zoom'], equals(initialZoom + lodFactor));
      });
    });

    group('zoomOut', () {
      test('should decrease zoom by lodFactor', () async {
        // Arrange
        const initialZoom = 10.0;
        const lodFactor = 3;
        fakeView.zoom = initialZoom;

        // Act
        final result = await controller.zoomOut(
          lodFactor: lodFactor,
          view: jsView as JsView,
        );

        // Assert
        expect(result, isTrue);

        final goToCall = fakeView.getLastCallForMethod('goTo');
        expect(goToCall, isNotNull);

        final target = goToCall!['target'] as Map<String, dynamic>;
        expect(target['zoom'], equals(initialZoom - lodFactor));
      });
    });
  });
}