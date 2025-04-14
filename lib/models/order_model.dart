import 'cart_model.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String? couponCode;
  final double? discount;
  final OrderStatus status;
  final String? paymentMethod;
  final bool paid;
  final String? shippingAddress;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    this.couponCode,
    this.discount,
    required this.status,
    this.paymentMethod,
    required this.paid,
    this.shippingAddress,
    this.trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory OrderModel.fromMap(Map<String, dynamic> data, String id) {
    List<CartItem> orderItems = [];
    if (data['items'] != null) {
      (data['items'] as List).forEach((item) {
        orderItems.add(CartItem.fromMap(item));
      });
    }

    return OrderModel(
      id: id,
      userId: data['userId'] ?? '',
      items: orderItems,
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      shipping: (data['shipping'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      couponCode: data['couponCode'],
      discount: data['discount']?.toDouble(),
      status: OrderStatus.values[data['status'] ?? 0],
      paymentMethod: data['paymentMethod'],
      paid: data['paid'] ?? false,
      shippingAddress: data['shippingAddress'],
      trackingNumber: data['trackingNumber'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> itemsMap = [];
    items.forEach((item) {
      itemsMap.add(item.toMap());
    });

    return {
      'userId': userId,
      'items': itemsMap,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'total': total,
      'couponCode': couponCode,
      'discount': discount,
      'status': status.index,
      'paymentMethod': paymentMethod,
      'paid': paid,
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
