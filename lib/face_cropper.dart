import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceCropper {
  static Future<File?> cropFace(File imageFile, Face face) async {
    // Read the image file
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) return null;

    // Calculate the bounding box of the face
    final boundingBox = face.boundingBox;

    // Crop the image around the face
    final croppedImage = img.copyCrop(
      image,
      boundingBox.left.toInt(),
      boundingBox.top.toInt(),
      boundingBox.width.toInt(),
      boundingBox.height.toInt(),
    );

    // Save the cropped image to a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_face.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(croppedImage));

    return tempFile;
  }
}