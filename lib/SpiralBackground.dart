import 'dart:io';
import 'dart:typed_data';
import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class SpiralBackground extends StatefulWidget {
  @override
  _SpiralBackgroundState createState() => new _SpiralBackgroundState();
}

class _SpiralBackgroundState extends State<SpiralBackground> {
  Uint8List? imageFile;
  Uint8List? backgroundRemovedImage;
  String? imagePath;
  String? selectedBackground;
  ScreenshotController controller = ScreenshotController();

  // List of predefined background spirals
  final List<String> _backgroundImages = [
    'assets/images/s1.png',
    'assets/images/s2.png',
    'assets/images/s3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiral Effect on Image'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Display the image with the selected spiral
            (backgroundRemovedImage != null && selectedBackground != null)
                ? Screenshot(
              controller: controller,
              child: Stack(
                alignment: Alignment.center,
                children: _buildSpiralLayers(), // Spiral effect layers
              ),
            )
            // If the background is removed but spiral is not selected yet
                : (backgroundRemovedImage != null)
                ? Image.memory(
              backgroundRemovedImage!,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              fit: BoxFit.contain,
            )
            // If no image is selected or background is not removed
                : (imageFile != null)
                ? Image.memory(
              imageFile!,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              fit: BoxFit.contain,
            )
                : Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              color: Colors.grey[300]!,
              child: const Icon(
                Icons.image,
                size: 100,
              ),
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    backgroundColor: Colors.red, // Set the color to red
                    child: Icon(Icons.edit), // Use the edit icon
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (imageFile != null) {
                        _removeBackground(); // Remove background
                      }
                    },
                    backgroundColor: Colors.blue, // Set the color to red
                    child: Icon(Icons.delete), // Use the edit icon
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (backgroundRemovedImage != null) {
                        _selectBackground(); // Select spiral background
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            Text("Please remove the background first."),
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.green, // Set the color to red
                    child: Icon(Icons.waves), // Use the edit icon
                  ),
                  SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () async {
                      if (selectedBackground != null &&
                          backgroundRemovedImage != null) {
                        _saveImage(); // Save image
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please select a background first."),
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.orange, // Set the color to red
                    child: Icon(Icons.save_alt), // Use the edit icon
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _buildSpiralLayers() {
    // Build the spiral layers alternating between back and front
    List<Widget> layers = [];

    // Add the spiral background behind the image
    if (selectedBackground != null) {
      layers.add(
        Positioned(
          child: Image.asset(
            selectedBackground!,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Add the user image in the center
    if (backgroundRemovedImage != null) {
      layers.add(
        Image.memory(
          backgroundRemovedImage!,
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.45,
          fit: BoxFit.contain,
        ),
      );
    }

    return layers;
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        imagePath = pickedImage.path;
        imageFile = await pickedImage.readAsBytes();
        setState(() {});
      }
    } catch (e) {
      imageFile = null;
      setState(() {});
    }
  }

  Future<void> _removeBackground() async {
    if (imageFile != null) {
      try {
        Uint8List result = await removeBackground(imageBytes: imageFile!);
        setState(() {
          backgroundRemovedImage = result;
        });
      } catch (e) {
        print("Error removing background: $e");
      }
    }
  }

  void _selectBackground() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a Spiral Background'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _backgroundImages.map((bgImage) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _applyBackground(
                        bgImage); // Apply the selected spiral background
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    child: Image.asset(
                      bgImage,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveImage() async {
    try {
      // Capture the widget using ScreenshotController
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/edited_image.jpg'; // Temporary file path

      controller.capture().then((Uint8List? image) async {
        if (image != null) {
          final file = File(path);
          await file.writeAsBytes(image);
          await GallerySaver.saveImage(file.path);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image saved to gallery.")),
          );
        }
      }).catchError((onError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving image: $onError")),
        );
      });
    } catch (e) {
      print("Error saving image: $e");
    }
  }

  void _applyBackground(String bgImagePath) {
    setState(() {
      selectedBackground = bgImagePath;
    });
  }
}
