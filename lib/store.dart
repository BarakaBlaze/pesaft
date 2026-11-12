// Pure Dart: all data and calculations. The UI only reads from here and calls its methods.
import 'dart:convert';
import 'model.dart';

abstract class Persist {
  Future<String?> read();
  Future<void> write(String s);
}

class MemoryPersist implements Persist {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String s) async => data = s;
}

class Store {
  Store(this.p);
  final Persist p;

  String cur = 'TSh';
  List<Account> accounts = [];
  List<Tx> tx = [];
  List<Cat> expCats = [];
  List<Cat> incCats = [];
  Map<String, List<String>> subs = {};
  Map<String, dynamic> profile = {};
  // Everything this version does not edit yet (budgets, goals, debts, plans, lists, filters, ...) is kept as is.
  Map<String, dynamic> extra = {};

  final List<void Function()> _ls = [];
  void addListener(void Function() f) => _ls.add(f);
  void removeListener(void Function() f) => _ls.remove(f);
  void _notify() {
    for (final f in List.of(_ls)) {
      f();
    }
  }

  Future<void> load() async {
    final s = await p.read();
    Map<String, dynamic> m = {};
    if (s != null && s.isNotEmpty) {
      try {
        final d = jsonDecode(s);
        if (d is Map<String, dynamic>) m = d;
      } catch (_) {}
    }
    _apply(m);
    _notify();
  }

  List<dynamic> _list(dynamic v) => v is List ? v : const [];

  void _apply(Map<String, dynamic> m) {
    final cp = Map<String, dynamic>.from(m);
    cur = toStr(cp.remove('cur'));
    if (cur.isEmpty) cur = 'TSh';
    accounts = _list(cp.remove('accounts')).whereType<Map>().map((e) => Account(Map<String, dynamic>.from(e))).toList();
    tx = _list(cp.remove('tx')).whereType<Map>().map((e) => Tx(Map<String, dynamic>.from(e))).toList();
    final cats = cp.remove('cats');
    List<Cat> mk(dynamic raw, List<String> defaults, int shift) {
      final l = _list(raw).whereType<Map>().map((e) => Cat(Map<String, dynamic>.from(e))).toList();
      if (l.isNotEmpty) return l;
      return [for (var i = 0; i < defaults.length; i++) Cat({'name': defaults[i], 'color': palette[(i + shift) % palette.length]})];
    }
    expCats = mk(cats is Map ? cats['expense'] : null, defaultExpense, 0);
    incCats = mk(cats is Map ? cats['income'] : null, defaultIncome, 4);
    subs = {};
    final rs = cp.remove('subs');
    if (rs is Map) {
      rs.forEach((k, v) => subs['$k'] = _list(v).map((e) => '$e').toList());
    }
    if (cp['subsMig'] == null) {
      defaultSubs.forEach((k, d) {
        final ex = subs[k] ?? <String>[];
        subs[k] = [...d, ...ex.where((x) => !d.contains(x))];
      });
      cp['subsMig'] = 1;
    }
    final pr = cp.remove('profile');
    profile = pr is Map ? Map<String, dynamic>.from(pr) : {'name': '', 'email': '', 'phone': '', 'photo': ''};
    extra = cp;
  }

  Map<String, dynamic> toJson() {
    final m = Map<String, dynamic>.from(extra);
    m['cur'] = cur;
    m['accounts'] = accounts.map((a) => a.j).toList();
    m['tx'] = tx.map((t) => t.j).toList();
    m['cats'] = {'expense': expCats.map((c) => c.j).toList(), 'income': incCats.map((c) => c.j).toList()};
    m['subs'] = subs;
    m['profile'] = profile;
    return m;
  }

  Future<void> _changed() async {
    _notify();
    await p.write(jsonEncode(toJson()));
  }

  // ---------- editing ----------
  Future<void> addTx(Tx t) { tx.add(t); return _changed(); }
  Future<void> updateTx(Tx t) {
    final i = tx.indexWhere((x) => x.id == t.id);
    if (i >= 0) tx[i] = t;
    return _changed();
  }
  Future<void> deleteTx(String id) { tx.removeWhere((x) => x.id == id); return _changed(); }
  Future<void> saveAccount(Account a) {
    final i = accounts.indexWhere((x) => x.id == a.id);
    if (i >= 0) { accounts[i] = a; } else { accounts.add(a); }
    return _changed();
  }
  bool accountUsed(String id) => tx.any((t) => t.acc == id || t.to == id);
  /// Returns false (and does nothing) if the account has transactions.
  Future<bool> deleteAccount(String id) async {
    if (accountUsed(id)) return false;
    accounts.removeWhere((a) => a.id == id);
    await _changed();
    return true;
  }
  Future<void> setCur(String c) { cur = c.trim().isEmpty ? 'TSh' : c.trim(); return _changed(); }

  // ---------- calculations (same rules as the web app) ----------
  double accBal(String id) {
    final a = accounts.where((x) => x.id == id);
    var b = a.isEmpty ? 0.0 : a.first.open;
    for (final t in tx) {
      if (t.acc == id) {
        b += t.type == 'income' ? t.amt : -t.amt;
      } else if (t.type == 'transfer' && t.to == id) {
        b += t.amt;
      }
    }
    return b;
  }

  double net(Iterable<Tx> l) => l.where((t) => t.type != 'transfer').fold(0.0, (s, t) => s + (t.type == 'income' ? t.amt : -t.amt));
  double inc(Iterable<Tx> l) => l.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amt);
  double exs(Iterable<Tx> l) => l.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amt);
  double totalBalance() => accounts.fold(0.0, (s, a) => s + a.open) + net(tx);

  String? get firstDate {
    if (tx.isEmpty) return null;
    final d = tx.map((t) => t.date).toList()..sort();
    return d.first;
  }

  List<Tx> txIn(Range r) => tx.where((t) => t.date.compareTo(r.from) >= 0 && t.date.compareTo(r.to) <= 0).toList();

  /// Newest first; records added later on the same day come first.
  List<Tx> sorted(Iterable<Tx> l) {
    final x = l.toList().asMap().entries.toList();
    x.sort((a, b) {
      final c = b.value.date.compareTo(a.value.date);
      return c != 0 ? c : b.key.compareTo(a.key);
    });
    return x.map((e) => e.value).toList();
  }

  List<Cat> catsFor(String type) => type == 'income' ? incCats : expCats;
  Cat? _cat(String name) {
    for (final c in [...expCats, ...incCats]) {
      if (c.name == name) return c;
    }
    return null;
  }
  String catColor(String name) => _cat(name)?.color ?? palette[0];
  String catIcon(String name) {
    final c = _cat(name);
    return (c != null && c.icon.isNotEmpty) ? c.icon : (defaultIcons[name] ?? 'tag');
  }
  List<String> subsOf(String cat) => subs[cat] ?? const [];
  String accName(String id) {
    for (final a in accounts) {
      if (a.id == id) return a.name;
    }
    return 'No account';
  }

  // ---------- backup (same file format as the web app) ----------
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'pesa', 'v': 1, 'exported': DateTime.now().toIso8601String(), 'device': 'flutter', 'data': toJson()
      });

  /// Accepts a backup from the web app or from this app. Throws FormatException if it is not a Pesa backup.
  Future<void> importJson(String raw) async {
    dynamic o;
    try {
      o = jsonDecode(raw.trim());
    } catch (_) {
      throw const FormatException('That is not a valid backup.');
    }
    if (o is Map && o['app'] == 'pesa' && o['data'] is Map) o = o['data'];
    if (o is! Map || o['tx'] is! List) throw const FormatException('That is not a Pesa backup.');
    _apply(Map<String, dynamic>.from(o));
    await _changed();
  }

  Future<void> eraseAll() { _apply({}); return _changed(); }
}
