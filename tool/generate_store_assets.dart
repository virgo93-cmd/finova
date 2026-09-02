import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final icon = img.decodePng(
    File('assets/branding/finova_icon_master.png').readAsBytesSync(),
  );
  final feature = img.decodePng(
    File('assets/branding/finova_feature_graphic_master.png').readAsBytesSync(),
  );
  if (icon == null || feature == null) {
    throw StateError('Unable to decode branding masters.');
  }

  final output = Directory('assets/store')..createSync(recursive: true);
  File('${output.path}/finova_store_icon_512.png').writeAsBytesSync(
    img.encodePng(img.copyResize(icon, width: 512, height: 512), level: 9),
  );
  File('${output.path}/finova_feature_graphic_1024x500.png').writeAsBytesSync(
    img.encodePng(img.copyResize(feature, width: 1024, height: 500), level: 9),
  );
}
