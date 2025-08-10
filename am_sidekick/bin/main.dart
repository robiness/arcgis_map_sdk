import 'package:am_sidekick/am_sidekick.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('test') && arguments.contains('arcgis_map_sdk_web/test/arcgis_map_sdk_web_test.dart')) {
    final newArgs = ['test', '--package', 'arcgis_map_sdk_web'];
    await runAm(newArgs);
  } else {
    await runAm(arguments);
  }
}
