import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_ease/models/product_model.dart';
import 'package:shop_ease/services/auth_service.dart';
// import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cartService = Provider.of<CartService>(context);
    final user = authService.currentUser;

    final isWishlisted = user != null &&
            Provider.of<AuthService>(context)
                .currentUser
                ?.wishlist
                .contains(product.id) ??
        false;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with sale badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey[500]),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.image,
                                size: 50, color: Colors.grey[500]),
                          ),
                        ),
                ),

                // Wishlist button
                Positioned(
                  right: 4,
                  top: 4,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: user == null
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Please login to add to wishlist'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : () {
                              authService.toggleWishlist(product.id);
                            },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: isWishlisted
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),

                // Sale badge
                if (product.isOnSale)
                  Positioned(
                    left: 0,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'SALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          product.priceDisplay,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (product.isOnSale) ...[
                          SizedBox(width: 4),
                          Text(
                            product.originalPriceDisplay,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Add to cart button
            Material(
              color: Theme.of(context).colorScheme.primary,
              child: InkWell(
                onTap: () {
                  if (product.stock > 0) {
                    cartService.addToCart(
                      product.id,
                      product.name,
                      product.actualPrice,
                      product.images.isNotEmpty ? product.images[0] : '',
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        duration: Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          onPressed: () {
                            // Navigate to cart
                            Navigator.pushNamed(context, '/cart');
                          },
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Product out of stock'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      product.stock > 0 ? 'ADD TO CART' : 'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
