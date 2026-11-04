import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  Database? _db;
  final _uuid = const Uuid();

  String newId() => _uuid.v4();
  // Versioned, salted PBKDF2-HMAC-SHA256. Legacy SHA-256 is accepted only
  // during login and upgraded in place, preserving existing accounts.
  String hashPassword(String value) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    return 'pbkdf2_sha256\$120000\$${base64Url.encode(salt)}\$${base64Url.encode(_pbkdf2(value, salt))}';
  }

  List<int> _pbkdf2(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final input = [...salt, 0, 0, 0, 1];
    var u = hmac.convert(input).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < 120000; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) { result[j] ^= u[j]; }
    }
    return result;
  }

  bool _verifyPassword(String password, String stored) {
    if (!stored.startsWith('pbkdf2_sha256\$')) {
      return _constantTimeEquals(sha256.convert(utf8.encode(password)).toString(), stored);
    }
    final fields = stored.split('\$');
    if (fields.length != 4 || fields[1] != '120000') return false;
    try {
      return _constantTimeEquals(base64Url.encode(_pbkdf2(password, base64Url.decode(fields[2]))), fields[3]);
    } catch (_) { return false; }
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) { difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i); }
    return difference == 0;
  }

  Future<Map<String, Object?>?> validSession(String userId, String centerId) async {
    final db = await database;
    final rows = await db.rawQuery('''SELECT users.*, centers.name AS center_name
      FROM users JOIN centers ON centers.id = users.center_id
      WHERE users.id = ? AND users.center_id = ? AND users.active = 1 LIMIT 1''', [userId, centerId]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return {'center_id': r['center_id'], 'user_id': r['id'], 'center_name': r['center_name'], 'user_name': r['name'], 'role': r['role']};
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      p.join(base, 'albyate_center.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE centers (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, owner_name TEXT NOT NULL,
          username TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL, created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE users (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, name TEXT NOT NULL,
          username TEXT NOT NULL, password_hash TEXT NOT NULL, role TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          UNIQUE(center_id, username)
        )''');
        await db.execute('''CREATE TABLE customers (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, name TEXT NOT NULL,
          phone TEXT, address TEXT, notes TEXT,
          price_type TEXT NOT NULL DEFAULT 'retail',
          credit_limit REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE customer_ledger (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, customer_id TEXT NOT NULL,
          entry_type TEXT NOT NULL, amount REAL NOT NULL,
          currency TEXT NOT NULL DEFAULT 'IQD', note TEXT, reference_id TEXT,
          created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE sales_invoices (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, customer_id TEXT NOT NULL,
          invoice_no TEXT NOT NULL, subtotal REAL NOT NULL, discount REAL NOT NULL DEFAULT 0,
          total REAL NOT NULL, paid REAL NOT NULL DEFAULT 0,
          currency TEXT NOT NULL DEFAULT 'IQD', status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE sales_invoice_items (
          id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, part_id TEXT NOT NULL,
          part_name TEXT NOT NULL, quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL, line_total REAL NOT NULL
        )''');
        await db.execute('''CREATE TABLE devices (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, serial TEXT NOT NULL,
          brand TEXT, model TEXT, power TEXT, customer_name TEXT, customer_phone TEXT,
          fault TEXT, status TEXT NOT NULL, label_photo TEXT, created_at TEXT NOT NULL,
          UNIQUE(center_id, serial)
        )''');
        await db.execute('''CREATE TABLE repairs (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, device_id TEXT NOT NULL,
          technician TEXT, diagnosis TEXT, work_done TEXT, labor_cost REAL NOT NULL DEFAULT 0,
          parts_cost REAL NOT NULL DEFAULT 0, received_amount REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE parts (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, name TEXT NOT NULL,
          sku TEXT, quantity INTEGER NOT NULL DEFAULT 0,
          purchase_price REAL NOT NULL DEFAULT 0, sale_price REAL NOT NULL DEFAULT 0,
          min_quantity INTEGER NOT NULL DEFAULT 1
        )''');
        await db.execute('''CREATE TABLE stock_movements (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, part_id TEXT NOT NULL,
          movement_type TEXT NOT NULL, quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL DEFAULT 0, note TEXT, created_at TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE transactions (
          id TEXT PRIMARY KEY, center_id TEXT NOT NULL, type TEXT NOT NULL,
          amount REAL NOT NULL, note TEXT, created_at TEXT NOT NULL
        )''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE customers ADD COLUMN address TEXT');
          await db.execute("ALTER TABLE customers ADD COLUMN price_type TEXT NOT NULL DEFAULT 'retail'");
          await db.execute('ALTER TABLE customers ADD COLUMN credit_limit REAL NOT NULL DEFAULT 0');
          await db.execute('''CREATE TABLE customer_ledger (
            id TEXT PRIMARY KEY, center_id TEXT NOT NULL, customer_id TEXT NOT NULL,
            entry_type TEXT NOT NULL, amount REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'IQD', note TEXT, reference_id TEXT,
            created_at TEXT NOT NULL
          )''');
          await db.execute('''CREATE TABLE sales_invoices (
            id TEXT PRIMARY KEY, center_id TEXT NOT NULL, customer_id TEXT NOT NULL,
            invoice_no TEXT NOT NULL, subtotal REAL NOT NULL, discount REAL NOT NULL DEFAULT 0,
            total REAL NOT NULL, paid REAL NOT NULL DEFAULT 0,
            currency TEXT NOT NULL DEFAULT 'IQD', status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )''');
          await db.execute('''CREATE TABLE sales_invoice_items (
            id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, part_id TEXT NOT NULL,
            part_name TEXT NOT NULL, quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL, line_total REAL NOT NULL
          )''');
        }
      },
    );
    return _db!;
  }

  Future<Map<String, Object?>> createCenter({required String centerName, required String ownerName, required String username, required String password}) async {
    final db = await database;
    final centerId = newId();
    final userId = newId();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('centers', {
        'id': centerId, 'name': centerName, 'owner_name': ownerName,
        'username': username, 'password_hash': hashPassword(password), 'created_at': now,
      });
      await txn.insert('users', {
        'id': userId, 'center_id': centerId, 'name': ownerName,
        'username': username, 'password_hash': hashPassword(password), 'role': 'owner', 'active': 1,
      });
    });
    return {'center_id': centerId, 'user_id': userId, 'center_name': centerName, 'user_name': ownerName, 'role': 'owner'};
  }

  Future<Map<String, Object?>?> login(String username, String password) async {
    final db = await database;
    final rows = await db.rawQuery('''SELECT users.*, centers.name AS center_name
      FROM users JOIN centers ON centers.id = users.center_id
      WHERE users.username = ? AND users.active = 1''', [username.trim()]);
    Map<String, Object?>? matched;
    for (final row in rows) {
      if (_verifyPassword(password, row['password_hash'] as String)) { matched = row; break; }
    }
    if (matched == null) return null;
    if (!(matched['password_hash'] as String).startsWith('pbkdf2_sha256\$')) {
      await db.update('users', {'password_hash': hashPassword(password)}, where: 'id = ?', whereArgs: [matched['id']]);
    }
    final r = matched;
    return {'center_id': r['center_id'], 'user_id': r['id'], 'center_name': r['center_name'], 'user_name': r['name'], 'role': r['role']};
  }

  Future<List<Map<String, Object?>>> devices(String centerId, {String query = ''}) async {
    final db = await database;
    if (query.trim().isEmpty) return db.query('devices', where: 'center_id = ?', whereArgs: [centerId], orderBy: 'created_at DESC');
    return db.query('devices', where: 'center_id = ? AND (serial LIKE ? OR model LIKE ? OR customer_name LIKE ?)', whereArgs: [centerId, '%$query%', '%$query%', '%$query%'], orderBy: 'created_at DESC');
  }

  Future<void> addDevice(String centerId, Map<String, Object?> data) async {
    final db = await database;
    await db.insert('devices', {'id': newId(), 'center_id': centerId, ...data, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, Object?>>> parts(String centerId) async {
    final db = await database;
    return db.query('parts', where: 'center_id = ?', whereArgs: [centerId], orderBy: 'name COLLATE NOCASE');
  }

  Future<void> addPart(String centerId, {required String name, required String sku, required int quantity, required double purchase, required double sale, required int minQty}) async {
    final db = await database;
    final id = newId();
    await db.transaction((txn) async {
      await txn.insert('parts', {'id': id, 'center_id': centerId, 'name': name, 'sku': sku, 'quantity': quantity, 'purchase_price': purchase, 'sale_price': sale, 'min_quantity': minQty});
      if (quantity > 0) {
        await txn.insert('stock_movements', {'id': newId(), 'center_id': centerId, 'part_id': id, 'movement_type': 'in', 'quantity': quantity, 'unit_price': purchase, 'note': 'Opening stock', 'created_at': DateTime.now().toIso8601String()});
      }
    });
  }

  Future<void> addTransaction(String centerId, {required String type, required double amount, required String note}) async {
    final db = await database;
    await db.insert('transactions', {'id': newId(), 'center_id': centerId, 'type': type, 'amount': amount, 'note': note, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<Map<String, double>> financeSummary(String centerId) async {
    final db = await database;
    final rows = await db.query('transactions', where: 'center_id = ?', whereArgs: [centerId]);
    double income = 0, expense = 0;
    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') income += amount; else expense += amount;
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  Future<List<Map<String, Object?>>> transactions(String centerId) async {
    final db = await database;
    return db.query('transactions', where: 'center_id = ?', whereArgs: [centerId], orderBy: 'created_at DESC');
  }

  Future<void> addRepair(String centerId, String deviceId, {required String technician, required String diagnosis, required String workDone, required double labor, required double parts, required double received}) async {
    final db = await database;
    await db.insert('repairs', {'id': newId(), 'center_id': centerId, 'device_id': deviceId, 'technician': technician, 'diagnosis': diagnosis, 'work_done': workDone, 'labor_cost': labor, 'parts_cost': parts, 'received_amount': received, 'created_at': DateTime.now().toIso8601String()});
    await db.update('devices', {'status': 'completed'}, where: 'id = ? AND center_id = ?', whereArgs: [deviceId, centerId]);
    final total = labor + parts;
    if (received > 0) await addTransaction(centerId, type: 'income', amount: received, note: 'Repair payment: $deviceId');
  }

  Future<void> addCustomer(
    String centerId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required String priceType,
    required double creditLimit,
  }) async {
    final db = await database;
    await db.insert('customers', {
      'id': newId(), 'center_id': centerId, 'name': name.trim(),
      'phone': phone.trim(), 'address': address.trim(), 'notes': notes.trim(),
      'price_type': priceType, 'credit_limit': creditLimit,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> customers(String centerId, {String query = ''}) async {
    final db = await database;
    if (query.trim().isEmpty) {
      return db.query('customers', where: 'center_id = ?', whereArgs: [centerId], orderBy: 'name COLLATE NOCASE');
    }
    return db.query(
      'customers',
      where: 'center_id = ? AND (name LIKE ? OR phone LIKE ?)',
      whereArgs: [centerId, '%${query.trim()}%', '%${query.trim()}%'],
      orderBy: 'name COLLATE NOCASE',
    );
  }

  Future<double> customerBalance(String centerId, String customerId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE
        WHEN entry_type = 'charge' THEN amount
        WHEN entry_type = 'payment' THEN -amount
        WHEN entry_type = 'return' THEN -amount
        ELSE amount END), 0) AS balance
      FROM customer_ledger WHERE center_id = ? AND customer_id = ? AND currency = 'IQD'
    ''', [centerId, customerId]);
    return (rows.first['balance'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, Object?>>> customerLedger(String centerId, String customerId) async {
    final db = await database;
    return db.query('customer_ledger',
      where: 'center_id = ? AND customer_id = ?',
      whereArgs: [centerId, customerId], orderBy: 'created_at DESC');
  }

  Future<void> recordCustomerPayment(
    String centerId, String customerId, {
    required double amount,
    required String note,
  }) async {
    if (amount <= 0) throw ArgumentError('Payment amount must be positive.');
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('customer_ledger', {
        'id': newId(), 'center_id': centerId, 'customer_id': customerId,
        'entry_type': 'payment', 'amount': amount, 'currency': 'IQD',
        'note': note, 'created_at': now,
      });
      await txn.insert('transactions', {
        'id': newId(), 'center_id': centerId, 'type': 'income',
        'amount': amount, 'note': 'Customer payment: $note', 'created_at': now,
      });
    });
  }

  Future<String> createCustomerSale(
    String centerId,
    String customerId, {
    required List<Map<String, Object?>> items,
    required double paid,
    double discount = 0,
    String note = '',
  }) async {
    if (items.isEmpty) throw ArgumentError('Add at least one item.');
    final db = await database;
    final invoiceId = newId();
    final now = DateTime.now().toIso8601String();
    final invoiceNo = 'SAL-${DateTime.now().millisecondsSinceEpoch}';
    await db.transaction((txn) async {
      final customerRows = await txn.query(
        'customers', where: 'id = ? AND center_id = ?',
        whereArgs: [customerId, centerId], limit: 1,
      );
      if (customerRows.isEmpty) throw StateError('Customer not found.');
      double subtotal = 0;
      final prepared = <Map<String, Object?>>[];
      final reservedQuantities = <String, int>{};
      for (final item in items) {
        final partId = item['part_id'].toString();
        final quantity = (item['quantity'] as num).toInt();
        final unitPrice = (item['unit_price'] as num).toDouble();
        if (quantity <= 0 || unitPrice < 0) throw ArgumentError('Invalid item quantity or price.');
        final partRows = await txn.query('parts', where: 'id = ? AND center_id = ?', whereArgs: [partId, centerId], limit: 1);
        if (partRows.isEmpty) throw StateError('Part not found.');
        final part = partRows.first;
        final available = (part['quantity'] as num).toInt();
        final alreadyReserved = reservedQuantities[partId] ?? 0;
        if (available < alreadyReserved + quantity) throw StateError('Insufficient stock for ${part['name']}.');
        reservedQuantities[partId] = alreadyReserved + quantity;
        final lineTotal = quantity * unitPrice;
        subtotal += lineTotal;
        prepared.add({
          'part_id': partId, 'part_name': part['name'].toString(),
          'quantity': quantity, 'unit_price': unitPrice, 'line_total': lineTotal,
        });
      }
      if (discount < 0 || discount > subtotal) throw ArgumentError('Invalid discount.');
      final total = subtotal - discount;
      if (paid < 0 || paid > total) throw ArgumentError('Invalid paid amount.');
      final creditLimit = (customerRows.first['credit_limit'] as num?)?.toDouble() ?? 0;
      if (creditLimit > 0) {
        final balanceRows = await txn.rawQuery('''
          SELECT COALESCE(SUM(CASE
            WHEN entry_type = 'charge' THEN amount
            WHEN entry_type = 'payment' OR entry_type = 'return' THEN -amount
            ELSE amount END), 0) AS balance
          FROM customer_ledger WHERE center_id = ? AND customer_id = ? AND currency = 'IQD'
        ''', [centerId, customerId]);
        final currentBalance = (balanceRows.first['balance'] as num?)?.toDouble() ?? 0;
        if (currentBalance + total - paid > creditLimit) {
          throw StateError('Customer credit limit would be exceeded.');
        }
      }
      await txn.insert('sales_invoices', {
        'id': invoiceId, 'center_id': centerId, 'customer_id': customerId,
        'invoice_no': invoiceNo, 'subtotal': subtotal, 'discount': discount,
        'total': total, 'paid': paid, 'currency': 'IQD',
        'status': paid >= total ? 'paid' : 'credit', 'created_at': now,
      });
      for (final item in prepared) {
        await txn.insert('sales_invoice_items', {
          'id': newId(), 'invoice_id': invoiceId, 'part_id': item['part_id'],
          'part_name': item['part_name'], 'quantity': item['quantity'],
          'unit_price': item['unit_price'], 'line_total': item['line_total'],
        });
        await txn.rawUpdate(
          'UPDATE parts SET quantity = quantity - ? WHERE id = ? AND center_id = ?',
          [item['quantity'], item['part_id'], centerId],
        );
        await txn.insert('stock_movements', {
          'id': newId(), 'center_id': centerId, 'part_id': item['part_id'],
          'movement_type': 'out', 'quantity': item['quantity'],
          'unit_price': item['unit_price'], 'note': 'Invoice $invoiceNo', 'created_at': now,
        });
      }
      await txn.insert('customer_ledger', {
        'id': newId(), 'center_id': centerId, 'customer_id': customerId,
        'entry_type': 'charge', 'amount': total, 'currency': 'IQD',
        'note': 'Invoice $invoiceNo${note.isEmpty ? '' : ' - $note'}',
        'reference_id': invoiceId, 'created_at': now,
      });
      if (paid > 0) {
        await txn.insert('customer_ledger', {
          'id': newId(), 'center_id': centerId, 'customer_id': customerId,
          'entry_type': 'payment', 'amount': paid, 'currency': 'IQD',
          'note': 'Payment for $invoiceNo', 'reference_id': invoiceId, 'created_at': now,
        });
        await txn.insert('transactions', {
          'id': newId(), 'center_id': centerId, 'type': 'income',
          'amount': paid, 'note': 'Sale payment $invoiceNo', 'created_at': now,
        });
      }
    });
    return invoiceNo;
  }

  Future<List<Map<String, Object?>>> employees(String centerId) async {
    final db = await database;
    return db.query('users', columns: ['id','name','username','role','active'], where: 'center_id = ?', whereArgs: [centerId], orderBy: 'name');
  }

  Future<void> addEmployee(String centerId, {required String name, required String username, required String password, required String role}) async {
    final db = await database;
    await db.insert('users', {'id': newId(), 'center_id': centerId, 'name': name, 'username': username, 'password_hash': hashPassword(password), 'role': role, 'active': 1});
  }
}
