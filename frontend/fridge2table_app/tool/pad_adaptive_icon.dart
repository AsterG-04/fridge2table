// One-off utility (not part of the app itself) that fixes the Android
// launcher icon being visibly cropped in a circle.
//
// Root cause: pubspec.yaml's flutter_launcher_icons config points
// adaptive_icon_foreground straight at assets/images/f2t_logo.png, which is
// a fully-opaque square with the fridge/leaf artwork close to its edges.
// Android composites an adaptive icon's foreground layer under a mask
// (circle, squircle, rounded-square, teardrop -- varies by device/launcher)
// that only guarantees the inner ~66% "safe zone" of the 108x108dp canvas
// stays visible; anything outside it can be clipped. A plain, edge-to-edge
// source image like this one gets clipped by exactly that mask on
// circle-mask launchers (e.g. stock Android/Pixel, and this project's
// emulator) -- which is what was actually being reported as "logo cut off".
//
// This script doesn't touch the in-app Home/Splash logo usages -- those
// display the same square source at a matching square aspect ratio with
// BoxFit.cover, which doesn't crop anything when the aspect ratios already
// match, so they were never actually the problem.
//
// Run: dart run tool/pad_adaptive_icon.dart
// Then: flutter pub run flutter_launcher_icons (regenerates the launcher
// icons from the new padded source).

import 'dart:io';

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/images/f2t_logo.png';
const _outputPath = 'assets/images/f2t_logo_adaptive.png';

// 1024px canvas is plenty of resolution for the largest launcher icon
// density (xxxhdpi, 192px) with headroom to spare.
const _canvasSize = 1024;

// Keeps the logo within Android's adaptive-icon safe zone (the inner ~66%
// of the canvas) with a bit of extra margin so it also reads comfortably
// under this app's own in-app rounded-square treatments.
const _logoFraction = 0.62;

void main() {
  final sourceBytes = File(_sourcePath).readAsBytesSync();
  final source = img.decodePng(sourceBytes);
  if (source == null) {
    stderr.writeln('Could not decode $_sourcePath');
    exit(1);
  }

  final logoSize = (_canvasSize * _logoFraction).round();
  final resizedLogo = img.copyResize(
    source,
    width: logoSize,
    height: logoSize,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(
    width: _canvasSize,
    height: _canvasSize,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final offset = (_canvasSize - logoSize) ~/ 2;
  img.compositeImage(canvas, resizedLogo, dstX: offset, dstY: offset);

  File(_outputPath).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln(
    'Wrote $_outputPath ($_canvasSize x $_canvasSize, logo at '
    '${(_logoFraction * 100).round()}% with transparent padding).',
  );
}
