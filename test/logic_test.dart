// Run with:  dart test/logic_test.dart     (no packages needed)
import 'dart:convert';
import 'dart:io';
import '../lib/model.dart';
import '../lib/store.dart';

int ok = 0, bad = 0;
void check(bool c, String m) {
  print('${c ? 'PASS' : 'FAIL'} $m');
  c ? ok++ : bad++;
}

bool near(double a, double b) => (a - b).abs() < 0.005;

Future<void> main() async {
  final sample = jsonDecode(File('test/web_sample.json').readAsStringSync()) as Map<String, dynamic>;
  final now = DateTime.parse(sample['today'] as String);
  final exp = sample['expect'] as Map<String, dynamic>;

  // ---- import a backup made by the WEB app ----
  final mem = MemoryPersist();
  final s = Store(mem);
  await s.load();
  check(s.accounts.isEmpty && s.cur == 'TSh' && s.expCats.length == 10 && s.incCats.length == 4, 'empty store starts with default categories');
  check(s.subsOf('Vehicle').contains('Fuel') && s.subsOf('Shopping').length == 12, 'default subcategories present');
  await s.importJson(jsonEncode(sample['backup']));
  check(s.accounts.length == 4 && s.tx.length == 21, 'web backup imported (4 accounts, 21 transactions)');

  // ---- same numbers as the web app ----
  var allBalOk = true;
  (exp['bal'] as Map<String, dynamic>).forEach((id, v) {
    if (!near(s.accBal(id), (v as num).toDouble())) {
      allBalOk = false;
      print('  balance $id dart=${s.accBal(id)} web=$v');
    }
  });
  check(allBalOk, 'account balances equal the web app (incl. transfers, decimals, negative start)');
  check(near(s.totalBalance(), (exp['total'] as num).toDouble()), 'total balance equals the web app');
  for (final p in exp['periods'] as List) {
    final per = p['per'] as String;
    final off = p['off'] as int;
    final r = rng(per, off, now, firstDate: s.firstDate);
    final ts = s.txIn(r);
    final same = r.from == p['from'] &&
        r.to == p['to'] &&
        near(s.inc(ts), (p['inc'] as num).toDouble()) &&
        near(s.exs(ts), (p['exs'] as num).toDouble()) &&
        near(s.net(ts), (p['net'] as num).toDouble()) &&
        ts.length == p['n'];
    check(same, 'period $per/$off: dates, income, spending, net and count match the web app');
  }
  var fmtOk = true;
  for (final f in exp['fmt'] as List) {
    final got = fmtMoney((f[0] as num).toDouble(), 'TSh');
    if (got != f[1]) {
      fmtOk = false;
      print('  fmt ${f[0]} dart="$got" web="${f[1]}"');
    }
  }
  check(fmtOk, 'money formatting equals the web app (rounding, thousands, minus sign)');

  // ---- nothing is lost on a round trip ----
  final back = (sample['backup'] as Map)['data'] as Map<String, dynamic>;
  final out = s.toJson();
  check(
      jsonEncode(out['debts']) == jsonEncode(back['debts']) &&
          jsonEncode(out['plans']) == jsonEncode(back['plans']) &&
          jsonEncode(out['lists']) == jsonEncode(back['lists']) &&
          jsonEncode(out['goals']) == jsonEncode(back['goals']),
      'debts, plans, shopping lists and goals are kept untouched');
  check(jsonEncode(out['futureField']) == jsonEncode(back['futureField']), 'unknown future fields are preserved');
  check(jsonEncode(out['tx']) == jsonEncode(back['tx']) && jsonEncode(out['accounts']) == jsonEncode(back['accounts']),
      'transactions and accounts unchanged by import');
  final s2 = Store(MemoryPersist());
  await s2.load();
  await s2.importJson(s.exportJson());
  check(jsonEncode(s2.toJson()) == jsonEncode(s.toJson()), 'export then import gives identical data');
  final s3 = Store(mem);
  await s3.load();
  check(jsonEncode(s3.toJson()) == jsonEncode(s.toJson()), 'data survives closing and reopening (persisted)');

  // ---- editing ----
  final n0 = s.tx.length;
  final t = Tx.create()
    ..type = 'expense'
    ..amt = 1500.5
    ..cat = 'Transport'
    ..acc = 'a1'
    ..date = ymd(now);
  await s.addTx(t);
  check(s.tx.length == n0 + 1 && s.sorted(s.txIn(rng('day', 0, now))).first.id == t.id, 'new transaction is added and listed first for the day');
  final b1 = s.accBal('a1');
  t.amt = 2000;
  await s.updateTx(t);
  check(near(s.accBal('a1'), b1 - 499.5), 'editing the amount changes the balance');
  await s.deleteTx(t.id);
  check(s.tx.length == n0 && near(s.accBal('a1'), b1 + 1500.5), 'deleting restores the balance');
  check(!await s.deleteAccount('a1') && s.accounts.length == 4, 'an account with transactions cannot be deleted');
  final acc = Account.create(name: 'Test', open: 10);
  await s.saveAccount(acc);
  check(s.accounts.length == 5 && await s.deleteAccount(acc.id) && s.accounts.length == 4, 'new unused account can be added and deleted');
  await s.setCur('USD');
  check(s.cur == 'USD' && fmtMoney(-2500, s.cur) == '\u2212USD 2,500', 'currency label changes');

  // ---- bad files ----
  var threw = 0;
  for (final b in ['not json', '{"hello":1}', '[1,2]', '{"app":"pesa","data":{"x":1}}']) {
    try {
      await s.importJson(b);
    } on FormatException {
      threw++;
    }
  }
  check(threw == 4 && s.tx.length == n0, 'invalid files are rejected and do not change your data');
  await s.importJson(jsonEncode(back)); // a raw (not wrapped) web backup also works
  check(s.tx.length == 21, 'a plain backup (without wrapper) also imports');
  await s.eraseAll();
  check(s.tx.isEmpty && s.accounts.isEmpty && s.expCats.length == 10, 'erase all resets to a clean state');
  print('$ok passed, $bad failed');
  exit(bad == 0 ? 0 : 1);
}
