import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService(this._auth);

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await _createUserDocument(credential.user!.uid, name, email);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
      String uid, String name, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'createdAt': Timestamp.now(),
      'profilePicture': '',
      'phoneNumber': '',
      'addresses': [],
      'wishlist': [],
    });
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    final doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final userRef = _firestore.collection('users').doc(currentUser!.uid);
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (profilePicture != null) updates['profilePicture'] = profilePicture;

    if (updates.isNotEmpty) {
      await userRef.update(updates);
    }
  }

  // Add address
  Future<void> addAddress(Map<String, dynamic> address) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final userRef = _firestore.collection('users').doc(currentUser!.uid);
    await userRef.update({
      'addresses': FieldValue.arrayUnion([address]),
    });
  }

  // Remove address
  Future<void> removeAddress(Map<String, dynamic> address) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final userRef = _firestore.collection('users').doc(currentUser!.uid);
    await userRef.update({
      'addresses': FieldValue.arrayRemove([address]),
    });
  }

  // Add product to wishlist
  Future<void> addToWishlist(String productId) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final userRef = _firestore.collection('users').doc(currentUser!.uid);
    await userRef.update({
      'wishlist': FieldValue.arrayUnion([productId]),
    });
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final userRef = _firestore.collection('users').doc(currentUser!.uid);
    await userRef.update({
      'wishlist': FieldValue.arrayRemove([productId]),
    });
  }

  // Handle Firebase Auth exceptions with more user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      case 'invalid-action-code':
        return 'The action code is invalid. This can happen if the code is malformed or has already been used.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
