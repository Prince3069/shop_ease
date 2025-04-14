import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_model.dart';

class CartService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CartModel _cart = CartModel();
  bool _isLoading = false;

  CartModel get cart => _cart;
  bool get isLoading => _isLoading;

  // Initialize cart from Firestore for logged in user
  Future<void> initCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot cartDoc =
            await _firestore.collection('carts').doc(user.uid).get();

        if (cartDoc.exists) {
          Map<String, dynamic> cartData =
              cartDoc.data() as Map<String, dynamic>;
          _cart.userId = user.uid;
          _cart.initFromFirestore(cartData['items'] ?? {});
        } else {
          _cart = CartModel();
          _cart.userId = user.uid;
        }
      } else {
        _cart = CartModel();
      }
    } catch (e) {
      print('Error initializing cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add item to cart
  Future<void> addToCart(
      String productId, String name, double price, String image) async {
    try {
      _cart.addItem(productId, name, price, image);
      await _saveCartToFirestore();
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      _cart.removeItem(productId);
      await _saveCartToFirestore();
    } catch (e) {
      print('Error removing from cart: $e');
    }
  }

  // Decrease item quantity
  Future<void> decreaseQuantity(String productId) async {
    try {
      _cart.decreaseQuantity(productId);
      await _saveCartToFirestore();
    } catch (e) {
      print('Error decreasing quantity: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      _cart.clear();
      await _saveCartToFirestore();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // Save cart to Firestore
  Future<void> _saveCartToFirestore() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('carts').doc(user.uid).set({
          'userId': user.uid,
          'items': _cart.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving cart to Firestore: $e');
    }
  }

  // Get cart from Firestore
  Future<void> refreshCart() async {
    await initCart();
  }

  // Process checkout
  Future<String?> checkout({
    required String address,
    required String paymentMethod,
    double taxRate = 0.08,
    double shippingFee = 5.99,
    String? couponCode,
    double? discount,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || _cart.items.isEmpty) {
        throw Exception('User not logged in or cart is empty');
      }

      // Calculate order totals
      double subtotal = _cart.totalAmount;
      double tax = subtotal * taxRate;
      double shipping = shippingFee;
      double total = subtotal + tax + shipping;

      // Apply discount if available
      if (discount != null && discount > 0) {
        total -= discount;
      }

      // Convert cart items to list for order
      List<CartItem> orderItems = _cart.items.values.toList();

      // Create order in Firestore
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': user.uid,
        'items': orderItems.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'total': total,
        'couponCode': couponCode,
        'discount': discount,
        'status': 0, // pending
        'paymentMethod': paymentMethod,
        'paid': false,
        'shippingAddress': address,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cart after successful order
      await clearCart();

      return orderRef.id;
    } catch (e) {
      print('Error during checkout: $e');
      return null;
    }
  }
}
