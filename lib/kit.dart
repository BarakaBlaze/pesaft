// Design tokens and small reusable widgets, matching the web app's look.
import 'package:flutter/material.dart';
import 'model.dart';
import 'store.dart';

const Color brand = Color(0xFF673DE6);

class Tk {
  final Color bg, card, ink, mut, soft, line, hov, acc, accL, inc, exp;
  const Tk({
    required this.bg,
    required this.card,
    required this.ink,
    required this.mut,
    required this.soft,
    required this.line,
    required this.hov,
    required this.acc,
    required this.accL,
    required this.inc,
    required this.exp,
  });

  static const Tk light = Tk(
    bg: Color(0xFFF5F6F9), card: Color(0xFFFFFFFF), ink: Color(0xFF1B1D21), mut: Color(0xFF5F6773),
    soft: Color(0xFF8B93A0), line: Color(0xFFE2E5E9), hov: Color(0xFFF0F1F4), acc: Color(0xFF673DE6),
    accL: Color(0xFFEFEAFD), inc: Color(0xFF0A8A6A), exp: Color(0xFFD63163),
  );
  static const Tk dark = Tk(
    bg: Color(0xFF101014), card: Color(0xFF1A1B21), ink: Color(0xFFF4F4F6), mut: Color(0xFFA1A1AA),
    soft: Color(0xFF71717A), line: Color(0xFF2A2B33), hov: Color(0x0AFFFFFF), acc: Color(0xFFA58BFF),
    accL: Color(0x298C6BFF), inc: Color(0xFF34D399), exp: Color(0xFFFF7A9C),
  );

  static Tk of(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? dark : light;
}

ThemeData buildTheme(Brightness b) {
  final t = b == Brightness.dark ? Tk.dark : Tk.light;
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.card,
    colorScheme: ColorScheme.fromSeed(seedColor: brand, brightness: b).copyWith(primary: b == Brightness.dark ? t.acc : brand, surface: t.card),
  );
}

Color hexColor(String h) {
  var s = h.replaceAll('#', '');
  if (s.length == 6) s = 'FF$s';
  return Color(int.tryParse(s, radix: 16) ?? 0xFF673DE6);
}

const Map<String, IconData> iconMap = {
  'food': Icons.restaurant, 'bag': Icons.shopping_bag_outlined, 'car': Icons.directions_car_outlined,
  'bus': Icons.directions_bus_outlined, 'home': Icons.home_outlined, 'rent': Icons.apartment, 'bolt': Icons.bolt,
  'health': Icons.favorite_border, 'work': Icons.work_outline, 'family': Icons.groups_outlined, 'tag': Icons.sell_outlined,
  'cash': Icons.payments_outlined, 'gift': Icons.card_giftcard, 'coffee': Icons.coffee_outlined, 'edu': Icons.school_outlined,
  'phone': Icons.smartphone, 'plane': Icons.flight, 'shirt': Icons.checkroom, 'tools': Icons.build_outlined,
  'trend': Icons.trending_up, 'book': Icons.menu_book_outlined, 'fuel': Icons.local_gas_station_outlined,
  'joy': Icons.sentiment_satisfied_alt_outlined, 'shield': Icons.shield_outlined, 'swap': Icons.swap_horiz,
};

IconData iconFor(String key) => iconMap[key] ?? Icons.sell_outlined;

/// Round coloured badge with a white category icon.
class CatBadge extends StatelessWidget {
  const CatBadge({super.key, required this.color, required this.icon, this.size = 34});
  final Color color;
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.53),
      );
}

class PCard extends StatelessWidget {
  const PCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.margin = const EdgeInsets.only(bottom: 12)});
  final Widget child;
  final EdgeInsets padding, margin;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.line)),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : Material(color: Colors.transparent, child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child))),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(children: [
        Expanded(child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.ink))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class LinkText extends StatelessWidget {
  const LinkText(this.text, {super.key, required this.onTap});
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Tk.of(context).acc)),
        ),
      );
}

/// A tappable box that looks like a dropdown.
class SelectField extends StatelessWidget {
  const SelectField({super.key, required this.label, required this.value, required this.onTap});
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12.5, color: t.mut, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.line)),
          child: Row(children: [
            Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, color: t.ink))),
            Icon(Icons.keyboard_arrow_down, color: t.soft),
          ]),
        ),
      ),
    ]);
  }
}

/// Plain labelled text box.
class Field extends StatelessWidget {
  const Field({super.key, required this.label, required this.controller, this.keyboard, this.hint, this.big = false, this.maxLines = 1});
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
  final bool big;
  final int maxLines;
  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.line));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12.5, color: t.mut, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(fontSize: big ? 24 : 14.5, fontWeight: big ? FontWeight.w600 : FontWeight.w400, color: t.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: t.soft),
          filled: true,
          fillColor: t.card,
          isDense: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: big ? 14 : 12),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: brand, width: 1.6)),
        ),
      ),
    ]);
  }
}

/// Segmented control: [(value, label), ...]
class Seg extends StatelessWidget {
  const Seg({super.key, required this.options, required this.value, required this.onChanged});
  final List<MapEntry<String, String>> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: t.hov == Tk.light.hov ? t.hov : const Color(0xFF24252C), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: o.key == value ? t.card : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text(o.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: o.key == value ? t.ink : t.mut)),
              ),
            ),
          ),
      ]),
    );
  }
}

Future<String?> pickOne(BuildContext context, String title, List<MapEntry<String, String>> opts, {String? current}) {
  final t = Tk.of(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: t.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: t.ink))),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final o in opts)
                ListTile(
                  title: Text(o.value, style: TextStyle(color: t.ink)),
                  trailing: o.key == current ? Icon(Icons.check, color: t.acc) : null,
                  onTap: () => Navigator.pop(c, o.key),
                ),
            ]),
          ),
        ]),
      ),
    ),
  );
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

Future<bool> confirmDialog(BuildContext context, String title, String body, {String yes = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
      ],
    ),
  );
  return r == true;
}

/// Rebuilds [builder] whenever the store changes.
class StoreBuilder extends StatefulWidget {
  const StoreBuilder({super.key, required this.store, required this.builder});
  final Store store;
  final Widget Function(BuildContext) builder;
  @override
  State<StoreBuilder> createState() => _StoreBuilderState();
}

class _StoreBuilderState extends State<StoreBuilder> {
  void _f() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_f);
  }

  @override
  void dispose() {
    widget.store.removeListener(_f);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// One transaction row (category icon, title, details, amount).
class TxRow extends StatelessWidget {
  const TxRow({super.key, required this.s, required this.t, required this.onTap});
  final Store s;
  final Tx t;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final k = Tk.of(context);
    final tr = t.type == 'transfer';
    final meta = [
      tr ? '${s.accName(t.acc)} \u2192 ${s.accName(t.to)}' : (t.sub.isNotEmpty ? '${t.sub} \u00b7 ' : '') + s.accName(t.acc),
      dfmt(t.date),
      t.note,
    ].where((x) => x.isNotEmpty).join(' \u00b7 ');
    final col = tr ? k.mut : (t.type == 'income' ? k.inc : k.exp);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          CatBadge(color: tr ? k.mut : hexColor(s.catColor(t.cat)), icon: iconFor(tr ? 'swap' : s.catIcon(t.cat))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(t.cat, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: k.ink))),
                if (t.hasAttachment) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.attach_file, size: 14, color: k.mut)),
              ]),
              const SizedBox(height: 2),
              Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: k.mut)),
            ]),
          ),
          const SizedBox(width: 8),
          Text('${tr ? '' : (t.type == 'income' ? '+' : '\u2212')}${fmtMoney(t.amt, s.cur)}', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: col)),
        ]),
      ),
    );
  }
}
