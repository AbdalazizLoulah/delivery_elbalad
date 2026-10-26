import 'package:equatable/equatable.dart';

/// تصنيف المنتجات في السوق.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    this.icon = '🛒',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  @override
  List<Object?> get props => [id, name, icon, sortOrder];
}

/// المنتج المعروض في السوق والمملوك لبائع.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.categoryId = 'other',
    this.categoryName = '',
    this.sellerName = '',
    this.stock = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.isActive = true,
    this.storeLat,
    this.storeLng,
    this.createdAt,
  });

  final String id;
  final String sellerId;
  final String title;
  final double price;
  final String description;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final String sellerName;
  final int stock;
  final double rating;
  final int reviewsCount;
  final bool isActive;

  /// موقع المتجر - بيتستخدم في حساب أقرب دليفاري.
  final double? storeLat;
  final double? storeLng;
  final DateTime? createdAt;

  bool get inStock => stock > 0;

  Product copyWith({
    String? title,
    double? price,
    String? description,
    String? imageUrl,
    String? categoryId,
    String? categoryName,
    String? sellerName,
    int? stock,
    bool? isActive,
  }) {
    return Product(
      id: id,
      sellerId: sellerId,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sellerName: sellerName ?? this.sellerName,
      stock: stock ?? this.stock,
      rating: rating,
      reviewsCount: reviewsCount,
      isActive: isActive ?? this.isActive,
      storeLat: storeLat,
      storeLng: storeLng,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        title,
        price,
        description,
        imageUrl,
        categoryId,
        stock,
        isActive,
      ];
}
