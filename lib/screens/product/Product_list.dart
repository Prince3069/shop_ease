import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../widgets/product_card.dart';
import 'product_detail.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final bool showFeaturedOnly;
  final String? searchQuery;

  const ProductListScreen({
    Key? key,
    this.categoryId,
    this.categoryName,
    this.showFeaturedOnly = false,
    this.searchQuery,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _sortBy = 'newest';
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final String title = widget.categoryName ??
        (widget.showFeaturedOnly
            ? 'Featured Products'
            : (widget.searchQuery != null ? 'Search Results' : 'All Products'));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'newest',
                child: Text('Newest First'),
              ),
              PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              PopupMenuItem(
                value: 'rating',
                child: Text('Highest Rated'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firestoreService.getProducts(
          categoryId: widget.categoryId,
          featured: widget.showFeaturedOnly ? true : null,
          searchQuery: widget.searchQuery,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading products. Please try again.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No products found.'),
            );
          }

          final products = snapshot.data!;

          // Sort products
          switch (_sortBy) {
            case 'price_low':
              products.sort((a, b) => a.actualPrice.compareTo(b.actualPrice));
              break;
            case 'price_high':
              products.sort((a, b) => b.actualPrice.compareTo(a.actualPrice));
              break;
            case 'rating':
              products.sort((a, b) => b.rating.compareTo(a.rating));
              break;
            case 'newest':
            default:
              products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              return Future.delayed(Duration(milliseconds: 500));
            },
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          productId: product.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
