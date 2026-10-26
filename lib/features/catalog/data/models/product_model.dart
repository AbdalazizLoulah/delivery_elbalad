import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/product.dart';

class CategoryModel extends Category {
  const CategoryModel({required super.id, required super.name, super.icon, super.sortOrder});

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: JsonX.str(json, 'id'),
        name: JsonX.str(json, 'name_ar', fallback: JsonX.str(json, 'name')),
        icon: JsonX.str(json, 'icon', fallback: '🛒'),
        sortOrder: JsonX.integer(json, 'sort_order'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': name,
        'icon': icon,
        'sort_order': sortOrder,
      };
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.sellerId,
    required super.title,
    required super.price,
    super.description,
    super.imageUrl,
    super.categoryId,
    super.categoryName,
    super.sellerName,
    super.stock,
    super.rating,
    super.reviewsCount,
    super.isActive,
    super.storeLat,
    super.storeLng,
    super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] is Map ? Map<String, dynamic>.from(json['category'] as Map) : null;
    final seller = json['seller'] is Map ? Map<String, dynamic>.from(json['seller'] as Map) : null;
    final store = json['store'] is Map ? Map<String, dynamic>.from(json['store'] as Map) : null;

    return ProductModel(
      id: JsonX.str(json, 'id'),
      sellerId: JsonX.str(json, 'seller_id'),
      title: JsonX.str(json, 'title'),
      price: JsonX.dbl(json, 'price'),
      description: JsonX.str(json, 'description'),
      imageUrl: JsonX.str(json, 'image_url'),
      categoryId: JsonX.str(json, 'category_id', fallback: 'other'),
      categoryName: category == null ? '' : JsonX.str(category, 'name_ar'),
      sellerName: seller == null
          ? JsonX.str(json, 'seller_name')
          : JsonX.str(seller, 'full_name'),
      stock: JsonX.integer(json, 'stock'),
      rating: JsonX.dbl(json, 'rating'),
      reviewsCount: JsonX.integer(json, 'reviews_count'),
      isActive: JsonX.boolean(json, 'is_active', fallback: true),
      storeLat: store == null ? JsonX.dblOrNull(json, 'store_lat') : JsonX.dblOrNull(store, 'lat'),
      storeLng: store == null ? JsonX.dblOrNull(json, 'store_lng') : JsonX.dblOrNull(store, 'lng'),
      createdAt: JsonX.dateOrNull(json, 'created_at'),
    );
  }

  /// بيانات الإدراج/التعديل في قاعدة البيانات.
  Map<String, dynamic> toJson({bool includeId = true}) => {
        if (includeId) 'id': id,
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'category_id': categoryId,
        'stock': stock,
        'is_active': isActive,
      };

  factory ProductModel.fromEntity(Product product) => ProductModel(
        id: product.id,
        sellerId: product.sellerId,
        title: product.title,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        sellerName: product.sellerName,
        stock: product.stock,
        rating: product.rating,
        reviewsCount: product.reviewsCount,
        isActive: product.isActive,
        storeLat: product.storeLat,
        storeLng: product.storeLng,
        createdAt: product.createdAt,
      );
}
