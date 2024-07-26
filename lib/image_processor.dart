import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:model_testing/face_cropper.dart';
import 'dart:developer' as devtools;

class ImageProcessor {
  File? filePath;
  String label = '';
  double confidence = 0.0;

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
        enableClassification: true, // Needed for eye open probabilities
        enableContours: true // Needed for mouth open detection
    ),
  );

  Future<void> initModel() async {
    String? res = await Tflite.loadModel(
        model: "assets/ml/model_unquant.tflite",
        labels: "assets/ml/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false
    );
    devtools.log(res ?? 'Model not loaded');
  }

  Future<void> pickImageFromCamera(Function(File, String, double) onImageProcessed) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    var imageFile = File(image.path);
    await _processImage(imageFile, onImageProcessed);
  }

  Future<void> pickImageFromGallery(Function(File, String, double) onImageProcessed) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    var imageFile = File(image.path);
    await _processImage(imageFile, onImageProcessed);
  }

  Future<void> _processImage(File imageFile, Function(File, String, double) onImageProcessed) async {
    String result = "No face detected";

    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      onImageProcessed(imageFile, result, 0.0);
      return;
    }

    final face = faces.first;
    final croppedFile = await FaceCropper.cropFace(imageFile, face);

    if (croppedFile == null) {
      devtools.log('Error cropping face');
      return;
    }

    var recognitions = await Tflite.runModelOnImage(
        path: croppedFile.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 2,
        threshold: 0.2,
        asynch: true
    );

    if (recognitions == null) {
      devtools.log("recognitions is Null");
      return;
    }
    devtools.log(recognitions.toString());

    double confidence = (recognitions[0]['confidence'] * 100);
    result = recognitions[0]['label'].toString();

    if (isMouthOpen(face, result, confidence)) {
      result = "Mouth is open";
      onImageProcessed(imageFile, result, 0.0);
      return;
    } else {
      final leftEyeOpenProb = face.leftEyeOpenProbability;
      final rightEyeOpenProb = face.rightEyeOpenProbability;

      if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
        if (leftEyeOpenProb < 0.5 && rightEyeOpenProb < 0.5) {
          result = "Both eyes closed";
          onImageProcessed(imageFile, result, 0.0);
          return;
        } else if (leftEyeOpenProb < 0.5) {
          result = "Left eye blinked";
          onImageProcessed(imageFile, result, 0.0);
          return;
        } else if (rightEyeOpenProb < 0.5) {
          result = "Right eye blinked";
          onImageProcessed(imageFile, result, 0.0);
          return;
        }
      }
    }

    onImageProcessed(imageFile, result, confidence);
  }

  bool isMouthOpen(Face face, modelLabel, modelConfidence) {
    final topMouthLip = face.contours[FaceContourType.upperLipTop];
    final bottomMouthLip = face.contours[FaceContourType.lowerLipBottom];

    if (topMouthLip != null && bottomMouthLip != null) {
      final topPoint = topMouthLip.points.first;
      final bottomPoint = bottomMouthLip.points.last;
      final distance = (topPoint.y - bottomPoint.y).abs();

      devtools.log("Mouth distance: $distance");

      if ((modelLabel == "0 duckface" && modelConfidence > 0 && distance > 5) || (distance > 100)) {
        return true;
      }
    }
    return false;
  }

  void dispose() {
    Tflite.close();
  }
}
