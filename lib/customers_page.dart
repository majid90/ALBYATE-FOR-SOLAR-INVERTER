import 'package:flutter/material.dart';
import 'database.dart';

const _navy = Color(0xFF263A98);
const _pink = Color(0xFFE90070);

class CustomersPage extends StatefulWidget {
  final String centerId;
  final String lang;
  const CustomersPage({super.key, required this.centerId, required this.lang});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _search = TextEditingController();
  bool get _ar => widget.lang == 'ar';
  String t(String ar, String en) => _ar ? ar : en;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    final notes = TextEditingController();
    final limit = TextEditingController(text: '0');
    String priceType = 'retail';
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(t('إضافة زبون جديد', 'Add customer')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(name, t('اسم الزبون', 'Customer name')),
              _field(phone, t('رقم الهاتف', 'Phone number'), keyboard: TextInputType.phone),
              _field(address, t('العنوان', 'Address')),
              DropdownButtonFormField<String>(
                value: priceType,
                decoration: InputDecoration(labelText: t('نوع التسعير', 'Price category')),
                items: [
                  DropdownMenuItem(value: 'retail', child: Text(t('مفرد', 'Retail'))),
                  DropdownMenuItem(value: 'wholesale', child: Text(t('جملة', 'Wholesale'))),
                  DropdownMenuItem(value: 'special', child: Text(t('سعر خاص', 'Special price'))),
                ],
                onChanged: (v) => setLocal(() => priceType = v ?? 'retail'),
              ),
              _field(limit, t('حد الدين الائتماني (د.ع)', 'Credit limit (IQD)'), keyboard: const TextInputType.numberWithOptions(decimal: true)),
              _field(notes, t('ملاحظات', 'Notes'), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('إلغاء', 'Cancel'))),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                await AppDb.instance.addCustomer(
                  widget.centerId,
                  name: name.text,
                  phone: phone.text,
                  address: address.text,
                  notes: notes.text,
                  priceType: priceType,
                  creditLimit: double.tryParse(limit.text) ?? 0,
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(t('حفظ', 'Save')),
            ),
          ],
        ),
      ),
    );
    name.dispose(); phone.dispose(); address.dispose(); notes.dispose(); limit.dispose();
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(child: Text(t('الزبائن والحسابات', 'Customers & accounts'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _navy))),
          FilledButton.icon(onPressed: _addCustomer, icon: const Icon(Icons.person_add_alt_1), label: Text(t('إضافة', 'Add'))),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t('ابحث بالاسم أو الهاتف', 'Search name or phone')),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: AppDb.instance.customers(widget.centerId, query: _search.text),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (rows.isEmpty) return Center(child: Text(t('لا يوجد زبائن مسجلون', 'No customers registered')));
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final customer = rows[index];
                return FutureBuilder<double>(
                  future: AppDb.instance.customerBalance(widget.centerId, customer['id'].toString()),
                  builder: (context, balanceSnapshot) {
                    final balance = balanceSnapshot.data ?? 0;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFE9ECFA), child: Icon(Icons.person, color: _navy)),
                        title: Text(customer['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${customer['phone'] ?? ''}\n${_priceLabel(customer['price_type']?.toString() ?? 'retail')}'),
                        isThreeLine: true,
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(balance.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, color: balance > 0 ? _pink : Colors.green)),
                          Text(t('الرصيد (د.ع)', 'Balance (IQD)'), style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                        ]),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailPage(centerId: widget.centerId, lang: widget.lang, customer: customer)));
                          if (mounted) setState(() {});
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  String _priceLabel(String value) => value == 'wholesale' ? t('تسعير جملة', 'Wholesale pricing') : value == 'special' ? t('تسعير خاص', 'Special pricing') : t('تسعير مفرد', 'Retail pricing');

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboard, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(controller: controller, keyboardType: keyboard, maxLines: maxLines, decoration: InputDecoration(labelText: label)),
  );
}

class CustomerDetailPage extends StatefulWidget {
  final String centerId;
  final String lang;
  final Map<String, Object?> customer;
  const CustomerDetailPage({super.key, required this.centerId, required this.lang, required this.customer});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  bool get _ar => widget.lang == 'ar';
  String t(String ar, String en) => _ar ? ar : en;
  String get customerId => widget.customer['id'].toString();

  Future<void> _payment() async {
    final amount = TextEditingController();
    final note = TextEditingController(text: t('تسديد من الزبون', 'Customer payment'));
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('استلام دفعة', 'Receive payment')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('المبلغ بالدينار', 'Amount (IQD)'))),
          const SizedBox(height: 10),
          TextField(controller: note, decoration: InputDecoration(labelText: t('البيان', 'Description'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () async {
            final value = double.tryParse(amount.text) ?? 0;
            if (value <= 0) return;
            await AppDb.instance.recordCustomerPayment(widget.centerId, customerId, amount: value, note: note.text.trim());
            if (ctx.mounted) Navigator.pop(ctx, true);
          }, child: Text(t('تسجيل الاستلام', 'Record receipt'))),
        ],
      ),
    );
    amount.dispose(); note.dispose();
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _sale() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => CustomerSalePage(centerId: widget.centerId, lang: widget.lang, customer: widget.customer)));
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Scaffold(
      appBar: AppBar(title: Text(customer['name'].toString())),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          AppDb.instance.customerBalance(widget.centerId, customerId),
          AppDb.instance.customerLedger(widget.centerId, customerId),
        ]),
        builder: (context, snapshot) {
          final balance = snapshot.data == null ? 0.0 : snapshot.data![0] as double;
          final entries = snapshot.data?[1] as List<Map<String, Object?>>? ?? [];
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer['name'].toString(), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _navy)),
              if ((customer['phone'] ?? '').toString().isNotEmpty) Text(customer['phone'].toString()),
              if ((customer['address'] ?? '').toString().isNotEmpty) Text(customer['address'].toString()),
              const SizedBox(height: 14),
              Text(t('الرصيد المستحق', 'Outstanding balance'), style: const TextStyle(color: Colors.blueGrey)),
              Text('${balance.toStringAsFixed(0)} ${t('د.ع', 'IQD')}', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: balance > 0 ? _pink : Colors.green)),
              Text('${t('حد الدين', 'Credit limit')}: ${(customer['credit_limit'] as num? ?? 0).toStringAsFixed(0)} ${t('د.ع', 'IQD')}'),
            ]))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: _sale, icon: const Icon(Icons.add_shopping_cart), label: Text(t('سحب مواد / فاتورة', 'Issue materials / Sale'))),
              OutlinedButton.icon(onPressed: _payment, icon: const Icon(Icons.payments_outlined), label: Text(t('استلام دفعة', 'Receive payment'))),
            ]),
            const SizedBox(height: 18),
            Text(t('كشف الحساب', 'Account statement'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
            if (entries.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(t('لا توجد حركات مالية', 'No account entries')))),
            ...entries.map((entry) {
              final isPayment = entry['entry_type'] == 'payment';
              return Card(child: ListTile(
                leading: CircleAvatar(backgroundColor: (isPayment ? Colors.green : _pink).withOpacity(.1), child: Icon(isPayment ? Icons.call_received : Icons.receipt_long, color: isPayment ? Colors.green : _pink)),
                title: Text(entry['note']?.toString().isNotEmpty == true ? entry['note'].toString() : (isPayment ? t('استلام', 'Payment') : t('مبيعات / دين', 'Sale / Charge'))),
                subtitle: Text(entry['created_at'].toString().split('T').first),
                trailing: Text('${isPayment ? '-' : '+'}${(entry['amount'] as num).toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isPayment ? Colors.green : _pink)),
              ));
            }),
          ]);
        },
      ),
    );
  }
}

class CustomerSalePage extends StatefulWidget {
  final String centerId;
  final String lang;
  final Map<String, Object?> customer;
  const CustomerSalePage({super.key, required this.centerId, required this.lang, required this.customer});

  @override
  State<CustomerSalePage> createState() => _CustomerSalePageState();
}

class _CustomerSalePageState extends State<CustomerSalePage> {
  bool get _ar => widget.lang == 'ar';
  String t(String ar, String en) => _ar ? ar : en;
  final _quantity = TextEditingController(text: '1');
  final _price = TextEditingController(text: '0');
  final _paid = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _note = TextEditingController();
  List<Map<String, Object?>> _parts = [];
  final List<Map<String, Object?>> _cart = [];
  String? _selectedPartId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  @override
  void dispose() {
    _quantity.dispose(); _price.dispose(); _paid.dispose(); _discount.dispose(); _note.dispose();
    super.dispose();
  }

  Future<void> _loadParts() async {
    final rows = await AppDb.instance.parts(widget.centerId);
    if (!mounted) return;
    setState(() { _parts = rows; _loading = false; });
  }

  Map<String, Object?>? get _selectedPart {
    for (final part in _parts) {
      if (part['id'].toString() == _selectedPartId) return part;
    }
    return null;
  }

  double get _subtotal => _cart.fold<double>(0, (sum, item) => sum + (item['line_total'] as num).toDouble());
  double get _total => (_subtotal - (double.tryParse(_discount.text) ?? 0)).clamp(0, double.infinity).toDouble();

  void _addToCart() {
    final part = _selectedPart;
    final quantity = int.tryParse(_quantity.text) ?? 0;
    final price = double.tryParse(_price.text) ?? -1;
    if (part == null || quantity <= 0 || price < 0) return;
    final already = _cart.where((item) => item['part_id'] == part['id']).fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    final available = (part['quantity'] as num).toInt();
    if (already + quantity > available) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('الكمية المطلوبة أكبر من المتوفر', 'Requested quantity exceeds available stock'))));
      return;
    }
    setState(() {
      _cart.add({'part_id': part['id'].toString(), 'part_name': part['name'].toString(), 'quantity': quantity, 'unit_price': price, 'line_total': quantity * price});
      _quantity.text = '1';
    });
  }

  Future<void> _saveSale() async {
    final paid = double.tryParse(_paid.text) ?? 0;
    final discount = double.tryParse(_discount.text) ?? 0;
    if (_cart.isEmpty || paid < 0 || paid > _total || discount < 0 || discount > _subtotal) return;
    try {
      final invoice = await AppDb.instance.createCustomerSale(
        widget.centerId,
        widget.customer['id'].toString(),
        items: _cart,
        paid: paid,
        discount: discount,
        note: _note.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t('تم حفظ الفاتورة', 'Invoice saved')}: $invoice')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('فاتورة سحب مواد', 'Material issue invoice'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.customer['name'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _navy)),
        const SizedBox(height: 12),
        if (_parts.isEmpty) Text(t('أضف مواد إلى المخزن أولاً', 'Add inventory items first')),
        if (_parts.isNotEmpty) DropdownButtonFormField<String>(
          value: _selectedPartId,
          isExpanded: true,
          decoration: InputDecoration(labelText: t('اختر المادة', 'Select item')),
          items: _parts.map((part) => DropdownMenuItem(value: part['id'].toString(), child: Text('${part['name']} (${part['quantity']})', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) {
            final part = _parts.firstWhere((p) => p['id'].toString() == value);
            setState(() { _selectedPartId = value; _price.text = (part['sale_price'] as num).toString(); });
          },
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: _quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t('الكمية', 'Quantity')))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('سعر الوحدة', 'Unit price')))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _parts.isEmpty ? null : _addToCart, icon: const Icon(Icons.add), label: Text(t('إضافة إلى الفاتورة', 'Add to invoice'))),
        const SizedBox(height: 12),
        ..._cart.asMap().entries.map((entry) {
          final item = entry.value;
          return Card(child: ListTile(
            title: Text(item['part_name'].toString()),
            subtitle: Text('${item['quantity']} × ${(item['unit_price'] as num).toStringAsFixed(0)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text((item['line_total'] as num).toStringAsFixed(0)),
              IconButton(onPressed: () => setState(() => _cart.removeAt(entry.key)), icon: const Icon(Icons.delete_outline, color: _pink)),
            ]),
          ));
        }),
        const Divider(height: 28),
        _summary(t('المجموع', 'Subtotal'), _subtotal),
        TextField(controller: _discount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('الخصم', 'Discount')), onChanged: (_) => setState(() {})),
        _summary(t('الإجمالي', 'Total'), _total, bold: true),
        TextField(controller: _paid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('المبلغ المستلم الآن', 'Paid now'))),
        TextField(controller: _note, decoration: InputDecoration(labelText: t('ملاحظات الفاتورة', 'Invoice notes'))),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _cart.isEmpty ? null : _saveSale, icon: const Icon(Icons.save), label: Text(t('حفظ الفاتورة وخصم المواد', 'Save invoice & deduct stock'))),
        const SizedBox(height: 12),
        Text(t('الأسعار الافتراضية مأخوذة من سعر البيع للمادة. يمكنك تعديل سعر الوحدة قبل الإضافة لتطبيق سعر الجملة أو السعر الخاص.', 'Default prices use the item sale price. Edit the unit price to apply wholesale or special pricing.'), style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
      ]),
    );
  }

  Widget _summary(String label, double value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))), Text(value.toStringAsFixed(0), style: TextStyle(fontSize: bold ? 19 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: _navy))]),
  );
}
