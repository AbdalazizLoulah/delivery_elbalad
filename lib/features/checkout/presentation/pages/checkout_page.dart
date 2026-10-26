import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/payment_cards.dart';
import '../../../../core/utils/pricing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../cart/domain/entities/cart_line.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/utils/order_ui.dart';
import '../../../profile/domain/entities/address.dart';
import '../bloc/checkout_bloc.dart';

import '../../../../core/localization/app_text.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/utils/responsive.dart';
/// صفحة إتمام الطلب: العنوان + طريقة الدفع + مراجعة الطلب.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: ErrorView(message: 'لازم تسجل دخول الأول.'));
    }
    return BlocProvider(
      create: (_) => di<CheckoutBloc>()..add(CheckoutStarted(user)),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _cardExpiry = TextEditingController();
  final _cardCvv = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).pushNamed<PickedAddress>(
      AppRoutes.addressPicker,
    );
    if (result == null || !mounted) return;
    context.read<CheckoutBloc>().add(CheckoutLocationPicked(
          lat: result.lat,
          lng: result.lng,
          label: result.label,
          details: result.details,
        ));
  }

  void _submit() {
    final state = context.read<CheckoutBloc>().state;
    var cardValidated = true;
    if (state.paymentMethod == PaymentMethod.visa) {
      cardValidated = _formKey.currentState?.validate() ?? false;
      if (!cardValidated) return;
    }

    final lines = context.read<CartBloc>().state.lines;
    FocusScope.of(context).unfocus();
    context.read<CheckoutBloc>().add(CheckoutSubmitted(lines: lines, cardValidated: cardValidated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listenWhen: (previous, current) =>
          (current.errorMessage != null && previous.errorMessage != current.errorMessage) ||
          (current.hasCreatedOrders && !previous.hasCreatedOrders),
      listener: (context, state) {
        if (state.errorMessage != null) {
          showAppSnackBar(context, state.errorMessage!, isError: true);
        }
        if (state.hasCreatedOrders) {
          final cart = context.read<CartBloc>();
          for (final order in state.createdOrders) {
            cart.add(CartCleared(sellerId: order.sellerId));
          }
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.checkoutSuccess,
            arguments: state.createdOrders,
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) return const LoadingView(label: 'بنجهز بيانات الطلب...');

        final lines = context.watch<CartBloc>().state.lines;
        final address = state.selectedAddress;
        final fees = _estimateFees(lines, address);

        return Scaffold(
          appBar: AppBar(title: const AppText('إتمام الطلب')),
          body: Responsive.centerContent(ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const SectionHeader(title: 'عنوان التوصيل'),
              _AddressList(
                addresses: state.addresses,
                selected: address,
                isLocating: state.isLocating,
                onSelect: (item) => context.read<CheckoutBloc>().add(CheckoutAddressSelected(item)),
                onAddNew: _pickOnMap,
                onUseCurrentLocation: () =>
                    context.read<CheckoutBloc>().add(const CheckoutCurrentLocationRequested()),
                pickedAddressText: state.pickedAddressText,
              ),
              const SizedBox(height: 8),
              const SectionHeader(title: 'طريقة الدفع'),
              _PaymentMethods(
                selected: state.paymentMethod,
                onSelect: (method) =>
                    context.read<CheckoutBloc>().add(CheckoutPaymentMethodSelected(method)),
              ),
              if (state.paymentMethod == PaymentMethod.visa) ...[
                const SizedBox(height: 12),
                _CardForm(
                  formKey: _formKey,
                  number: _cardNumber,
                  expiry: _cardExpiry,
                  cvv: _cardCvv,
                ),
              ],
              const SizedBox(height: 14),
              const SectionHeader(title: 'ملاحظات للمتجر أو الطيار'),
              TextField(
                controller: _noteController,
                maxLines: 2,
                onChanged: (value) => context.read<CheckoutBloc>().add(CheckoutNoteChanged(value)),
                decoration: InputDecoration(
                  hintText: trOf(context, 'مثال: كلمني قبل ما توصل، الدور الثالث'),
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'ملخص الطلب'),
              _OrderSummary(lines: lines, fees: fees),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: state.paymentMethod == PaymentMethod.visa
                    ? 'ادفع ${Formatters.money(_subtotal(lines) + _totalFees(fees))}'
                    : 'تأكيد الطلب (الدفع عند الوصول)',
                icon: state.paymentMethod == PaymentMethod.visa
                    ? Icons.lock_outline
                    : Icons.check_circle_outline,
                isLoading: state.isPlacing,
                onPressed: lines.isEmpty ? null : _submit,
              ),
              const SizedBox(height: 10),
              const AppText(
                'بالضغط على تأكيد الطلب أنت موافق على شروط الخدمة وسياسة الاسترجاع.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
            ],
          )),
        );
      },
    );
  }

  Map<String, double> _estimateFees(List<CartLine> lines, Address? address) {
    if (address == null) return const {};
    final fees = <String, double>{};
    for (final line in lines) {
      fees[line.product.sellerId] = _sellerFee(line, address);
    }
    return fees;
  }

  double _sellerFee(CartLine line, Address address) {
    final lat = line.product.storeLat;
    final lng = line.product.storeLng;
    if (lat == null || lng == null) return 10;
    final distance = DistanceCalculator.betweenKm(
      fromLat: lat,
      fromLng: lng,
      toLat: address.lat,
      toLng: address.lng,
    );
    return Pricing.deliveryFee(distance);
  }

  double _subtotal(List<CartLine> lines) =>
      lines.fold(0, (sum, line) => sum + line.total);

  double _totalFees(Map<String, double> fees) => fees.values.fold(0, (sum, fee) => sum + fee);
}

class _AddressList extends StatelessWidget {
  const _AddressList({
    required this.addresses,
    required this.selected,
    required this.onSelect,
    required this.onAddNew,
    required this.onUseCurrentLocation,
    required this.isLocating,
    this.pickedAddressText,
  });

  final List<Address> addresses;
  final Address? selected;
  final ValueChanged<Address> onSelect;
  final VoidCallback onAddNew;
  final VoidCallback onUseCurrentLocation;
  final bool isLocating;
  final String? pickedAddressText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioGroup<String>(
          groupValue: selected?.id,
          onChanged: (value) {
            if (value == null) return;
            onSelect(addresses.firstWhere(
              (address) => address.id == value,
              orElse: () => addresses.first,
            ));
          },
          child: Column(
            children: [
              for (final address in addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onTap: () => onSelect(address),
                    child: RadioListTile<String>(
                      value: address.id,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          AppText(address.label,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          if (address.isDefault) ...[
                            const SizedBox(width: 6),
                            const Chip(
                                label: AppText('الافتراضي'),
                                visualDensity: VisualDensity.compact),
                          ],
                        ],
                      ),
                      subtitle: AppText(address.details,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12.5)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            children: [
              AppPrimaryButton(
                outlined: true,
                label: 'حدد موقع على الخريطة (Google Maps)',
                onPressed: onAddNew,
              ),
              const SizedBox(height: 8),
              AppPrimaryButton(
                label: isLocating ? 'بنجيب موقعك...' : 'استخدم موقعي الحالي',
                icon: Icons.my_location,
                isLoading: isLocating,
                onPressed: onUseCurrentLocation,
              ),
              if (pickedAddressText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AppText(pickedAddressText!,
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.selected, required this.onSelect});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final method in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => onSelect(method),
              child: Row(
                children: [
                  Icon(method.icon, color: selected == method ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(method.label,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        AppText(method.description,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(
                    selected == method
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected == method ? AppColors.primary : AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CardForm extends StatelessWidget {
  const _CardForm({
    required this.formKey,
    required this.number,
    required this.expiry,
    required this.cvv,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController number;
  final TextEditingController expiry;
  final TextEditingController cvv;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.success),
                SizedBox(width: 6),
                AppText('دفع آمن ومشفر', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: number,
              label: 'رقم الكارت',
              hint: '4111 1111 1111 1111',
              keyboardType: TextInputType.number,
              icon: Icons.credit_card,
              inputFormatters: const [CardNumberInputFormatter()],
              validator: Validators.cardNumber,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: expiry,
                    label: 'الانتهاء',
                    hint: 'MM/YY',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [CardExpiryInputFormatter()],
                    validator: Validators.cardExpiry,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    controller: cvv,
                    label: 'CVV',
                    hint: '123',
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: const [CardCvvInputFormatter()],
                    validator: Validators.cardCvv,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.lines, required this.fees});

  final List<CartLine> lines;
  final Map<String, double> fees;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const EmptyView(title: 'السلة فاضية', icon: Icons.shopping_cart_outlined);
    }

    final grouped = <String, List<CartLine>>{};
    for (final line in lines) {
      grouped.putIfAbsent(line.product.sellerId, () => []).add(line);
    }

    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.total);
    final totalFees = fees.values.fold<double>(0, (sum, fee) => sum + fee);

    return AppCard(
      child: Column(
        children: [
          for (final entry in grouped.entries) ...[
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: AppText(
                    entry.value.first.product.sellerName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                AppText('${entry.value.length} منتج',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            for (final line in entry.value)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        '${line.quantity} × ${line.product.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    AppText(PriceTag.formatMoney(line.total),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const AppText('دليفاري المتجر دا:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                AppText(Formatters.money(fees[entry.key] ?? 0),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 22),
          ],
          _TotalRow(label: 'إجمالي المنتجات', value: subtotal),
          _TotalRow(label: 'مصاريف الدليفاري', value: totalFees),
          _TotalRow(label: 'الإجمالي', value: subtotal + totalFees, isBold: true),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.isBold = false});

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AppText(label,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              )),
          const Spacer(),
          AppText(
            Formatters.money(value),
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: FontWeight.w800,
              color: isBold ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
