import 'package:flutter/material.dart';

/// نسخة من `IndexedStack` بتبني التاب المفتوح فقط (Lazy)، وبعدين بتحتفظ بحالته.
///
/// الفايدة: الشاشات اللي فيها تحميل بيانات (طلبات / منتجات) مش بتتنده غير لما
/// المستخدم يفتح التاب بتاعها، وبعد كده بتفضل محتفظة بحالتها زي العادي.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final Set<int> _opened = {widget.index};

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _opened.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_opened.contains(i)) widget.children[i] else const SizedBox.shrink(),
      ],
    );
  }
}
