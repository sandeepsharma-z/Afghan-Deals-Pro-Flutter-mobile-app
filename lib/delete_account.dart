import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteAccountService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Delete user account and all associated data
  static Future<void> deleteUserAccount(String userId) async {
    try {
      final batch = _firestore.batch();

      // 1. Delete user profile
      batch.delete(_firestore.collection('users').doc(userId));

      // 2. Delete all listings by this user
      final listings = await _firestore
          .collection('listings')
          .where('seller_id', isEqualTo: userId)
          .get();
      for (var doc in listings.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete all chats with this user
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in chats.docs) {
        batch.delete(doc.reference);
      }

      // 4. Delete all favorites
      batch.delete(_firestore.collection('favorites').doc(userId));

      // 5. Commit batch
      await batch.commit();

      // 6. Delete Firebase Auth user
      await _auth.currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}
