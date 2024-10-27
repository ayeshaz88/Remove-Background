import 'dart:io';
import 'dart:typed_data';
import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'ImagePicker.dart';
import 'SpiralBackground.dart';
import 'HomePage.dart';
import 'add sticker.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RemoveBackground(),
    ),
  );
}

class RemoveBackground extends StatefulWidget {
  @override
  _RemoveBackgroundState createState() => new _RemoveBackgroundState();

  removeBackgroundFromFile(File file) {}
}

class _RemoveBackgroundState extends State<RemoveBackground> {
  final Future<ByteData> data = rootBundle.load('assets/images/img.jpeg');

  final Uint8List image =
      Uint8List.fromList([]); // Replace with actual image data
  Uint8List? imageFile;
  Uint8List? backgroundRemovedImage;
  String? imagePath;
  String? selectedBackground;
  ScreenshotController controller = ScreenshotController();

  // List of predefined background images
  final List<String> _backgroundImages = [
    'assets/images/b1.jpg',
    'assets/images/b2.jpg',
    'assets/images/b3.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Background'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            (backgroundRemovedImage != null)
                ? Screenshot(
                    controller: controller,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (selectedBackground != null)
                          Image.asset(
                            selectedBackground!,
                            width: MediaQuery.of(context)
                                .size
                                .width, // Set background width to screen width
                            height: MediaQuery.of(context).size.height *
                                0.6, // Adjust height to 60% of screen height
                            fit: BoxFit
                                .cover, // This will cover the container fully, scaling as needed
                          ),
                        Image.memory(
                          backgroundRemovedImage!,
                          width: MediaQuery.of(context).size.width *
                              0.8, // Slightly reduce foreground width to 80% of screen
                          height: MediaQuery.of(context).size.height *
                              0.55, // Adjust foreground height to slightly less than background
                          fit: BoxFit
                              .contain, // This will contain the foreground image, maintaining its aspect ratio
                        ),
                      ],
                    ),
                  )
                : (imageFile != null)
                    ? Image.memory(
                        imageFile!,
                        width: MediaQuery.of(context)
                            .size
                            .width, // Adjust width to fit the screen
                        height: MediaQuery.of(context).size.height *
                            0.6, // Adjust height
                        fit: BoxFit.contain,
                      )
                    : Container(
                        width: MediaQuery.of(context)
                            .size
                            .width, // Adjust width to fit the screen
                        height: MediaQuery.of(context).size.height *
                            0.6, // Adjust height
                        color: Colors.grey[300]!,
                        child: const Icon(
                          Icons.image,
                          size: 100,
                        ),
                      ),
            const SizedBox(height: 50),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    backgroundColor: Colors.red, // Set the color to red
                    child: const Icon(Icons.edit), // Use the edit icon
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (imageFile != null) {
                        _removeBackground(); // Remove background
                      }
                    },
                    backgroundColor: Colors.blue, // Set the color to red
                    child: const Icon(Icons.delete_forever), // Use the edit icon
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (backgroundRemovedImage != null) {
                        _selectBackground(); // Select background after removing it
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please remove the background first.")),
                        );
                      }
                    },
                    backgroundColor: Colors.yellow, // Set the color to red
                    child: const Icon(Icons.add_a_photo_outlined), // Use the edit icon
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (selectedBackground != null &&
                          backgroundRemovedImage != null) {
                        _saveImage(); // Call the save image function
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Please select a background first.")),
                        );
                      }
                    },
                    backgroundColor: Colors.green, // Set the color to red
                    child: const Icon(Icons.download_for_offline_sharp), // Use the edit icon
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.extended(
                    onPressed: () {
                      _showBottomSheet(context);
                    },
                    backgroundColor: Colors.red, // Set the button color to red
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          16), // Optional: Customize button shape
                    ),
                    label: const Column(
                      mainAxisSize: MainAxisSize.min, // Minimize vertical space
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.more_horiz, size: 28), // Icon above the text
                        SizedBox(height: 2), // Space between icon and text
                        Text(
                          'More',
                          style:
                              TextStyle(fontSize: 16), // Customize text style
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          title: const Text('Select a Background'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _backgroundImages.map((bgImage) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _applyBackground(bgImage); // Apply the selected background
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
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
      final directory =
          await getTemporaryDirectory(); // Get temporary directory
      final path = '${directory.path}/edited_image.jpg'; // Temporary file path

      // Capture the screenshot
      controller.capture().then((Uint8List? image) async {
        if (image != null) {
          // Save the captured image to a file
          final file = File(path);
          await file.writeAsBytes(image);

          // Save the file to the gallery
          await GallerySaver.saveImage(file.path);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image saved to gallery.")),
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

void _showBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.waves),
                title: const Text('Spiral Background'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SpiralBackground()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cameraswitch_rounded),
                title: const Text('Round Spiral'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ImagePickerScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drag_indicator_rounded),
                title: const Text('Sticker View'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
