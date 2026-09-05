// screens/wallet_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget
import 'dart:io';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  bool _showBankDetails = false;
  File? _screenshotFile;
  final ImagePicker _picker = ImagePicker();
  
  // Dummy QR Code image path
  final String qrCodeImage = 'assets/qr_scanner.png';

  // Balance state - you can manage this with provider or bloc in production
  double _balance = 1000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card - Reused from widgets
            BalanceCard(
              balance: _balance,
              showRechargeButton: false, // Hide recharge button in wallet page
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              borderRadius: AppDimens.borderRadiusMedium,
            ),
            
            const SizedBox(height: 24),
            
            // QR Code Scanner Section
            _buildQRCodeSection(),
            
            const SizedBox(height: 16),
            
            // I have paid button
            _buildPaidButton(),
            
            const SizedBox(height: 16),
            
            // Bank Details Form (Hidden by default)
            _buildBankDetailsForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(0.15),
            AppColors.secondaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Scan to Recharge',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan the QR code below to recharge your wallet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // QR Code Image Container
          Container(
            width: 280,
            height: 404,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                qrCodeImage,
                width: 280,
                height: 404,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 60,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'QR Code\n(Add image to assets)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recharge Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scan the QR code using any UPI app to make payment',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _showBankDetails = !_showBankDetails;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(
          _showBankDetails ? 'Hide Details' : 'I have paid',
          style: const TextStyle(
            color: Color.fromARGB(255, 213, 208, 208),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetailsForm() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showBankDetails ? null : 0,
      child: _showBankDetails
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.15),
                    AppColors.secondaryGreen.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Upload Screenshot Button
                  _buildUploadScreenshotButton(),
                  
                  const SizedBox(height: 16),
                  
                  // IFSC Code Field
                  TextField(
                    controller: _ifscController,
                    style: const TextStyle(
                      color: AppColors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      hintText: 'Enter IFSC code',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.account_balance,
                        color: AppColors.primaryGreen,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bank Account Number Field
                  TextField(
                    controller: _accountController,
                    style: const TextStyle(
                      color: AppColors.white,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Bank Account Number',
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      hintText: 'Enter bank account number',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.credit_card,
                        color: AppColors.primaryGreen,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _submitBankDetails();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildUploadScreenshotButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Upload Button
          InkWell(
            onTap: () {
              _showImagePickerOptions();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _screenshotFile != null ? 'Change Screenshot' : 'Upload Payment Screenshot',
                    style: TextStyle(
                      color: _screenshotFile != null ? AppColors.primaryGreen : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Show uploaded file name and preview
          if (_screenshotFile != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Screenshot uploaded: ${_screenshotFile!.path.split('/').last}',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Upload Screenshot',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryGreen,
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: AppColors.white),
                ),
                subtitle: const Text(
                  'Open camera to take a photo',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryGreen,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.white),
                ),
                subtitle: const Text(
                  'Select from file manager',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() {
          _screenshotFile = File(photo.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _screenshotFile = File(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitBankDetails() {
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload payment screenshot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_ifscController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter IFSC code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter bank account number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admit will update your wallet amount shortly',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your transaction is being processed. You will receive a notification once it is complete.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _ifscController.clear();
                _accountController.clear();
                setState(() {
                  _showBankDetails = false;
                  _screenshotFile = null;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _ifscController.dispose();
    _accountController.dispose();
    super.dispose();
  }
}