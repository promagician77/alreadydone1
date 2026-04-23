import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates a simple app icon (1024x1024) for flutter_launcher_icons.
/// Run: dart run tool/generate_icon.dart
/// Replace assets/icon/app_icon.png with your own 1024x1024 design for production.
void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Teal/cyan background (#0891b2) - "Already Done" brand color
  final bgColor = img.ColorRgb8(8, 145, 178);
  img.fill(image, color: bgColor);

  // Draw a simple white "A" shape using filled rectangles
  final fgColor = img.ColorRgb8(255, 255, 255);
  final cx = size ~/ 2;
  final cy = size ~/ 2;
  const w = 70;
  const h = 280;

  // Left vertical bar
  img.fillRect(image, x1: cx - h, y1: cy - h, x2: cx - h + w, y2: cy + h, color: fgColor);
  // Right vertical bar
  img.fillRect(image, x1: cx + h - w, y1: cy - h, x2: cx + h, y2: cy + h, color: fgColor);
  // Crossbar
  img.fillRect(image, x1: cx - h, y1: cy - 40, x2: cx + h, y2: cy + 40, color: fgColor);

  final dir = Directory('assets/icon');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final file = File('assets/icon/app_icon.png');
  file.writeAsBytesSync(img.encodePng(image));
  print('Generated ${file.path}');
}
