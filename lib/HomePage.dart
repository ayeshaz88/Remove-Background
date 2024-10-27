import 'dart:io';
import 'dart:typed_data';
import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:sticker_view/stickerview.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? imageFile;
  Uint8List? backgroundRemovedImage;
  String? imagePath;
  String? selectedBackground;
  ScreenshotController controller = ScreenshotController();
  List<Sticker> stickers = [];

  // List of predefined stickers
  final List<String> stickerAssets = [
    'assets/images/w1.png',
    'assets/images/w2.png',
    'assets/images/w3.png',
  ];

  // Pick an image from the gallery for background removal
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
  // Add stickers from assets

  void _selectSticker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Sticker'),
          content: SingleChildScrollView(
            child: Column(
              children: stickerAssets.map((sticker) {
                return GestureDetector(
                  onTap: () {
                    _addSticker(sticker);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      sticker,
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

  // Apply the selected sticker as draggable and resizable in the background
  void _addSticker(String stickerPath) {
    final newSticker = Sticker(
      id: "sticker_${stickers.length}",
      child: Image.asset(
        stickerPath,
        width: 100,
        height: 100,
      ),
      // Add functionality for resizing
      isText: false, // Set to true if you're using text stickers
    );

    setState(() {
      stickers.add(newSticker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sticker'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display the image with the selected spiral
              (backgroundRemovedImage != null && selectedBackground != null)
                  ? Screenshot(
                      controller: controller,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.memory(
                            backgroundRemovedImage!,
                            fit: BoxFit.contain,
                          ),
                          StickerView(
                            stickerList: stickers, // Use the list of stickers
                          ),
                        ],
                      ),
                    )
                  : (backgroundRemovedImage != null)
                      ? Image.memory(
                          backgroundRemovedImage!,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.6,
                          fit: BoxFit.contain,
                        )
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
                      backgroundColor: Colors.red,
                      child: Icon(Icons.edit),
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: () {
                        if (imageFile != null) {
                          _removeBackground(); // Remove background
                        }
                      },
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.delete),
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      onPressed: () {
                          _selectSticker();
                      },
                      backgroundColor: Colors.green,
                      child: Icon(Icons.animation),
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
                              content: Text("Please select a sticker first."),
                            ),
                          );
                        }
                      },
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.save_alt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
}
