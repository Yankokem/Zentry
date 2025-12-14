import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';

/// Upload type enum to specify which preset to use
enum CloudinaryUploadType {
  accountPhoto,
  journalImage,
  projectImage,
  wishlistImage,
  bugReport,
  accountAppeal,
}

class CloudinaryService {
  // Singleton pattern
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // Your Cloudinary cloud name
  static const String _cloudName = 'dg1cz2twr';

  // Upload presets for different image types
  // These names must match EXACTLY with your Cloudinary dashboard presets
  static const Map<CloudinaryUploadType, String> _uploadPresets = {
    CloudinaryUploadType.accountPhoto: 'zentry_accounts_photos',
    CloudinaryUploadType.journalImage: 'zentry_journal_images',
    CloudinaryUploadType.projectImage: 'zentry_project_images',
    CloudinaryUploadType.wishlistImage: 'zentry_wishlist_images',
    CloudinaryUploadType.bugReport: 'zentry_bug_reports',
    CloudinaryUploadType.accountAppeal: 'zentry_account_appeal',
  };

  late final Map<CloudinaryUploadType, CloudinaryPublic> _cloudinaryInstances;

  void initialize() {
    // Initialize a CloudinaryPublic instance for each upload type
    _cloudinaryInstances = {};
    for (var entry in _uploadPresets.entries) {
      _cloudinaryInstances[entry.key] = CloudinaryPublic(
        _cloudName,
        entry.value,
        cache: false,
      );
    }
  }

  /// Upload an image file to Cloudinary
  /// 
  /// [file] - The image file to upload
  /// [uploadType] - The type of upload (determines which preset to use)
  /// 
  /// Returns the secure URL of the uploaded image
  /// 
  /// Note: For unsigned presets, do not specify publicId or folder.
  /// Cloudinary will auto-generate unique IDs and use preset folder settings.
  /// Upload an image file to Cloudinary
  /// 
  /// [file] - The image file to upload
  /// [uploadType] - The type of upload (determines which preset to use)
  /// 
  /// Returns the secure URL of the uploaded image
  Future<String> uploadImage(
    File file, {
    required CloudinaryUploadType uploadType,
  }) async {
    try {
      final cloudinary = _cloudinaryInstances[uploadType];
      if (cloudinary == null) {
        throw Exception('CloudinaryService not initialized. Call initialize() first.');
      }

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      throw Exception('Cloudinary error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Upload an XFile (from image_picker) to Cloudinary
  /// Supports both Web and Mobile
  Future<String> uploadXFile(
    dynamic xfile, { // Using dynamic to avoid importing image_picker if not needed, but ideally should be XFile
    required CloudinaryUploadType uploadType,
  }) async {
    try {
      final cloudinary = _cloudinaryInstances[uploadType];
      if (cloudinary == null) {
        throw Exception('CloudinaryService not initialized. Call initialize() first.');
      }

      CloudinaryFile cloudinaryFile;
      
      // Check if it's web or if we need to use bytes
      // We assume xfile is XFile from image_picker
      if (xfile.runtimeType.toString().contains('XFile')) {
        final bytes = await xfile.readAsBytes();
        cloudinaryFile = CloudinaryFile.fromByteData(
          ByteData.view(bytes.buffer),
          identifier: xfile.name,
          resourceType: CloudinaryResourceType.Image,
        );
      } else {
        // Fallback for File or other types
        // If it's File (dart:io), use path
        cloudinaryFile = CloudinaryFile.fromFile(
          xfile.path,
          resourceType: CloudinaryResourceType.Image,
        );
      }

      final response = await cloudinary.uploadFile(cloudinaryFile);
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      throw Exception('Cloudinary error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image to Cloudinary: $e');
    }
  }

  /// Delete an image from Cloudinary
  /// 
  /// Note: The cloudinary_public package doesn't support deletion.
  /// For deletion, you'll need to use the Cloudinary Admin API or dashboard.
  /// This method is kept for interface completeness but currently does nothing.
  Future<void> deleteImage(String publicId) async {
    // Deletion requires admin API access which cloudinary_public doesn't provide
    // You can either:
    // 1. Delete manually from Cloudinary dashboard
    // 2. Implement deletion using HTTP calls to Cloudinary Admin API
    // 3. Set up auto-delete policies in your Cloudinary account
    throw UnimplementedError(
      'Image deletion requires Cloudinary Admin API. Please delete manually from dashboard.',
    );
  }

  /// Extract public ID from Cloudinary URL
  /// 
  /// Example: https://res.cloudinary.com/cloud_name/image/upload/v123456/folder/image_id.jpg
  /// Returns: folder/image_id
  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }
      
      // Get segments after 'upload' and version (v123456)
      final relevantSegments = pathSegments.skip(uploadIndex + 2).toList();
      
      // Join and remove file extension
      final publicIdWithExt = relevantSegments.join('/');
      final lastDotIndex = publicIdWithExt.lastIndexOf('.');
      
      if (lastDotIndex != -1) {
        return publicIdWithExt.substring(0, lastDotIndex);
      }
      
      return publicIdWithExt;
    } catch (e) {
      return null;
    }
  }
}
