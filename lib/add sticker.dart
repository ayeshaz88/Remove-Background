import 'dart:io';
import 'dart:typed_data';
import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sticker_view/stickerview.dart';

class Add extends StatefulWidget {
  @override
  _AddState createState() => new _AddState();
}

class _AddState extends State<Add> {
  Uint8List? imageFile;
  Uint8List? backgroundRemovedImage;
  String? selectedBackground;
  ScreenshotController controller = ScreenshotController();

  // List of predefined background images
  final List<String> _backgroundImages = [
    'assets/images/w1.png',
    'assets/images/w2.png',
    'assets/images/w3.png',
  ];

  // List to hold stickers
  List<Sticker> stickers = [];

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
                  // StickerView to manage stickers
                  StickerView(
                    stickerList: [
                      // Add the selected background as a sticker
                      if (selectedBackground != null)
                        Sticker(
                          id: "background_sticker",
                          child: Image.asset(
                            selectedBackground!,
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.6,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ]..addAll(stickers), // Add foreground stickers
                  ),
                  Image.memory(
                    backgroundRemovedImage!,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.55,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
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
            const SizedBox(height: 50),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.edit),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (imageFile != null) {
                        _removeBackground(); // Remove background
                      }
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.delete_forever),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (backgroundRemovedImage != null) {
                        _selectBackground(); // Select background after removing it
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please remove the background first.")),
                        );
                      }
                    },
                    backgroundColor: Colors.yellow,
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () {
                      if (selectedBackground != null && backgroundRemovedImage != null) {
                        _saveImage(); // Call the save image function
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select a background first.")),
                        );
                      }
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.download_for_offline_sharp),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.extended(
                    onPressed: () {},
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    label: const Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.more_horiz, size: 28),
                        SizedBox(height: 2),
                        Text(
                          'More',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
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
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/edited_image.jpg';

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

      // Add the selected background as a sticker
      stickers.add(Sticker(
        id: "background_sticker",
        child: Image.asset(
          bgImagePath,
          fit: BoxFit.cover,
        ),
      ));
    });
  }
}
