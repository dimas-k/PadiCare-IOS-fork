import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/services/api_service.dart';

class ImageSection extends StatelessWidget {
  final bool isHistoryMode;
  final File? selectedImage;
  final String? historyImageFilename;
  final Future<String?>? historyImageUrlFuture;
  final DateTime? historyDate;
  final Color primaryColor;
  final Color accentColor;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback? onImageTap;

  const ImageSection({
    Key? key,
    required this.isHistoryMode,
    this.selectedImage,
    this.historyImageFilename,
    this.historyImageUrlFuture,
    this.historyDate,
    required this.primaryColor,
    required this.accentColor,
    required this.onCameraTap,
    required this.onGalleryTap,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (isHistoryMode && historyDate != null) _buildHistoryDateInfo(),
          _buildImageContainer(context),
          if (!isHistoryMode) _buildImagePickerButtons(),
        ],
      ),
    );
  }

  Widget _buildHistoryDateInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: primaryColor, size: 20),
          SizedBox(width: 8),
          Text(
            'Diagnosa pada ${DateFormat('dd MMMM yyyy, HH:mm').format(historyDate!)}',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContainer(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double imageHeight;
        if (isHistoryMode) {
          imageHeight = MediaQuery.of(context).size.height * 0.15;
          imageHeight = imageHeight.clamp(100.0, 160.0);
        } else if (selectedImage != null) {
          imageHeight = 120;
        } else {
          imageHeight = 200;
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: imageHeight,
          width: double.infinity,
          margin: EdgeInsets.all(16),
          child: isHistoryMode
              ? HistoryImageView(
                  imageUrlFuture: historyImageUrlFuture,
                  imageFilename: historyImageFilename ?? '',
                  primaryColor: primaryColor,
                  onTap: onImageTap,
                )
              : ImagePickerView(
                  selectedImage: selectedImage,
                  onTap: onImageTap,
                ),
        );
      },
    );
  }

  Widget _buildImagePickerButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCameraTap,
              icon: Icon(Icons.camera_alt, size: 18),
              label: Text('Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onGalleryTap,
              icon: Icon(Icons.photo_library, size: 18),
              label: Text('Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryImageView extends StatelessWidget {
  final Future<String?>? imageUrlFuture;
  final String imageFilename;
  final Color primaryColor;
  final VoidCallback? onTap;

  const HistoryImageView({
    Key? key,
    required this.imageUrlFuture,
    required this.imageFilename,
    required this.primaryColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: FutureBuilder<String?>(
          future: imageUrlFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingImage();
            }
            if (snapshot.hasData && snapshot.data != null) {
              return _buildNetworkImage(snapshot.data!);
            }
            return _buildPlaceholderImage();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat gambar riwayat...',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    // URL dari Supabase Storage sudah absolut (https). Jangan tambahkan baseUrl.
    final fullImageUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiService.baseUrl}$imageUrl';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingImage();
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 28,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Gambar Diagnosa',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - 24,
                ),
                child: Text(
                  imageFilename,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ImagePickerView extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback? onTap;

  const ImagePickerView({Key? key, this.selectedImage, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return selectedImage != null
        ? GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 48,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 8),
                Text(
                  'Tambahkan gambar daun padi',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'untuk diagnosa',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
  }
}
