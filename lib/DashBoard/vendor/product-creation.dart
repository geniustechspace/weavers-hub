import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class VendorProductCreation extends StatefulWidget {
  const VendorProductCreation({Key? key}) : super(key: key);

  @override
  _VendorProductCreationState createState() => _VendorProductCreationState();
}

class _VendorProductCreationState extends State<VendorProductCreation> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();
  final storage = FirebaseStorage.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool _isLoading = false;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadProductData(
      String name, int quantity, String description, double price) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      DocumentReference productRef =
          FirebaseFirestore.instance.collection('products').doc();

      Map<String, dynamic> productData = {
        'userId': user.uid,
        'sellerEmail': user.email,
        'name': name,
        'quantity': quantity,
        'description': description,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_image != null) {
        final ref = storage.ref().child('product_images/${productRef.id}');
        await ref.putFile(_image!);
        final url = await ref.getDownloadURL();
        productData['image_url'] = url;
      }

      await productRef.set(productData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully!')),
      );
      Get.back();

      _formKey.currentState!.reset();
      setState(() {
        _image = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating product: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Create Product', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green, Colors.green, Colors.white],
                  stops: [0.0, 0.3, 0.3],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Product Details',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                                const SizedBox(height: 20),
                                _buildTextField('Product Name', nameController,
                                    Icons.shopping_bag),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    'Product Quantity',
                                    quantityController,
                                    Icons.format_list_numbered),
                                const SizedBox(height: 15),
                                _buildTextField('Product Description',
                                    descriptionController, Icons.description,
                                    isDescription: true),
                                const SizedBox(height: 15),
                                _buildTextField('Product Price',
                                    priceController, Icons.attach_money),
                                const SizedBox(height: 20),
                                _buildImageUpload(),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate() &&
                                        !_isLoading) {
                                      final name = nameController.text;
                                      final description =
                                          descriptionController.text;
                                      final parsedQuantity =
                                          int.tryParse(quantityController.text);
                                      final parsedPrice =
                                          double.tryParse(priceController.text);

                                      if (parsedQuantity == null ||
                                          parsedPrice == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please enter valid quantity and price')),
                                        );
                                        return;
                                      }
                                      _uploadProductData(name, parsedQuantity,
                                          description, parsedPrice);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Create Product',
                                      style: TextStyle(fontSize: 18,color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool isDescription = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Product Quantity' && int.tryParse(value) == null) {
          return 'Please enter a valid integer';
        }
        if (label == 'Product Price' && double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
      keyboardType: label == 'Product Quantity' || label == 'Product Price'
          ? TextInputType.number
          : TextInputType.text,
      maxLines: isDescription ? 3 : 1,
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Product Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: getImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: _image == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Tap to upload your product image!',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
}
