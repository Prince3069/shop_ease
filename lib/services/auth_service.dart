import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _userModel;
  Stream<UserModel?> get user =>
      _auth.authStateChanges().asyncMap(_userFromFirebase);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to convert Firebase User to UserModel
  Future<UserModel?> _userFromFirebase(User? user) async {
    if (user == null) {
      _userModel = null;
      return null;
    }

    // Get user document from Firestore
    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      _userModel = UserModel.fromMap(doc.data()!, doc.id);
      return _userModel;
    } else {
      // Create user document if it doesn't exist
      final newUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      _userModel = newUser;
      return newUser;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setError(null);
      _userModel = await _userFromFirebase(userCredential.user);
      return _userModel;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user in Firestore
      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      _setError(null);
      _userModel = newUser;
      return newUser;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    String? phoneNumber,
    String? address,
  }) async {
    if (_userModel == null) return;

    _setLoading(true);
    try {
      final updatedUser = _userModel!.copyWith(
        name: name,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        address: address,
      );

      await _firestore
          .collection('users')
          .doc(_userModel!.id)
          .update(updatedUser.toMap());

      // Update display name in Firebase Auth
      if (name != null) {
        await _auth.currentUser?.updateDisplayName(name);
      }

      // Update photo URL in Firebase Auth
      if (photoUrl != null) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }

      _userModel = updatedUser;
      _setError(null);
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } finally {
      _setLoading(false);
    }
  }

  // Add to wishlist
  Future<void> toggleWishlistItem(String productId) async {
    if (_userModel == null) return;

    _setLoading(true);
    try {
      List<String> updatedWishlist = [..._userModel!.wishlist];

      if (updatedWishlist.contains(productId)) {
        updatedWishlist.remove(productId);
      } else {
        updatedWishlist.add(productId);
      }

      final updatedUser = _userModel!.copyWith(wishlist: updatedWishlist);

      await _firestore
          .collection('users')
          .doc(_userModel!.id)
          .update({'wishlist': updatedWishlist});

      _userModel = updatedUser;
      _setError(null);
    } catch (e) {
      _setError('Failed to update wishlist: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for state management
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'email-already-in-use':
        message = 'The email address is already in use.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      default:
        message = e.message ?? 'An unknown error occurred.';
    }
    _setError(message);
  }
}
