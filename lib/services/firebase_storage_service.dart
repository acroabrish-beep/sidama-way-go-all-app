import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/logger.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload photo bytes to Firebase Storage (web and mobile compatible)
  /// 
  /// Parameters:
  /// - [bytes]: The image bytes to upload
  /// - [firebaseUid]: The user's Firebase UID for organizing uploads
  /// - [contentType]: MIME type of the image (default: image/jpeg)
  /// - [category]: Optional category for organizing uploads (e.g., 'citizen_reports', 'profile')
  /// 
  /// Returns: The public download URL of the uploaded file
  /// 
  /// Throws: Exception if upload fails or user is not authenticated
  Future<String> uploadPhotoBytes({
    required Uint8List bytes,
    required String firebaseUid,
    String contentType = 'image/jpeg',
    String category = 'citizen_reports',
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Generate file path: citizen_reports/{firebase_uid}/{timestamp}.jpg
      final fileName = '$timestamp.jpg';
      final storagePath = '$category/$firebaseUid/$fileName';
      
      AppLogger.info('Uploading photo bytes to Firebase Storage: $storagePath');
      AppLogger.info('Storage bucket: ${_storage.bucket}');
      
      // Set max retry time to 15 seconds
      _storage.setMaxUploadRetryTime(const Duration(seconds: 15));
      
      // Create reference to the file location
      final ref = _storage.ref().child(storagePath);
      
      // Upload the bytes with metadata, with 30 second timeout
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      ).timeout(const Duration(seconds: 30));
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Check for errors during upload
      if (snapshot.state == TaskState.error) {
        throw Exception('Upload failed. Please try again.');
      }
      
      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      
      AppLogger.info('Photo uploaded successfully - URL length: ${downloadUrl.length} chars');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error - code: ${e.code}, message: ${e.message}', error: e);
      throw Exception('Storage error (${e.code}): ${e.message}');
    } catch (e) {
      AppLogger.error('Photo upload failed', error: e);
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  /// Upload a photo (from camera or gallery) to Firebase Storage (mobile only)
  /// 
  /// Parameters:
  /// - [file]: The image file to upload (from camera or gallery)
  /// - [category]: Optional category for organizing uploads (e.g., 'citizen_reports', 'profile')
  /// 
  /// Returns: The public download URL of the uploaded file
  /// 
  /// Throws: Exception if upload fails or user is not authenticated
  /// 
  /// Note: This method uses dart:io File and is not compatible with Flutter Web.
  /// Use uploadPhotoBytes for web compatibility.
  Future<String> uploadPhoto({
    required File file,
    String category = 'citizen_reports',
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final firebaseUid = user.uid;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Generate file path: citizen_reports/{firebase_uid}/{timestamp}.jpg
      final fileName = '$timestamp.jpg';
      final storagePath = '$category/$firebaseUid/$fileName';
      
      AppLogger.info('Uploading photo to Firebase Storage: $storagePath');
      
      // Create reference to the file location
      final ref = _storage.ref().child(storagePath);
      
      // Upload the file
      final uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Check for errors during upload
      if (snapshot.state == TaskState.error) {
        throw Exception('Upload failed. Please try again.');
      }
      
      // Get the download URL
      final downloadUrl = await ref.getDownloadURL();
      
      AppLogger.info('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error', error: e);
      throw Exception('Storage error: ${e.message}');
    } catch (e) {
      AppLogger.error('Photo upload failed', error: e);
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  /// Delete a file from Firebase Storage
  /// 
  /// Parameters:
  /// - [downloadUrl]: The download URL of the file to delete
  /// 
  /// Returns: true if deletion was successful
  /// 
  /// Throws: Exception if deletion fails
  Future<bool> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      
      AppLogger.info('Photo deleted successfully: $downloadUrl');
      return true;
      
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage deletion error', error: e);
      throw Exception('Storage deletion error: ${e.message}');
    } catch (e) {
      AppLogger.error('Photo deletion failed', error: e);
      throw Exception('Failed to delete photo: ${e.toString()}');
    }
  }

  /// Get the file size of an image before upload
  /// 
  /// Parameters:
  /// - [file]: The image file
  /// 
  /// Returns: File size in bytes
  int getFileSize(File file) {
    return file.lengthSync();
  }

  /// Validate image bytes before upload (web and mobile compatible)
  /// 
  /// Parameters:
  /// - [bytes]: The image bytes to validate
  /// - [fileName]: The file name to check extension
  /// - [maxSizeBytes]: Maximum allowed file size (default: 10MB)
  /// 
  /// Returns: true if file is valid
  /// 
  /// Throws: Exception if file is invalid
  Future<bool> validateImageBytes({
    required Uint8List bytes,
    required String fileName,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
  }) async {
    try {
      // Check file size
      if (bytes.length > maxSizeBytes) {
        throw Exception('File size exceeds maximum allowed size of ${maxSizeBytes / (1024 * 1024)}MB');
      }

      // Check file extension
      final lowerFileName = fileName.toLowerCase();
      if (!lowerFileName.endsWith('.jpg') && 
          !lowerFileName.endsWith('.jpeg') && 
          !lowerFileName.endsWith('.png')) {
        throw Exception('Only JPG, JPEG, and PNG files are allowed');
      }

      return true;
      
    } catch (e) {
      AppLogger.error('Image validation failed', error: e);
      rethrow;
    }
  }

  /// Validate image file before upload (mobile only)
  /// 
  /// Parameters:
  /// - [file]: The image file to validate
  /// - [maxSizeBytes]: Maximum allowed file size (default: 10MB)
  /// 
  /// Returns: true if file is valid
  /// 
  /// Throws: Exception if file is invalid
  /// 
  /// Note: This method uses dart:io File and is not compatible with Flutter Web.
  /// Use validateImageBytes for web compatibility.
  Future<bool> validateImageFile({
    required File file,
    int maxSizeBytes = 10 * 1024 * 1024, // 10MB default
  }) async {
    try {
      // Check file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Check file size
      final fileSize = getFileSize(file);
      if (fileSize > maxSizeBytes) {
        throw Exception('File size exceeds maximum allowed size of ${maxSizeBytes / (1024 * 1024)}MB');
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      if (!fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png')) {
        throw Exception('Only JPG, JPEG, and PNG files are allowed');
      }

      return true;
      
    } catch (e) {
      AppLogger.error('Image validation failed', error: e);
      rethrow;
    }
  }
}
