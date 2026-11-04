import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';
import 'scanner_page.dart';
import 'customers_page.dart';
import 'ai_assistant_page.dart';
import 'firebase_options.dart';

const navy = Color(0xFF263A98);
const pink = Color(0xFFE90070);
const pale = Color(0xFFF4F6FC);

String tr(String lang, String key) {
  const ar = <String, String>{
    'app':'ALBYATE FOR SOLAR INVERTER','tagline':'إدارة صيانة الإنفيرترات والطاقة الشمسية',
    'login':'تسجيل الدخول','register':'إنشاء مركز جديد','center':'اسم المركز','owner':'اسم صاحب المركز',
    'username':'اسم المستخدم','password':'كلمة المرور','welcome':'مرحباً بك','dashboard':'الرئيسية',
    'devices':'الأجهزة والصيانة','inventory':'المخزن','finance':'الحسابات','customers':'الزبائن','settings':'الإعدادات','ai':'الذكاء الاصطناعي',
    'total_devices':'إجمالي الأجهزة','in_repair':'قيد الصيانة','completed':'مكتملة','parts':'قطع الغيار',
    'add_device':'تسجيل جهاز جديد','search':'ابحث بالسيريال أو الموديل أو الزبون',
    'serial':'الرقم التسلسلي','brand':'الشركة','model':'الموديل','power':'القدرة','customer':'اسم الزبون',
    'phone':'رقم الهاتف','fault':'العطل المبلغ عنه','status':'حالة الجهاز','label_photo':'صورة ملصق الجهاز',
    'scan_barcode':'مسح الباركود','read_label':'تصوير الملصق وقراءة الرقم','save':'حفظ','cancel':'إلغاء',
    'no_devices':'لا توجد أجهزة مسجلة بعد','add_part':'إضافة قطعة','part_name':'اسم القطعة','sku':'رمز القطعة',
    'quantity':'الكمية','purchase_price':'سعر الشراء','sale_price':'سعر البيع','minimum':'حد التنبيه',
    'no_parts':'لا توجد قطع في المخزن','income':'إيراد','expense':'مصروف','net':'الصافي','add_transaction':'إضافة حركة مالية',
    'amount':'المبلغ بالدينار','note':'ملاحظات','no_transactions':'لا توجد حركات مالية','language':'اللغة',
    'arabic':'العربية','english':'English','logout':'تسجيل الخروج','employees':'الموظفون والصلاحيات',
    'add_employee':'إضافة موظف','role':'الدور الوظيفي','technician':'فني صيانة','accountant':'موظف حسابات',
    'storekeeper':'أمين مخزن','owner_role':'صاحب المركز','name':'الاسم','repair':'تسجيل عملية صيانة',
    'diagnosis':'التشخيص','work_done':'الأعمال المنفذة','labor':'أجور الصيانة','parts_cost':'كلفة القطع',
    'received':'المبلغ المستلم','device_saved':'تم حفظ الجهاز','part_saved':'تمت إضافة القطعة','transaction_saved':'تم حفظ الحركة',
    'employee_saved':'تمت إضافة الموظف','invalid_login':'اسم المستخدم أو كلمة المرور غير صحيحة',
    'duplicate_serial':'هذا الرقم التسلسلي مسجل مسبقاً','required':'يرجى إكمال الحقول المطلوبة',
    'camera_error':'تعذر قراءة الملصق. حاول تصويره بوضوح وإضاءة جيدة.', 'scan_hint':'ضع الباركود داخل الإطار',
    'repair_history':'سجل الصيانة','sync_note':'المزامنة السحابية بين أجهزة المركز ستُفعّل في مرحلة ربط الخادم.',
    'local_note':'تُحفظ البيانات حالياً على هذا الهاتف وتعمل دون إنترنت.', 'empty':'لا توجد بيانات',
  };
  const en = <String, String>{
    'app':'ALBYATE FOR SOLAR INVERTER','tagline':'Solar inverter repair center management',
    'login':'Sign in','register':'Create a center','center':'Center name','owner':'Center owner name',
    'username':'Username','password':'Password','welcome':'Welcome','dashboard':'Dashboard',
    'devices':'Devices & Repairs','inventory':'Inventory','finance':'Finance','customers':'Customers','settings':'Settings','ai':'AI Assistant',
    'total_devices':'Total devices','in_repair':'In repair','completed':'Completed','parts':'Spare parts',
    'add_device':'Register device','search':'Search serial, model or customer',
    'serial':'Serial number','brand':'Brand','model':'Model','power':'Power','customer':'Customer name',
    'phone':'Phone number','fault':'Reported fault','status':'Device status','label_photo':'Device label photo',
    'scan_barcode':'Scan barcode','read_label':'Photograph label & read serial','save':'Save','cancel':'Cancel',
    'no_devices':'No devices registered yet','add_part':'Add part','part_name':'Part name','sku':'Part code',
    'quantity':'Quantity','purchase_price':'Purchase price','sale_price':'Sale price','minimum':'Low-stock alert',
    'no_parts':'No inventory parts yet','income':'Income','expense':'Expense','net':'Net','add_transaction':'Add transaction',
    'amount':'Amount (IQD)','note':'Notes','no_transactions':'No financial transactions','language':'Language',
    'arabic':'العربية','english':'English','logout':'Log out','employees':'Employees & permissions',
    'add_employee':'Add employee','role':'Role','technician':'Technician','accountant':'Accountant',
    'storekeeper':'Storekeeper','owner_role':'Center owner','name':'Name','repair':'Add repair record',
    'diagnosis':'Diagnosis','work_done':'Work performed','labor':'Labor cost','parts_cost':'Parts cost',
    'received':'Amount received','device_saved':'Device saved','part_saved':'Part added','transaction_saved':'Transaction saved',
    'employee_saved':'Employee added','invalid_login':'Incorrect username or password',
    'duplicate_serial':'This serial number is already registered','required':'Please complete required fields',
    'camera_error':'Could not read the label. Retake it with better focus and lighting.', 'scan_hint':'Place the barcode inside the frame',
    'repair_history':'Repair history','sync_note':'Cloud sync between your center devices will be enabled in the server-integration phase.',
    'local_note':'Data is currently stored on this phone and works offline.','empty':'No data',
  };
  return (lang == 'ar' ? ar : en)[key] ?? key;
}

Future<void> saveSession(Map<String, Object?> s) async {
  final p = await SharedPreferences.getInstance();
  await p.setString('center_id', s['center_id'].toString());
  await p.setString('user_id', s['user_id'].toString());
  await p.setString('center_name', s['center_name'].toString());
  await p.setString('user_name', s['user_name'].toString());
  await p.setString('role', s['role'].toString());
}

class AlbyateApp extends StatefulWidget {
  const AlbyateApp({super.key});
  @override
  State<AlbyateApp> createState() => _AlbyateAppState();
}

class _AlbyateAppState extends State<AlbyateApp> {
  Map<String, Object?>? session;
  String lang = 'ar';
  bool ready = false;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getString('center_id');
    lang = p.getString('lang') ?? 'ar';
    if (id != null) {
      try {
        session = await AppDb.instance.validSession(p.getString('user_id') ?? '', id);
      } catch (e) {
        debugPrint('Session validation failed: $e');
        session = null;
      }
    }
    if (mounted) setState(() => ready = true);
  }
  Future<void> _setLang(String value) async {
    lang = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', value);
    if (mounted) setState(() {});
  }
  Future<void> _login(Map<String, Object?> value) async {
    await saveSession(value);
    if (mounted) setState(() => session = value);
  }
  Future<void> _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('center_id'); await p.remove('user_id'); await p.remove('center_name'); await p.remove('user_name'); await p.remove('role');
    if (mounted) setState(() => session = null);
  }
  @override
  Widget build(BuildContext context) {
    if (!ready) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALBYATE FOR SOLAR INVERTER',
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy), scaffoldBackgroundColor: pale, appBarTheme: const AppBarTheme(backgroundColor: pale, foregroundColor: navy, centerTitle: false), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
      builder: (context, child) => Directionality(textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: child ?? const SizedBox()),
      home: session == null
          ? LoginScreen(lang: lang, onLanguage: _setLang, onLogin: _login)
          : HomeShell(session: session!, lang: lang, onLanguage: _setLang, onLogout: _logout),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String lang; final ValueChanged<String> onLanguage; final ValueChanged<Map<String, Object?>> onLogin;
  const LoginScreen({super.key, required this.lang, required this.onLanguage, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController(); final pass = TextEditingController(); bool busy = false; String? error;
  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(children: [
      Align(alignment: AlignmentDirectional.topEnd, child: TextButton.icon(onPressed: () => widget.onLanguage(l == 'ar' ? 'en' : 'ar'), icon: const Icon(Icons.language), label: Text(l == 'ar' ? 'English' : 'العربية'))),
      Image.asset('assets/albyate_logo.png', height: 150, fit: BoxFit.contain),
      const SizedBox(height: 8), Text(tr(l,'tagline'), style: const TextStyle(color: Colors.blueGrey)), const SizedBox(height: 28),
      Text(tr(l,'login'), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 18),
      TextField(controller: user, decoration: InputDecoration(labelText: tr(l,'username'), prefixIcon: const Icon(Icons.person))), const SizedBox(height: 12),
      TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: tr(l,'password'), prefixIcon: const Icon(Icons.lock))),
      if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 14), SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: busy ? null : () async {
        setState(() {busy = true; error = null;});
        final result = await AppDb.instance.login(user.text, pass.text);
        if (!mounted) return;
        setState(() => busy = false);
        if (result == null) { setState(() => error = tr(l,'invalid_login')); } else { widget.onLogin(result); }
      }, child: busy ? const CircularProgressIndicator(color: Colors.white) : Text(tr(l,'login')))),
      const SizedBox(height: 10), SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () async {
        final result = await Navigator.push<Map<String,Object?>>(context, MaterialPageRoute(builder: (_) => RegisterCenterScreen(lang: l)));
        if (result != null) widget.onLogin(result);
      }, icon: const Icon(Icons.add_business), label: Text(tr(l,'register')))),
      const SizedBox(height: 22), Text(tr(l,'local_note'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
    ]))))));
  }
}

class RegisterCenterScreen extends StatefulWidget {
  final String lang; const RegisterCenterScreen({super.key, required this.lang});
  @override
  State<RegisterCenterScreen> createState() => _RegisterCenterScreenState();
}
class _RegisterCenterScreenState extends State<RegisterCenterScreen> {
  final center = TextEditingController(), owner = TextEditingController(), username = TextEditingController(), password = TextEditingController(); bool busy = false;
  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    return Scaffold(appBar: AppBar(title: Text(tr(l,'register'))), body: ListView(padding: const EdgeInsets.all(18), children: [
      TextField(controller: center, decoration: InputDecoration(labelText: tr(l,'center'))), const SizedBox(height: 12),
      TextField(controller: owner, decoration: InputDecoration(labelText: tr(l,'owner'))), const SizedBox(height: 12),
      TextField(controller: username, decoration: InputDecoration(labelText: tr(l,'username'))), const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: tr(l,'password'))), const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : () async {
        if ([center.text,owner.text,username.text,password.text].any((e) => e.trim().isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(l,'required')))); return; }
        if (password.text.length < 6) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l == 'ar' ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : 'Password must be at least 6 characters'))); return; }
        setState(() => busy = true);
        try {
          final s = await AppDb.instance.createCenter(centerName: center.text.trim(), ownerName: owner.text.trim(), username: username.text.trim(), password: password.text);
          if (mounted) Navigator.pop(context, s);
        } catch (_) {
          if (mounted) { setState(() => busy = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l == 'ar' ? 'اسم المستخدم مستخدم مسبقاً على هذا الهاتف' : 'Username already exists on this phone'))); }
        }
      }, child: busy ? const CircularProgressIndicator(color: Colors.white) : Text(tr(l,'register'))),
    ]));
  }
}

class HomeShell extends StatefulWidget {
  final Map<String,Object?> session; final String lang; final ValueChanged<String> onLanguage; final VoidCallback onLogout;
  const HomeShell({super.key, required this.session, required this.lang, required this.onLanguage, required this.onLogout});
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  String get centerId => widget.session['center_id'].toString();
  String get role => widget.session['role'].toString();
  List<String> get tabs => role == 'technician' ? ['dashboard','devices'] : role == 'accountant' ? ['dashboard','finance','customers'] : role == 'storekeeper' ? ['dashboard','inventory','customers'] : ['dashboard','devices','inventory','customers','finance','settings'];
  IconData iconFor(String t) => {'dashboard':Icons.dashboard_outlined,'devices':Icons.build_outlined,'inventory':Icons.inventory_2_outlined,'customers':Icons.people_alt_outlined,'finance':Icons.account_balance_wallet_outlined,'settings':Icons.settings_outlined}[t]!;
  @override
  Widget build(BuildContext context) {
    final l = widget.lang; final current = tabs[index.clamp(0, tabs.length-1)];
    final pages = <String,Widget>{
      'dashboard':DashboardPage(centerId: centerId, lang: l, centerName: widget.session['center_name'].toString()),
      'devices':DevicesPage(centerId: centerId, lang: l, userName: widget.session['user_name'].toString()),
      'inventory':InventoryPage(centerId: centerId, lang: l),
      'finance':FinancePage(centerId: centerId, lang: l),
      'customers':CustomersPage(centerId: centerId, lang: l),
      'settings':SettingsPage(centerId: centerId, lang: l, role: role, onLanguage: widget.onLanguage, onLogout: widget.onLogout),
    };
    return Scaffold(body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/albyate_logo.png', width: 54, height: 42, fit: BoxFit.cover)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.session['center_name'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)), Text(widget.session['user_name'].toString(), style: const TextStyle(fontSize: 11, color: Colors.blueGrey))])), IconButton(
        tooltip: 'ALBYATE AI',
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AiAssistantPage(centerName: widget.session['center_name'].toString(), lang: l),
        )),
        icon: const Icon(Icons.auto_awesome, color: pink),
      ),
      IconButton(onPressed: () => widget.onLanguage(l == 'ar' ? 'en' : 'ar'), icon: const Icon(Icons.language, color: navy))])),
      Expanded(child: IndexedStack(index: tabs.indexOf(current), children: tabs.map((t) => pages[t]!).toList())),
    ])), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i), destinations: tabs.map((t) => NavigationDestination(icon: Icon(iconFor(t)), label: tr(l,t))).toList()));
  }
}

class DashboardPage extends StatefulWidget {
  final String centerId, lang, centerName; const DashboardPage({super.key, required this.centerId, required this.lang, required this.centerName});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(future: Future.wait([AppDb.instance.devices(widget.centerId), AppDb.instance.parts(widget.centerId), AppDb.instance.financeSummary(widget.centerId)]), builder: (context, snap) {
    final l = widget.lang; final devices = snap.data?[0] as List<Map<String,Object?>>? ?? []; final parts = snap.data?[1] as List<Map<String,Object?>>? ?? []; final finance = snap.data?[2] as Map<String,double>? ?? {};
    final inRepair = devices.where((d) => d['status'] == 'received' || d['status'] == 'in_progress').length;
    final completed = devices.where((d) => d['status'] == 'completed' || d['status'] == 'delivered').length;
    return RefreshIndicator(onRefresh: () async => setState(() {}), child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF4359C3)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tr(l,'welcome'), style: const TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text(widget.centerName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(tr(l,'tagline'), style: const TextStyle(color: Colors.white70, fontSize: 12))]),
      ), const SizedBox(height: 16),
      GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 1.65, crossAxisSpacing: 10, mainAxisSpacing: 10, children: [
        _stat(tr(l,'total_devices'), '${devices.length}', Icons.solar_power, navy), _stat(tr(l,'in_repair'), '$inRepair', Icons.handyman, pink), _stat(tr(l,'completed'), '$completed', Icons.task_alt, Colors.green), _stat(tr(l,'parts'), '${parts.length}', Icons.inventory_2, Colors.deepOrange),
      ]), const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l == 'ar' ? 'ملخص الحسابات (د.ع)' : 'Finance summary (IQD)', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 12), _moneyLine(tr(l,'income'), finance['income'] ?? 0, Colors.green), _moneyLine(tr(l,'expense'), finance['expense'] ?? 0, pink), const Divider(), _moneyLine(tr(l,'net'), finance['net'] ?? 0, navy)]))),
      const SizedBox(height: 10), Text(tr(l,'local_note'), style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
    ]));
  });
  Widget _stat(String title, String value, IconData icon, Color color) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [CircleAvatar(backgroundColor: color.withOpacity(.1), child: Icon(icon,color:color)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 21,fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontSize: 11,color:Colors.blueGrey), maxLines: 2)]))])));
  Widget _moneyLine(String label, double value, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label)), Text(value.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold,color:c))]));
}

class DevicesPage extends StatefulWidget {
  final String centerId, lang, userName; const DevicesPage({super.key, required this.centerId, required this.lang, required this.userName});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}
class _DevicesPageState extends State<DevicesPage> {
  final search = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16,12,16,8), child: Row(children: [Expanded(child: Text(tr(l,'devices'), style: const TextStyle(fontSize: 21,fontWeight: FontWeight.bold,color:navy))), FilledButton.icon(onPressed: _addDevice, icon: const Icon(Icons.add), label: Text(tr(l,'add_device')))])), Padding(padding: const EdgeInsets.symmetric(horizontal:16), child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr(l,'search')))), Expanded(child: FutureBuilder<List<Map<String,Object?>>>(future: AppDb.instance.devices(widget.centerId, query: search.text), builder: (context,snap) {
      final rows = snap.data ?? [];
      if (rows.isEmpty) return Center(child: Text(tr(l,'no_devices'), style: const TextStyle(color:Colors.blueGrey)));
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: rows.length, itemBuilder: (_,i) { final d=rows[i]; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFFE9ECFA), child: const Icon(Icons.solar_power,color:navy)), title: Text('${d['serial']}',style: const TextStyle(fontWeight:FontWeight.bold)), subtitle: Text('${d['brand'] ?? ''} ${d['model'] ?? ''}\n${d['customer_name'] ?? ''}',maxLines:2), isThreeLine:true, trailing: const Icon(Icons.chevron_right), onTap: () => _deviceDetails(d))); });
    }))]);
  }
  Future<void> _addDevice() async { final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DeviceForm(centerId: widget.centerId, lang: widget.lang))); if (changed == true && mounted) setState(() {}); }
  Future<void> _deviceDetails(Map<String,Object?> d) async {
    final l=widget.lang;
    await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx).viewInsets.bottom+24), child: SingleChildScrollView(child: Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisSize:MainAxisSize.min, children: [Text('${d['serial']}',style: const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy)), const SizedBox(height:8), Text('${d['brand'] ?? ''} ${d['model'] ?? ''} • ${d['power'] ?? ''}'), Text('${tr(l,'customer')}: ${d['customer_name'] ?? ''}'), Text('${tr(l,'phone')}: ${d['customer_phone'] ?? ''}'), Text('${tr(l,'fault')}: ${d['fault'] ?? ''}'), if ((d['label_photo'] ?? '').toString().isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical:12), child: Image.file(File(d['label_photo'].toString()),height:130)), const SizedBox(height:12), FilledButton.icon(onPressed: () { Navigator.pop(ctx); _addRepair(d); }, icon: const Icon(Icons.build), label: Text(tr(l,'repair')))]))));
  }
  Future<void> _addRepair(Map<String,Object?> d) async {
    final l=widget.lang; final diagnosis=TextEditingController(), work=TextEditingController(), labor=TextEditingController(text:'0'), parts=TextEditingController(text:'0'), received=TextEditingController(text:'0');
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(tr(l,'repair')),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:diagnosis,decoration:InputDecoration(labelText:tr(l,'diagnosis'))),TextField(controller:work,decoration:InputDecoration(labelText:tr(l,'work_done'))),TextField(controller:labor,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr(l,'labor'))),TextField(controller:parts,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr(l,'parts_cost'))),TextField(controller:received,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:tr(l,'received')))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr(l,'cancel'))),FilledButton(onPressed:() async { await AppDb.instance.addRepair(widget.centerId,d['id'].toString(),technician:widget.userName,diagnosis:diagnosis.text,workDone:work.text,labor:double.tryParse(labor.text)??0,parts:double.tryParse(parts.text)??0,received:double.tryParse(received.text)??0); if(ctx.mounted) Navigator.pop(ctx); if(mounted)setState((){}); },child:Text(tr(l,'save')))]));
    if(mounted)setState((){});
  }
}

class DeviceForm extends StatefulWidget {
  final String centerId, lang; const DeviceForm({super.key,required this.centerId,required this.lang});
  @override
  State<DeviceForm> createState()=>_DeviceFormState();
}
class _DeviceFormState extends State<DeviceForm> {
  final serial=TextEditingController(),brand=TextEditingController(),model=TextEditingController(),power=TextEditingController(),customer=TextEditingController(),phone=TextEditingController(),fault=TextEditingController();
  String? photo; bool busy=false;
  Future<void> _barcode() async { final value=await Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const ScannerPage())); if(value!=null && mounted) setState(()=>serial.text=value); }
  Future<void> _photoOcr() async {
    final l=widget.lang;
    try {
      final x=await ImagePicker().pickImage(source:ImageSource.camera,imageQuality:88);
      if(x==null)return;
      final dir=await getApplicationDocumentsDirectory(); final target='${dir.path}/label_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(target); photo=target;
      final recognizer=TextRecognizer(script:TextRecognitionScript.latin);
      final result=await recognizer.processImage(InputImage.fromFilePath(target)); await recognizer.close();
      final all=result.text;
      final digitCandidates=RegExp(r'\b\d{8,24}\b').allMatches(all).map((m)=>m.group(0)!).toList();
      final mixedCandidates=RegExp(r'\b[A-Z0-9][A-Z0-9-]{7,23}\b',caseSensitive:false).allMatches(all).map((m)=>m.group(0)!).toList();
      if(digitCandidates.isNotEmpty) serial.text=digitCandidates.last;
      else if(mixedCandidates.isNotEmpty) serial.text=mixedCandidates.last;
      if(mounted) { setState((){}); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(serial.text.isNotEmpty ? (l=='ar'?'تمت قراءة الرقم تلقائياً':'Serial read automatically') : tr(l,'camera_error')))); }
    } catch (_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(l,'camera_error')))); }
  }
  @override
  Widget build(BuildContext context){final l=widget.lang; return Scaffold(appBar:AppBar(title:Text(tr(l,'add_device'))),body:ListView(padding:const EdgeInsets.all(16),children:[
    TextField(controller:serial,decoration:InputDecoration(labelText:tr(l,'serial'),prefixIcon:const Icon(Icons.qr_code_2))), const SizedBox(height:8),
    Row(children:[Expanded(child:OutlinedButton.icon(onPressed:_barcode,icon:const Icon(Icons.qr_code_scanner),label:Text(tr(l,'scan_barcode')))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:_photoOcr,icon:const Icon(Icons.document_scanner),label:Text(tr(l,'read_label'))))]),
    if(photo!=null) Padding(padding:const EdgeInsets.symmetric(vertical:10),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(photo!),height:150,fit:BoxFit.contain))),
    _field(brand,tr(l,'brand')), _field(model,tr(l,'model')), _field(power,tr(l,'power')), _field(customer,tr(l,'customer')), _field(phone,tr(l,'phone'),keyboard:TextInputType.phone), _field(fault,tr(l,'fault'),maxLines:3), const SizedBox(height:14),
    FilledButton(onPressed:busy?null:()async{if(serial.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(l,'required'))));return;} setState(()=>busy=true);try{await AppDb.instance.addDevice(widget.centerId,{'serial':serial.text.trim(),'brand':brand.text.trim(),'model':model.text.trim(),'power':power.text.trim(),'customer_name':customer.text.trim(),'customer_phone':phone.text.trim(),'fault':fault.text.trim(),'status':'received','label_photo':photo});if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(l,'device_saved'))));Navigator.pop(context,true);}}catch(_){if(mounted){setState(()=>busy=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(l,'duplicate_serial'))));}}},child:busy?const CircularProgressIndicator(color:Colors.white):Text(tr(l,'save')))
  ]));}
  Widget _field(TextEditingController c,String label,{TextInputType? keyboard,int maxLines=1})=>Padding(padding:const EdgeInsets.only(top:10),child:TextField(controller:c,keyboardType:keyboard,maxLines:maxLines,decoration:InputDecoration(labelText:label)));
}

class InventoryPage extends StatefulWidget {final String centerId,lang;const InventoryPage({super.key,required this.centerId,required this.lang});@override State<InventoryPage> createState()=>_InventoryPageState();}
class _InventoryPageState extends State<InventoryPage>{
  Future<void> _add()async{final l=widget.lang;final name=TextEditingController(),sku=TextEditingController(),qty=TextEditingController(text:'0'),buy=TextEditingController(text:'0'),sell=TextEditingController(text:'0'),min=TextEditingController(text:'1');await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(tr(l,'add_part')),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[_tf(name,tr(l,'part_name')), _tf(sku,tr(l,'sku')),_tf(qty,tr(l,'quantity'),num:true),_tf(buy,tr(l,'purchase_price'),num:true),_tf(sell,tr(l,'sale_price'),num:true),_tf(min,tr(l,'minimum'),num:true)])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr(l,'cancel'))),FilledButton(onPressed:()async{await AppDb.instance.addPart(widget.centerId,name:name.text,sku:sku.text,quantity:int.tryParse(qty.text)??0,purchase:double.tryParse(buy.text)??0,sale:double.tryParse(sell.text)??0,minQty:int.tryParse(min.text)??1);if(ctx.mounted)Navigator.pop(ctx);if(mounted)setState((){});},child:Text(tr(l,'save')))]));}
  @override Widget build(BuildContext context){final l=widget.lang;return Column(children:[Padding(padding:const EdgeInsets.all(16),child:Row(children:[Expanded(child:Text(tr(l,'inventory'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy))),FilledButton.icon(onPressed:_add,icon:const Icon(Icons.add),label:Text(tr(l,'add_part')))])),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:AppDb.instance.parts(widget.centerId),builder:(context,s){final rows=s.data??[];if(rows.isEmpty)return Center(child:Text(tr(l,'no_parts')));return ListView.builder(itemCount:rows.length,padding:const EdgeInsets.all(12),itemBuilder:(_,i){final p=rows[i];final low=(p['quantity'] as int)<=(p['min_quantity'] as int);return Card(child:ListTile(leading:CircleAvatar(backgroundColor:low?pink.withOpacity(.1):navy.withOpacity(.1),child:Icon(Icons.memory,color:low?pink:navy)),title:Text(p['name'].toString()),subtitle:Text('${tr(l,'sku')}: ${p['sku']??'-'}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('${p['quantity']}',style:TextStyle(fontWeight:FontWeight.bold,color:low?pink:navy)),Text(tr(l,'quantity'),style:const TextStyle(fontSize:10))])));});}))]);}
}

class FinancePage extends StatefulWidget {final String centerId,lang;const FinancePage({super.key,required this.centerId,required this.lang});@override State<FinancePage> createState()=>_FinancePageState();}
class _FinancePageState extends State<FinancePage>{
  Future<void> _add(String type)async{final l=widget.lang;final amount=TextEditingController(),note=TextEditingController();await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(type=='income'?tr(l,'income'):tr(l,'expense')),content:Column(mainAxisSize:MainAxisSize.min,children:[_tf(amount,tr(l,'amount'),num:true),_tf(note,tr(l,'note'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(tr(l,'cancel'))),FilledButton(onPressed:()async{final a=double.tryParse(amount.text)??0;if(a<=0)return;await AppDb.instance.addTransaction(widget.centerId,type:type,amount:a,note:note.text);if(ctx.mounted)Navigator.pop(ctx);if(mounted)setState((){});},child:Text(tr(l,'save')))]));}
  @override Widget build(BuildContext context){final l=widget.lang;return Column(children:[Padding(padding:const EdgeInsets.all(16),child:Row(children:[Expanded(child:Text(tr(l,'finance'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold,color:navy))),IconButton(onPressed:()=>_add('income'),icon:const Icon(Icons.add_circle,color:Colors.green)),IconButton(onPressed:()=>_add('expense'),icon:const Icon(Icons.remove_circle,color:pink))])),Expanded(child:FutureBuilder<List<dynamic>>(future:Future.wait([AppDb.instance.financeSummary(widget.centerId),AppDb.instance.transactions(widget.centerId)]),builder:(context,s){final summary = s.data == null ? <String,double>{} : s.data![0] as Map<String,double>;final rows=s.data?[1] as List<Map<String,Object?>>? ?? [];return ListView(padding:const EdgeInsets.all(14),children:[Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[_money(tr(l,'income'),summary['income']??0,Colors.green),_money(tr(l,'expense'),summary['expense']??0,pink),const Divider(),_money(tr(l,'net'),summary['net']??0,navy)]))),const SizedBox(height:12),...rows.map((r)=>Card(child:ListTile(leading:Icon(r['type']=='income'?Icons.arrow_downward:Icons.arrow_upward,color:r['type']=='income'?Colors.green:pink),title:Text(r['note']?.toString().isNotEmpty==true?r['note'].toString():(r['type']=='income'?tr(l,'income'):tr(l,'expense'))),trailing:Text((r['amount'] as num).toStringAsFixed(0)))))]);}))]);}
  Widget _money(String t,double v,Color c)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[Expanded(child:Text(t)),Text(v.toStringAsFixed(0),style:TextStyle(fontWeight:FontWeight.bold,color:c,fontSize:17))]));
}

class SettingsPage extends StatefulWidget {
  final String centerId, lang, role;
  final ValueChanged<String> onLanguage;
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.centerId, required this.lang, required this.role, required this.onLanguage, required this.onLogout});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _employee() async {
    final l = widget.lang;
    final name = TextEditingController();
    final user = TextEditingController();
    final pass = TextEditingController();
    String selectedRole = 'technician';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(tr(l, 'add_employee')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(name, tr(l, 'name')),
                _tf(user, tr(l, 'username')),
                _tf(pass, tr(l, 'password')),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: tr(l, 'role')),
                  items: [
                    DropdownMenuItem(value: 'technician', child: Text(tr(l, 'technician'))),
                    DropdownMenuItem(value: 'accountant', child: Text(tr(l, 'accountant'))),
                    DropdownMenuItem(value: 'storekeeper', child: Text(tr(l, 'storekeeper'))),
                  ],
                  onChanged: (value) => setLocal(() => selectedRole = value ?? 'technician'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr(l, 'cancel'))),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || user.text.trim().isEmpty || pass.text.length < 6) return;
                try {
                  await AppDb.instance.addEmployee(
                    widget.centerId,
                    name: name.text.trim(),
                    username: user.text.trim(),
                    password: pass.text,
                    role: selectedRole,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Username already exists')),
                    );
                  }
                }
              },
              child: Text(tr(l, 'save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lang;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(tr(l, 'settings'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: navy)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language, color: navy),
            title: Text(tr(l, 'language')),
            trailing: DropdownButton<String>(
              value: l,
              items: [
                DropdownMenuItem(value: 'ar', child: Text(tr(l, 'arabic'))),
                DropdownMenuItem(value: 'en', child: Text(tr(l, 'english'))),
              ],
              onChanged: (value) { if (value != null) widget.onLanguage(value); },
            ),
          ),
        ),
        if (widget.role == 'owner')
          Card(
            child: ListTile(
              leading: const Icon(Icons.people, color: navy),
              title: Text(tr(l, 'employees')),
              trailing: IconButton(onPressed: _employee, icon: const Icon(Icons.person_add_alt_1, color: pink)),
            ),
          ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_sync, color: navy),
            title: Text(l == 'ar' ? 'مزامنة أجهزة المركز' : 'Center device sync'),
            subtitle: Text(tr(l, 'sync_note'), style: const TextStyle(fontSize: 11)),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.offline_bolt, color: navy),
            title: Text(l == 'ar' ? 'العمل دون إنترنت' : 'Offline mode'),
            subtitle: Text(tr(l, 'local_note'), style: const TextStyle(fontSize: 11)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: widget.onLogout, icon: const Icon(Icons.logout), label: Text(tr(l, 'logout'))),
      ],
    );
  }
}

Widget _tf(TextEditingController c, String label, {bool num = false}) => Padding(
  padding: const EdgeInsets.only(top: 8),
  child: TextField(
    controller: c,
    keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    decoration: InputDecoration(labelText: label),
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase is optional for the local/offline parts of ALBYATE.
  // The AI chat is enabled only when Firebase initialization succeeds.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    } catch (e) {
      debugPrint('ALBYATE App Check initialization warning: $e');
    }
  } catch (e) {
    debugPrint('ALBYATE Firebase initialization warning: $e');
  }

  runApp(const AlbyateApp());
}
