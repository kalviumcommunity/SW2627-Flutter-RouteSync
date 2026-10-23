import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  StorageService({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<String> uploadProofBytes({
    required String deliveryId,
    required Uint8List bytes,
    required String contentType,
    String extension = 'jpg',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated user is required to upload proof.');
    }
    if (!contentType.startsWith('image/')) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Proof must be an image.',
      );
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError.value(
        bytes.length,
        'bytes',
        'Proof must be between 1 byte and 10 MB.',
      );
    }

    final reference = _storage.ref(
      'deliveries/$deliveryId/proof-${user.uid}.$extension',
    );
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }
}
