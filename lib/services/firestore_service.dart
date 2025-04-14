import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products
  Stream<List<ProductModel>> getProducts({
    String? categoryId,
    bool? isFeatured,
    String? query,
    int limit = 10,
  }) {
    Query productsQuery = _firestore.collection('products');

    if (categoryId != null) {
      productsQuery = productsQuery.where('categoryId', isEqualTo: categoryId);
    }

    if (isFeatured != null) {
      productsQuery = productsQuery.where('isFeatured', isEqualTo: isFeatured);
    }

    if (query != null && query.isNotEmpty) {
      // Firebase doesn't support full-text search directly
      // This is a simplified version, for production you might need Algolia or similar
      productsQuery = productsQuery
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff');
    }

    return productsQuery.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();

    if (doc.exists) {
      return ProductModel.fromMap(doc.data()!, doc.id);
    }

    return null;
  }

  // Categories
  Stream<List<CategoryModel>> getCategories() {
    return _firestore
        .collection('categories')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Cart
  Future<CartModel> getCart(String userId) async {
    final doc = await _firestore.collection('carts').doc(userId).get();

    if (doc.exists) {
      return CartModel.fromMap(doc.data()!, userId);
    }

    return CartModel.empty(userId);
  }

  Future<void> updateCart(CartModel cart) async {
    await _firestore.collection('carts').doc(cart.userId).set(cart.toMap());
  }

  // Orders
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore.collection('orders').add(order.toMap());
    return docRef.id;
  }

  Stream<List<OrderModel>> getOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final doc = await _firestore.collection('orders').doc(orderId).get();

    if (doc.exists) {
      return OrderModel.fromMap(doc.data()!, doc.id);
    }

    return null;
  }
}
