import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_controller.dart';
import '../history/history_types.dart';
import '../history/history_view.dart';

class FinancialSettlementView extends StatelessWidget {
  const FinancialSettlementView({super.key});

  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _primary = Color(0xFFC15A20);
  static const Color _primaryDark = Color(0xFF8A4C31);
  static const Color _text = Color(0xFF222222);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _primaryDark),
          title: const Text(
            'التسوية المالية',
            style: TextStyle(color: _primaryDark, fontWeight: FontWeight.w900),
          ),
        ),
        body: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ملخص الحساب الحالي',
                      style: TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MoneyLine(
                      title: 'المديونية على السائق للمطعم',
                      value: c.debtToday.value.toStringAsFixed(2),
                    ),

                    _MoneyLine(
                      title: 'الربح',
                      value: c.profitAll.value.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: c.loading.value
                      ? null
                      : () async {
                          final ok = await _confirm(context);
                          if (ok == true) {
                            await c.closeRestaurantDaily();
                          }
                        },
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(
                    c.loading.value
                        ? 'جاري التنفيذ...'
                        : 'تنفيذ التسوية وتصفير مديونية المطعم',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => const HistoryView(
                      kind: HistoryKind.debt,
                      initialRange: 'all',
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('عرض سجل المديونية والتسويات'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: BorderSide(color: _primary.withOpacity(.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد التسوية'),
          content: const Text(
            'هل تريد تنفيذ التسوية المالية الآن؟ سيتم تسجيل الإغلاق وتحديث الحساب حسب النظام.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: FinancialSettlementView._muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value د.ل',
            style: const TextStyle(
              color: FinancialSettlementView._text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
