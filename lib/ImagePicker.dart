import 'dart:io';
import 'dart:typed_data';
import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'SpiralPainter.dart';

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _image;
  Uint8List? _backgroundRemovedImage;
  final picker = ImagePicker();

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _backgroundRemovedImage = null; // Reset the removed background when a new image is selected
      });
    }
  }

  // Function to remove background from the selected image
  Future<void> _removeBackground() async {
    if (_image != null) {
      final imageBytes = await _image!.readAsBytes(); // Get image as bytes
      try {
        final result = await removeBackground(imageBytes: imageBytes);
        setState(() {
          _backgroundRemovedImage = result; // Set the image with the background removed
        });
      } catch (e) {
        print("Error removing background: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove background.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Image'),
        backgroundColor: Colors.teal,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the original or background removed image
            if (_backgroundRemovedImage != null)
              Image.memory(_backgroundRemovedImage!, width: 150, height: 150)
            else if (_image != null)
              Image.file(_image!, width: 150, height: 150),

            SizedBox(height: 20),

            // Button to pick an image from the gallery
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image from Gallery'),
            ),

            if (_image != null && _backgroundRemovedImage == null) ...[
              // Button to remove background (only visible after image selection)
              ElevatedButton(
                onPressed: _removeBackground,
                child: Text('Remove Background'),
              ),
            ],

            if (_backgroundRemovedImage != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpiralPage(
                        imageFile: File(''), // pass the imageFile if needed
                        backgroundRemovedImage: _backgroundRemovedImage,
                      ),
                    ),
                  );
                },
                child: Text('Add Spiral to Image'),
              ),
          ],
        ),
      ),
    );
  }
}
