// Pure Dart (no Flutter imports) so the logic can be tested without a phone.
// The data format is the SAME as the web app's backup file, so backups move both ways.
import 'dart:math';

final Random _rnd = Random();

String uid() {
  const c = '0123456789abcdefghijklmnopqrstuvwxyz';
  return List.generate(14, (_) => c[_rnd.nextInt(36)]).join();
}

double toNum(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
String toStr(dynamic v) => v == null ? '' : '$v';

const List<String> defaultExpense = [
  'Food and drinks', 'Vehicle', 'Shopping', 'Transport', 'Rent', 'Bills', 'Health', 'Business', 'Family', 'Other'
];
const List<String> defaultIncome = ['Salary', 'Business', 'Gift', 'Other'];
const Map<String, List<String>> defaultSubs = {
  'Food and drinks': ['Bar', 'Cafe', 'Groceries', 'Restaurant'],
  'Vehicle': ['Fuel', 'Leasing', 'Parking', 'Rentals', 'Vehicle insurance', 'Vehicle maintenance', 'Servicing'],
  'Shopping': [
    'Clothes and shoes', 'Drug-store', 'Electronics and accessories', 'Gifts', 'Joy', 'Health and beauty',
    'Home', 'Jewels', 'Kids', 'Stationery', 'Tools', 'Other'
  ],
};
const List<String> palette = [
  '#0e8f7a', '#c23b4a', '#d9a21b', '#3b6fc2', '#8a5cc2', '#e07b39', '#4a9a3b', '#c25c9a', '#6b7a74', '#2b8fb3'
];
const Map<String, String> defaultIcons = {
  'Food and drinks': 'food', 'Vehicle': 'car', 'Shopping': 'bag', 'Transport': 'bus', 'Rent': 'rent',
  'Bills': 'bolt', 'Health': 'health', 'Business': 'work', 'Family': 'family', 'Other': 'tag',
  'Salary': 'cash', 'Gift': 'gift', 'Transfer': 'swap',
};

/// A record backed by the raw JSON map, so fields this version does not know about survive a round trip.
class Rec {
  final Map<String, dynamic> j;
  Rec(this.j);
  String get id => toStr(j['id']);
}

class Account extends Rec {
  Account(super.j);
  factory Account.create({required String name, double open = 0, String color = '#0e8f7a'}) =>
      Account({'id': uid(), 'name': name, 'open': open, 'color': color});
  String get name => toStr(j['name']);
  set name(String v) => j['name'] = v;
  double get open => toNum(j['open']);
  set open(double v) => j['open'] = v;
  String get color => toStr(j['color']).isEmpty ? '#0e8f7a' : toStr(j['color']);
  set color(String v) => j['color'] = v;
}

class Tx extends Rec {
  Tx(super.j);
  factory Tx.create() => Tx({
        'id': uid(), 'type': 'expense', 'amt': 0, 'cat': '', 'sub': '', 'date': ymd(DateTime.now()),
        'acc': '', 'to': '', 'note': ''
      });
  String get type => toStr(j['type']);
  set type(String v) => j['type'] = v;
  double get amt => toNum(j['amt']);
  set amt(double v) => j['amt'] = v;
  String get cat => toStr(j['cat']);
  set cat(String v) => j['cat'] = v;
  String get sub => toStr(j['sub']);
  set sub(String v) => j['sub'] = v;
  String get date => toStr(j['date']);
  set date(String v) => j['date'] = v;
  String get acc => toStr(j['acc']);
  set acc(String v) => j['acc'] = v;
  String get to => toStr(j['to']);
  set to(String v) => j['to'] = v;
  String get note => toStr(j['note']);
  set note(String v) => j['note'] = v;
  bool get hasAttachment => j['att'] is List && (j['att'] as List).isNotEmpty;
}

class Cat extends Rec {
  Cat(super.j);
  String get name => toStr(j['name']);
  String get color => toStr(j['color']).isEmpty ? palette[0] : toStr(j['color']);
  String get icon => toStr(j['icon']);
}

// ---------- dates ----------
const List<String> _mon = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const List<String> _mon3 = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const List<String> _wd3 = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "31 Oct" from "2026-10-31"
String dfmt(String s) {
  final d = DateTime.tryParse(s);
  return d == null ? s : '${d.day} ${_mon3[d.month - 1]}';
}

class Range {
  final String from, to, label;
  const Range(this.from, this.to, this.label);
}

/// Same periods as the web app: day, week (Monday start), month, quarter, year, all.
Range rng(String per, int off, DateTime now, {String? firstDate}) {
  DateTime addD(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
  switch (per) {
    case 'day':
      final d = addD(now, off);
      return Range(ymd(d), ymd(d), '${_wd3[d.weekday - 1]}, ${d.day} ${_mon3[d.month - 1]} ${d.year}');
    case 'week':
      final s = addD(now, -((now.weekday - 1) % 7) + off * 7), e = addD(s, 6);
      return Range(ymd(s), ymd(e), '${s.day} ${_mon3[s.month - 1]} \u2013 ${e.day} ${_mon3[e.month - 1]} ${e.year}');
    case 'month':
      final s = DateTime(now.year, now.month + off, 1), e = DateTime(s.year, s.month + 1, 0);
      return Range(ymd(s), ymd(e), '${_mon[s.month - 1]} ${s.year}');
    case 'quarter':
      final s = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1 + off * 3, 1), e = DateTime(s.year, s.month + 3, 0);
      return Range(ymd(s), ymd(e), 'Q${(s.month - 1) ~/ 3 + 1} ${s.year}');
    case 'year':
      final y = now.year + off;
      return Range('$y-01-01', '$y-12-31', '$y');
    default:
      return Range(firstDate ?? ymd(now), ymd(now), 'All time');
  }
}

/// Money text like the web app: "\u2212TSh 5,000" for negatives.
String fmtMoney(double n, String cur) {
  final r = (n + 0.5).floor(); // same rounding as JavaScript Math.round
  final digits = r.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
    b.write(digits[i]);
  }
  return '${r < 0 ? '\u2212' : ''}$cur $b';
}

/// 1500.0 -> "1500", 12.5 -> "12.5"
String fmtNum(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();
