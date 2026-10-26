import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/usecases/catalog_usecases.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// إضافة أو تعديل منتج (الشاشة بترجع المنتج للتعديل في الصفحة السابقة).
class SellerProductFormPage extends StatefulWidget {
  const SellerProductFormPage({super.key, this.product});

  final Product? product;

  @override
  State<SellerProductFormPage> createState() => _SellerProductFormPageState();
}

class _SellerProductFormPageState extends State<SellerProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _title = TextEditingController(text: widget.product?.title ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.product == null ? '' : widget.product!.price.toStringAsFixed(0));
  late final TextEditingController _stock =
      TextEditingController(text: widget.product == null ? '10' : widget.product!.stock.toString());
  late final TextEditingController _image = TextEditingController(text: widget.product?.imageUrl ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.product?.description ?? '');

  List<Category> _categories = const [];
  String _categoryId = 'other';
  bool _isActive = true;
  bool _isLoadingCategories = true;
  String? _categoriesError;

  bool _isUploading = false;
  Uint8List? _pickedBytes;
  String? _pickedName;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId ?? 'other';
    _isActive = widget.product?.isActive ?? true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });

    try {
      final result = await di<GetCategoriesUseCase>()(const NoParams())
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      final categories = result.data;
      setState(() {
        _isLoadingCategories = false;
        if (categories == null || categories.isEmpty) {
          _categories = const [];
          _categoriesError = result.failure?.message ?? 'مفيش تصنيفات متاحة على السيرفر.';
          return;
        }
        _categories = categories;
        if (!_categories.any((category) => category.id == _categoryId)) {
          _categoryId = _categories.first.id;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categories = const [];
        _categoriesError = 'السيرفر مش بيرد دلوقتي، اتأكد من الإنترنت وحاول تاني.';
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _stock.dispose();
    _image.dispose();
    _description.dispose();
    super.dispose();
  }

  /// اختيار صورة من معرض الصور أو الكاميرا (بتترفع وقت الحفظ).
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedName = picked.name.trim().isEmpty ? 'product.jpg' : picked.name.trim();
      });
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'مش قادرين نفتح الصور، حاول تاني.', isError: true);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categories.isEmpty) {
      showAppSnackBar(context, 'التصنيفات لسه ما اتحملتش — اضغط "حاول تاني" فوق.', isError: true);
      return;
    }
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    var imageUrl = _image.text.trim();

    // لو فيه صورة جديدة مختارة من الجهاز، بترتفع على Supabase Storage الأول.
    if (_pickedBytes != null) {
      setState(() => _isUploading = true);
      try {
        imageUrl = await di<StorageService>().uploadProductImage(
          bytes: _pickedBytes!,
          fileName: _pickedName ?? 'product.jpg',
          sellerId: user.id,
        );
      } on AppException catch (error) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        showAppSnackBar(context, error.message, isError: true);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        showAppSnackBar(context, 'مش قادرين نرفع الصورة، حاول تاني.', isError: true);
        return;
      }
      if (!mounted) return;
      setState(() => _isUploading = false);
    }

    final existing = widget.product;
    final category = _categories.where((item) => item.id == _categoryId).firstOrNull;

    final product = Product(
      id: existing?.id ?? const Uuid().v4(),
      sellerId: user.id,
      title: _title.text.trim(),
      price: double.parse(_price.text.trim()),
      description: _description.text.trim(),
      imageUrl: imageUrl,
      categoryId: _categoryId,
      categoryName: category?.name ?? '',
      sellerName: user.fullName,
      stock: int.parse(_stock.text.trim()),
      rating: existing?.rating ?? 0,
      reviewsCount: existing?.reviewsCount ?? 0,
      isActive: _isActive,
      storeLat: existing?.storeLat ?? user.lat,
      storeLng: existing?.storeLng ?? user.lng,
      createdAt: existing?.createdAt,
    );

    Navigator.of(context).pop(product);
  }

  Widget _previewPlaceholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(
          Icons.image_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          size: 36,
        ),
      );

  Widget _imagePreview(BuildContext context) {
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!, fit: BoxFit.cover, width: double.infinity);
    }
    final url = _image.text.trim();
    if (url.isEmpty) return _previewPlaceholder(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => _previewPlaceholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText(widget.product == null ? 'منتج جديد' : 'تعديل المنتج')),
      body: Form(
        key: _formKey,
        child: Responsive.centerContent(ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _title,
              label: 'اسم المنتج',
              icon: Icons.shopping_bag_outlined,
              validator: (value) => Validators.required(value, message: 'اكتب اسم المنتج'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _price,
                    label: 'السعر (ج.م)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final price = double.tryParse(value?.trim() ?? '');
                      if (price == null || price <= 0) return 'سعر غير صحيح';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _stock,
                    label: 'المخزون',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final stock = int.tryParse(value?.trim() ?? '');
                      if (stock == null || stock < 0) return 'رقم غير صحيح';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoadingCategories)
              const LoadingView(label: 'بنجيب التصنيفات...')
            else if (_categoriesError != null)
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_outlined, color: AppColors.danger, size: 32),
                    const SizedBox(height: 8),
                    const AppText(
                      'مش قادرين نجيب التصنيفات',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      '$_categoriesError\nلو دي أول مرة، شغّل ملف supabase/schema.sql من SQL Editor على Supabase.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadCategories,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const AppText('حاول تاني'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: trOf(context, 'التصنيف'),
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: AppText('${category.icon} ${category.name}'),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value ?? 'other'),
              ),
            const SizedBox(height: 14),
            const AppText('صورة المنتج',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _imagePreview(context),
              ),
            ),
            if (!AppConfig.isDemoMode) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const AppText('من المعرض'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const AppText('صوّر المنتج'),
                    ),
                  ),
                ],
              ),
              if (_pickedBytes != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => setState(() {
                              _pickedBytes = null;
                              _pickedName = null;
                            }),
                    icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                    label: const AppText('شيل الصورة المختارة',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            AppTextField(
              controller: _image,
              label: _pickedBytes == null ? 'رابط صورة المنتج' : 'الصورة المختارة هتترفع لما تحفظ',
              hint: 'https://...',
              icon: Icons.image_outlined,
              keyboardType: TextInputType.url,
              enabled: _pickedBytes == null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _description,
              label: 'الوصف',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              title: const AppText('ظاهر للعملاء',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const AppText('لو قفلته المنتج مش هيظهر في السوق',
                  style: TextStyle(fontSize: 12)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: _isUploading
                  ? 'بنرفع الصورة...'
                  : widget.product == null
                      ? 'إضافة المنتج'
                      : 'حفظ التعديلات',
              icon: Icons.save_outlined,
              isLoading: _isUploading,
              onPressed: _isUploading ? null : () => _save(),
            ),
          ],
        )),
      ),
    );
  }
}
