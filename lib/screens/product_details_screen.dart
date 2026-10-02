// Enhancement 2: product details page
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // Enhancement 3: demo user id, same one cart_screen.dart uses
  final int _userId = 1;
  bool _isAdding = false;

  // Enhancement 3: calls POST /carts/add with this product's id/quantity
  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    try {
      await CartService().addToCart(
        userId: _userId,
        products: [
          {'id': widget.product.id, 'quantity': 1},
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.title} added to cart!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              product.thumbnail,
              width: double.infinity,
              height: 250.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 250.h,
                color: Colors.grey.shade300,
                child: Icon(Icons.image, size: 48.sp),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: product.title,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: '${product.rating} ★  •  ${product.stock} in stock',
                    fontSize: 13.sp,
                  ),
                  SizedBox(height: 16.h),
                  CustomText(text: product.description, fontSize: 14.sp),
                  SizedBox(height: 16.h),
                  CustomText(text: 'Brand: ${product.brand}', fontSize: 13.sp),
                  CustomText(
                    text: 'Category: ${product.category}',
                    fontSize: 13.sp,
                  ),
                  CustomText(
                    text: 'Warranty: ${product.warrantyInformation}',
                    fontSize: 13.sp,
                  ),
                  CustomText(
                    text: 'Shipping: ${product.shippingInformation}',
                    fontSize: 13.sp,
                  ),
                  CustomText(
                    text: 'Return Policy: ${product.returnPolicy}',
                    fontSize: 13.sp,
                  ),
                  SizedBox(height: 24.h),
                  // Enhancement 3: add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: _isAdding ? null : _addToCart,
                      child: _isAdding
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const CustomText(
                              text: 'Add to Cart',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
