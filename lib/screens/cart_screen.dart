import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';
import '../models/product.dart';

// services
import '../services/cart_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Enhancement 3: hardcoded demo user id (dummyjson test users go from 1-208)
  final int _userId = 1;
  late Future<Cart?> _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // Enhancement 3: load only this user's cart via getCartByUserId
  void _loadCart() {
    _cartFuture = CartService().getCartByUserId(_userId);
  }

  // Converts a CartProduct into a minimal Product so we can reuse
  // ProductDetailsScreen (Enhancement 1: cart items are clickable)
  Product _cartProductToProduct(CartProduct cp) {
    return Product(
      id: cp.id,
      title: cp.title,
      description:
          'No additional description available from the cart endpoint.',
      category: '',
      price: cp.price,
      discountPercentage: cp.discountPercentage,
      rating: 0,
      stock: 0,
      tags: const [],
      brand: '',
      sku: '',
      weight: 0,
      dimensions: ProductDimensions(width: 0, height: 0, depth: 0),
      warrantyInformation: '',
      shippingInformation: '',
      availabilityStatus: '',
      reviews: const [],
      returnPolicy: '',
      minimumOrderQuantity: 1,
      meta: ProductMeta(createdAt: '', updatedAt: '', barcode: '', qrCode: ''),
      images: [cp.thumbnail],
      thumbnail: cp.thumbnail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 2,
          title: const CustomText(
            text: 'Cart',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        body: FutureBuilder<Cart?>(
          future: _cartFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: CustomText(
                  text: 'Error: ${snapshot.error}',
                  fontSize: 14.sp,
                ),
              );
            }

            final cart = snapshot.data;
            if (cart == null || cart.products.isEmpty) {
              return Center(
                child: CustomText(text: 'Your cart is empty.', fontSize: 14.sp),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: cart.products.length,
                    itemBuilder: (context, index) {
                      final item = cart.products[index];
                      return GestureDetector(
                        // Enhancement 1: tap a cart item to view its details
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                product: _cartProductToProduct(item),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12.h),
                          child: Padding(
                            padding: EdgeInsets.all(10.r),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    item.thumbnail,
                                    width: 60.w,
                                    height: 60.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image, size: 24.sp),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        text: item.title,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      SizedBox(height: 4.h),
                                      CustomText(
                                        text:
                                            '\$${item.price.toStringAsFixed(2)}  •  ${item.discountPercentage.toStringAsFixed(0)}% off - \$${item.discountedTotal.toStringAsFixed(2)} total',
                                        fontSize: 12.sp,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () {
                                        // stepper UI only; wiring up
                                        // add/remove quantity to the API
                                        // is optional for this activity
                                      },
                                    ),
                                    CustomText(
                                      text: '${item.quantity}',
                                      fontSize: 13.sp,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(text: 'Subtotal:', fontSize: 14.sp),
                          CustomText(
                            text:
                                '\$${cart.discountedTotal.toStringAsFixed(2)}',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          onPressed: () {},
                          child: const CustomText(
                            text: 'Confirm Order',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
