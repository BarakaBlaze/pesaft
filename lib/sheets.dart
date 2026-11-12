// Bottom sheets: add/edit transaction and add/edit account.
import 'package:flutter/material.dart';
import 'kit.dart';
import 'model.dart';
import 'store.dart';

const RoundedRectangleBorder _sheetShape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)));

Future<void> showTxSheet(BuildContext context, Store s, {Tx? edit}) async {
  if (s.accounts.isEmpty) {
    snack(context, 'Add an account first, such as Cash or CRDB.');
    await showAccountSheet(context, s);
    return;
  }
  var type = edit?.type ?? 'expense';
  var acc = edit?.acc ?? s.accounts.first.id;
  var to = edit?.to.isNotEmpty == true ? edit!.to : (s.accounts.length > 1 ? s.accounts[1].id : s.accounts.first.id);
  var cat = edit != null && edit.type != 'transfer' ? edit.cat : s.expCats.first.name;
  var sub = edit?.sub ?? '';
  var date = edit?.date ?? ymd(DateTime.now());
  final amtC = TextEditingController(text: edit == null ? '' : fmtNum(edit.amt));
  final noteC = TextEditingController(text: edit?.note ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Tk.of(context).card,
    shape: _sheetShape,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final t = Tk.of(ctx);
      final catNames = s.catsFor(type).map((c) => c.name).toList();
      if (type != 'transfer' && !catNames.contains(cat)) cat = catNames.first;
      final subNames = type == 'expense' ? s.subsOf(cat) : <String>[];

      Future<void> save() async {
        final a = double.tryParse(amtC.text.replaceAll(',', '.').trim());
        if (a == null || a <= 0) {
          snack(ctx, 'Enter an amount greater than 0.');
          return;
        }
        if (type == 'transfer' && acc == to) {
          snack(ctx, 'Choose two different accounts.');
          return;
        }
        final tx = edit ?? Tx.create();
        tx
          ..type = type
          ..amt = a
          ..cat = type == 'transfer' ? 'Transfer' : cat
          ..sub = type == 'expense' ? sub : ''
          ..date = date
          ..acc = acc
          ..to = type == 'transfer' ? to : ''
          ..note = noteC.text.trim();
        Navigator.pop(ctx);
        if (edit == null) {
          await s.addTx(tx);
        } else {
          await s.updateTx(tx);
        }
      }

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(edit == null ? 'Add transaction' : 'Edit transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.ink)),
              const SizedBox(height: 14),
              Seg(
                options: const [MapEntry('expense', 'Expense'), MapEntry('income', 'Income'), MapEntry('transfer', 'Transfer')],
                value: type,
                onChanged: (v) => setS(() {
                  type = v;
                  sub = '';
                }),
              ),
              const SizedBox(height: 14),
              Field(label: 'Amount (${s.cur})', controller: amtC, keyboard: const TextInputType.numberWithOptions(decimal: true), hint: '0', big: true),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: SelectField(
                    label: type == 'transfer' ? 'From account' : (type == 'income' ? 'Deposit to account' : 'Paid from account'),
                    value: s.accName(acc),
                    onTap: () async {
                      final r = await pickOne(ctx, 'Account', [for (final a in s.accounts) MapEntry(a.id, a.name)], current: acc);
                      if (r != null) setS(() => acc = r);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: type == 'transfer'
                      ? SelectField(
                          label: 'To account',
                          value: s.accName(to),
                          onTap: () async {
                            final r = await pickOne(ctx, 'To account', [for (final a in s.accounts) MapEntry(a.id, a.name)], current: to);
                            if (r != null) setS(() => to = r);
                          },
                        )
                      : SelectField(
                          label: 'Category',
                          value: cat,
                          onTap: () async {
                            final r = await pickOne(ctx, 'Category', [for (final n in catNames) MapEntry(n, n)], current: cat);
                            if (r != null) {
                              setS(() {
                                cat = r;
                                sub = '';
                              });
                            }
                          },
                        ),
                ),
              ]),
              if (type == 'expense' && subNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                SelectField(
                  label: 'Subcategory',
                  value: sub.isEmpty ? 'No subcategory' : sub,
                  onTap: () async {
                    final r = await pickOne(ctx, 'Subcategory', [const MapEntry('', 'No subcategory'), for (final n in subNames) MapEntry(n, n)], current: sub);
                    if (r != null) setS(() => sub = r);
                  },
                ),
              ],
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: SelectField(
                    label: 'Date',
                    value: dfmt(date) + ' ' + date.substring(0, 4),
                    onTap: () async {
                      final init = DateTime.tryParse(date) ?? DateTime.now();
                      final r = await showDatePicker(context: ctx, initialDate: init, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (r != null) setS(() => date = ymd(r));
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Field(label: 'Note', controller: noteC, hint: 'Optional')),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                if (edit != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: OutlinedButton(
                      onPressed: () async {
                        if (await confirmDialog(ctx, 'Delete this transaction?', 'This cannot be undone.')) {
                          Navigator.pop(ctx);
                          await s.deleteTx(edit.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: t.exp, minimumSize: const Size(0, 48)),
                      child: const Text('Delete'),
                    ),
                  ),
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(onPressed: save, style: FilledButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Save'))),
              ]),
            ]),
          ),
        ),
      );
    }),
  );
  amtC.dispose();
  noteC.dispose();
}

Future<void> showAccountSheet(BuildContext context, Store s, {Account? edit}) async {
  var color = edit?.color ?? palette[s.accounts.length % palette.length];
  final nameC = TextEditingController(text: edit?.name ?? '');
  final openC = TextEditingController(text: edit == null ? '' : fmtNum(edit.open));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Tk.of(context).card,
    shape: _sheetShape,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final t = Tk.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(edit == null ? 'New account' : 'Edit account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.ink)),
              const SizedBox(height: 14),
              Field(label: 'Account name', controller: nameC, hint: 'Cash, CRDB, NMB, M-Pesa'),
              const SizedBox(height: 12),
              Field(label: 'Starting balance (${s.cur})', controller: openC, keyboard: const TextInputType.numberWithOptions(decimal: true, signed: true), hint: 'What it holds today'),
              if (edit != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Balance now: ${fmtMoney(s.accBal(edit.id), s.cur)}', style: TextStyle(fontSize: 12.5, color: t.mut))),
              const SizedBox(height: 14),
              Text('Color', style: TextStyle(fontSize: 12.5, color: t.mut, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final c in palette)
                  GestureDetector(
                    onTap: () => setS(() => color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: hexColor(c), shape: BoxShape.circle, border: Border.all(color: color == c ? t.ink : Colors.transparent, width: 2.5)),
                      child: color == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                if (edit != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: OutlinedButton(
                      onPressed: () async {
                        if (s.accountUsed(edit.id)) {
                          snack(ctx, 'This account has transactions, so it can\u2019t be deleted.');
                          return;
                        }
                        if (await confirmDialog(ctx, 'Delete this account?', 'This cannot be undone.')) {
                          Navigator.pop(ctx);
                          await s.deleteAccount(edit.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: t.exp, minimumSize: const Size(0, 48)),
                      child: const Text('Delete'),
                    ),
                  ),
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Cancel'))),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: () async {
                      final n = nameC.text.trim();
                      if (n.isEmpty) {
                        snack(ctx, 'Enter an account name.');
                        return;
                      }
                      final open = double.tryParse(openC.text.replaceAll(',', '.').trim()) ?? 0;
                      final a = edit ?? Account.create(name: n);
                      a
                        ..name = n
                        ..open = open
                        ..color = color;
                      Navigator.pop(ctx);
                      await s.saveAccount(a);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      );
    }),
  );
  nameC.dispose();
  openC.dispose();
}
