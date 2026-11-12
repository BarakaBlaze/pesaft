// Screens: Home, Records, Accounts, Settings.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kit.dart';
import 'model.dart';
import 'sheets.dart';
import 'store.dart';

const double _navSpace = 110; // keeps the last items clear of the floating navigation bar

Widget _page(BuildContext context, List<Widget> children) => ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _navSpace),
      children: children,
    );

// ============================ HOME ============================
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.s});
  final Store s;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String per = 'day';
  int off = 0;
  static const tabs = [MapEntry('day', 'Day'), MapEntry('week', 'Week'), MapEntry('month', 'Month'), MapEntry('year', 'Year'), MapEntry('all', 'All')];

  String _label(Range r) {
    if (per == 'day') return off == 0 ? 'Today' : (off == -1 ? 'Yesterday' : r.label);
    if (per == 'week') return off == 0 ? 'This week' : (off == -1 ? 'Last week' : r.label);
    if (per == 'month') return off == 0 ? 'This month' : (off == -1 ? 'Last month' : r.label);
    if (per == 'year') return off == 0 ? 'This year' : r.label;
    return 'All time';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return StoreBuilder(
      store: s,
      builder: (context) {
        final t = Tk.of(context);
        final r = rng(per, off, DateTime.now(), firstDate: s.firstDate);
        final ts = s.txIn(r);
        final i = s.inc(ts), e = s.exs(ts);
        final rec = s.sorted(ts);
        final lb = _label(r);

        Widget cell(String label, String value, Color? c, {BoxBorder? border}) => Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(border: border),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 12, color: t.mut)),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c ?? t.ink)),
                ]),
              ),
            );
        final side = BorderSide(color: t.line);

        return _page(context, [
          Row(children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final x in tabs)
                    GestureDetector(
                      onTap: () => setState(() {
                        per = x.key;
                        off = 0;
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: per == x.key ? brand : Colors.transparent, width: 2))),
                        child: Text(x.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: per == x.key ? t.ink : t.mut)),
                      ),
                    ),
                ]),
              ),
            ),
            if (per != 'all') ...[
              _navBtn(context, Icons.chevron_left, () => setState(() => off--)),
              SizedBox(width: 68, child: Text(lb, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.ink))),
              _navBtn(context, Icons.chevron_right, () => setState(() => off++)),
            ],
          ]),
          const SizedBox(height: 12),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
            child: Column(children: [
              Row(children: [
                cell('Balance', fmtMoney(s.totalBalance(), s.cur), null, border: Border(right: side)),
                cell('Income', fmtMoney(i, s.cur), t.inc),
              ]),
              Row(children: [
                cell('Spent', fmtMoney(e, s.cur), t.exp, border: Border(top: side, right: side)),
                cell('Net', fmtMoney(i - e, s.cur), (i - e) < 0 ? t.exp : t.inc, border: Border(top: side)),
              ]),
            ]),
          ),
          SectionTitle('Accounts', trailing: LinkText('Add account', onTap: () => showAccountSheet(context, s))),
          if (s.accounts.isEmpty)
            PCard(child: Text('No accounts yet. Tap "Add account" (Cash, CRDB, NMB, M-Pesa).', style: TextStyle(color: t.mut)))
          else
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 700 ? 4 : 2;
              final w = (c.maxWidth - 10 * (cols - 1)) / cols;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                for (final a in s.accounts)
                  SizedBox(
                    width: w,
                    child: PCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(12),
                      onTap: () => showAccountSheet(context, s, edit: a),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: hexColor(a.color), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.mut))),
                        ]),
                        const SizedBox(height: 4),
                        Text(fmtMoney(s.accBal(a.id), s.cur), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: s.accBal(a.id) < 0 ? t.exp : t.ink)),
                      ]),
                    ),
                  ),
              ]);
            }),
          SectionTitle('Records \u00b7 $lb \u00b7 ${rec.length}'),
          PCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: rec.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: Center(child: Text(per == 'day' ? (off == 0 ? 'No records today.' : 'No records on this day.') : 'No records in this period.', style: TextStyle(color: t.mut))))
                : Column(children: [
                    for (var k = 0; k < rec.length && k < 100; k++) ...[
                      TxRow(s: s, t: rec[k], onTap: () => showTxSheet(context, s, edit: rec[k])),
                      if (k < rec.length - 1 && k < 99) Divider(height: 1, color: t.line),
                    ],
                  ]),
          ),
        ]);
      },
    );
  }
}

Widget _navBtn(BuildContext context, IconData i, VoidCallback onTap) {
  final t = Tk.of(context);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(width: 28, height: 28, decoration: BoxDecoration(color: t.hov, borderRadius: BorderRadius.circular(8)), child: Icon(i, size: 18, color: t.ink)),
  );
}

// ============================ RECORDS ============================
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key, required this.s});
  final Store s;
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int off = 0;
  bool all = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return StoreBuilder(
      store: s,
      builder: (context) {
        final t = Tk.of(context);
        final r = rng('month', off, DateTime.now());
        final list = s.sorted(all ? s.tx : s.txIn(r));
        return _page(context, [
          Row(children: [
            Text('Records', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: t.ink)),
            const Spacer(),
            if (!all) ...[
              _navBtn(context, Icons.chevron_left, () => setState(() => off--)),
              SizedBox(width: 120, child: Text(r.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.ink))),
              _navBtn(context, Icons.chevron_right, () => setState(() => off++)),
            ],
            const SizedBox(width: 8),
            LinkText(all ? 'By month' : 'All time', onTap: () => setState(() => all = !all)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Income', style: TextStyle(fontSize: 12, color: t.mut)), Text(fmtMoney(s.inc(list), s.cur), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.inc))]))),
            const SizedBox(width: 10),
            Expanded(child: PCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Spent', style: TextStyle(fontSize: 12, color: t.mut)), Text(fmtMoney(s.exs(list), s.cur), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.exp))]))),
          ]),
          const SizedBox(height: 12),
          PCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: list.isEmpty
                ? Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: Center(child: Text('No records.', style: TextStyle(color: t.mut))))
                : Column(children: [
                    for (var k = 0; k < list.length && k < 300; k++) ...[
                      TxRow(s: s, t: list[k], onTap: () => showTxSheet(context, s, edit: list[k])),
                      if (k < list.length - 1 && k < 299) Divider(height: 1, color: t.line),
                    ],
                  ]),
          ),
        ]);
      },
    );
  }
}

// ============================ ACCOUNTS ============================
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key, required this.s});
  final Store s;
  @override
  Widget build(BuildContext context) => StoreBuilder(
        store: s,
        builder: (context) {
          final t = Tk.of(context);
          return _page(context, [
            Row(children: [
              Text('Accounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: t.ink)),
              const Spacer(),
              FilledButton(onPressed: () => showAccountSheet(context, s), child: const Text('New')),
            ]),
            const SizedBox(height: 12),
            PCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: s.accounts.isEmpty
                  ? Padding(padding: const EdgeInsets.symmetric(vertical: 28), child: Center(child: Text('No accounts yet.', style: TextStyle(color: t.mut))))
                  : Column(children: [
                      for (var k = 0; k < s.accounts.length; k++) ...[
                        InkWell(
                          onTap: () => showAccountSheet(context, s, edit: s.accounts[k]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: hexColor(s.accounts[k].color), shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(s.accounts[k].name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink))),
                              Text(fmtMoney(s.accBal(s.accounts[k].id), s.cur), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: s.accBal(s.accounts[k].id) < 0 ? t.exp : t.ink)),
                            ]),
                          ),
                        ),
                        if (k < s.accounts.length - 1) Divider(height: 1, color: t.line),
                      ],
                    ]),
            ),
            PCard(child: Row(children: [
              Expanded(child: Text('Total across all accounts', style: TextStyle(color: t.mut))),
              Text(fmtMoney(s.totalBalance(), s.cur), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.ink)),
            ])),
          ]);
        },
      );
}

// ============================ SETTINGS ============================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.s, required this.mode, required this.onMode});
  final Store s;
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onMode;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController curC = TextEditingController(text: widget.s.cur);

  @override
  void dispose() {
    curC.dispose();
    super.dispose();
  }

  Future<void> _restoreDialog() async {
    final c = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Paste the backup text here. This replaces all data in the app.'),
          const SizedBox(height: 12),
          TextField(controller: c, maxLines: 6, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"app":"pesa", ...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final d = await Clipboard.getData('text/plain');
              if (d?.text != null) c.text = d!.text!;
            },
            child: const Text('Paste'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Restore')),
        ],
      ),
    );
    c.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      await widget.s.importJson(text);
      if (mounted) {
        curC.text = widget.s.cur;
        snack(context, 'Backup restored.');
      }
    } on FormatException catch (e) {
      if (mounted) snack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    final s = widget.s;
    Widget radio(String label, String sub, ThemeMode m) => InkWell(
          onTap: () => widget.onMode(m),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: t.ink)),
                Text(sub, style: TextStyle(fontSize: 12.5, color: t.mut)),
              ])),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.mode == m ? brand : t.line, width: 2)),
                child: widget.mode == m ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: brand, shape: BoxShape.circle))) : null,
              ),
            ]),
          ),
        );
    Widget action(String label, String sub, VoidCallback onTap, {Color? color}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: color ?? t.ink)),
                Text(sub, style: TextStyle(fontSize: 12.5, color: t.mut)),
              ])),
              Icon(Icons.chevron_right, color: t.soft),
            ]),
          ),
        );

    return _page(context, [
      Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: t.ink)),
      const SectionTitle('Appearance'),
      PCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
        radio('System', 'Follow your phone setting', ThemeMode.system),
        Divider(height: 1, color: t.line),
        radio('Light', 'Always light', ThemeMode.light),
        Divider(height: 1, color: t.line),
        radio('Dark', 'Always dark', ThemeMode.dark),
      ])),
      const SectionTitle('Currency'),
      PCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Field(label: 'Currency label', controller: curC, hint: 'TSh'),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () async {
            await s.setCur(curC.text);
            if (mounted) snack(context, 'Saved.');
          },
          child: const Text('Save'),
        ),
      ])),
      const SectionTitle('Backup and restore'),
      PCard(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
        action('Copy backup', 'Copies all your data to the clipboard', () async {
          await Clipboard.setData(ClipboardData(text: s.exportJson()));
          if (mounted) snack(context, 'Backup copied. Paste it somewhere safe.');
        }),
        Divider(height: 1, color: t.line),
        action('Restore from backup', 'Paste a backup from this app or the web app', _restoreDialog),
        Divider(height: 1, color: t.line),
        action('Erase all data', 'Deletes everything on this phone', () async {
          if (await confirmDialog(context, 'Erase all data?', 'All accounts and records on this phone will be deleted.', yes: 'Erase')) {
            await s.eraseAll();
            if (mounted) snack(context, 'All data erased.');
          }
        }, color: t.exp),
      ])),
      const SizedBox(height: 4),
      Text('Version 1.0 (native). Budgets, goals, debts, planned payments, shopping, reminders, reports, Google backup and online sync are coming in the next stages; your existing data for them is kept safely inside backups.', style: TextStyle(fontSize: 12.5, color: t.mut)),
    ]);
  }
}
