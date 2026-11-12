import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kit.dart';
import 'pages.dart';
import 'sheets.dart';
import 'store.dart';

class PrefsPersist implements Persist {
  PrefsPersist(this.prefs);
  final SharedPreferences prefs;
  @override
  Future<String?> read() async => prefs.getString('pesa_state');
  @override
  Future<void> write(String s) async {
    await prefs.setString('pesa_state', s);
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController(this.prefs) {
    final m = prefs.getString('pesa_theme');
    mode = m == 'light' ? ThemeMode.light : (m == 'dark' ? ThemeMode.dark : ThemeMode.system);
  }
  final SharedPreferences prefs;
  ThemeMode mode = ThemeMode.system;
  Future<void> set(ThemeMode m) async {
    mode = m;
    notifyListeners();
    await prefs.setString('pesa_theme', m == ThemeMode.light ? 'light' : (m == ThemeMode.dark ? 'dark' : 'system'));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = Store(PrefsPersist(prefs));
  await store.load();
  runApp(PesaApp(store: store, theme: ThemeController(prefs)));
}

class PesaApp extends StatelessWidget {
  const PesaApp({super.key, required this.store, required this.theme});
  final Store store;
  final ThemeController theme;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: theme,
        builder: (context, _) => MaterialApp(
          title: 'Pesa',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: Intro(child: Shell(store: store, tc: theme)),
        ),
      );
}

// ---------- animated app-name intro ----------
class Intro extends StatefulWidget {
  const Intro({super.key, required this.child});
  final Widget child;
  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));
  bool done = false;

  @override
  void initState() {
    super.initState();
    c.forward().whenComplete(() {
      if (mounted) setState(() => done = true);
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (done) return widget.child;
    final t = Tk.of(context);
    const letters = ['P', 'e', 's', 'a'];
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: GestureDetector(
          onTap: () => c.animateTo(1.0, duration: const Duration(milliseconds: 300)),
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) {
              final fade = 1.0 - Curves.easeIn.transform(((c.value - 0.82) / 0.18).clamp(0.0, 1.0));
              final bar = Curves.easeInOut.transform(((c.value - 0.4) / 0.3).clamp(0.0, 1.0));
              return Opacity(
                opacity: fade,
                child: Container(
                  color: t.bg,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < letters.length; i++)
                        Builder(builder: (context) {
                          final p = Curves.easeOutCubic.transform(((c.value - (0.06 + 0.055 * i)) / 0.26).clamp(0.0, 1.0));
                          return Opacity(
                            opacity: p,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - p)),
                              child: Text(letters[i], style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: i == 0 ? brand : t.ink, decoration: TextDecoration.none)),
                            ),
                          );
                        }),
                    ]),
                    const SizedBox(height: 12),
                    Container(width: 64 * bar, height: 3, decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(2))),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}

// ---------- main shell with the floating pill navigation ----------
class Shell extends StatefulWidget {
  const Shell({super.key, required this.store, required this.tc});
  final Store store;
  final ThemeController tc;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    final s = widget.store;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(children: [
        Column(children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: t.card, border: Border(bottom: BorderSide(color: t.line))),
              child: Row(children: [
                Text('Pesa', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: t.ink)),
                const Spacer(),
                IconButton(
                  tooltip: 'Switch light or dark mode',
                  onPressed: () => widget.tc.set(dark ? ThemeMode.light : ThemeMode.dark),
                  icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: t.ink),
                ),
              ]),
            ),
          ),
          Expanded(
            child: IndexedStack(index: i, children: [
              HomePage(s: s),
              RecordsPage(s: s),
              AccountsPage(s: s),
              AnimatedBuilder(animation: widget.tc, builder: (context, _) => SettingsPage(s: s, mode: widget.tc.mode, onMode: widget.tc.set)),
            ]),
          ),
        ]),
        Positioned(left: 0, right: 0, bottom: 0, child: PillNav(index: i, onTap: (v) => setState(() => i = v), onAdd: () => showTxSheet(context, s))),
      ]),
    );
  }
}

class PillNav extends StatelessWidget {
  const PillNav({super.key, required this.index, required this.onTap, required this.onAdd});
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;

  Widget _item(BuildContext context, int k, IconData icon, String label) {
    final t = Tk.of(context);
    final on = index == k;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(k),
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 64,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: on ? t.acc : t.mut),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: on ? t.acc : t.mut)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Tk.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: SizedBox(
          height: 78,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: t.line),
                boxShadow: const [BoxShadow(color: Color(0x1F101828), blurRadius: 24, offset: Offset(0, 6))],
              ),
              child: Row(children: [
                _item(context, 0, Icons.home_outlined, 'Home'),
                _item(context, 1, Icons.receipt_long_outlined, 'Records'),
                const SizedBox(width: 72),
                _item(context, 2, Icons.account_balance_wallet_outlined, 'Accounts'),
                _item(context, 3, Icons.settings_outlined, 'Settings'),
              ]),
            ),
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t.card, width: 4),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B4DF0), Color(0xFF5A35D8)]),
                    boxShadow: const [BoxShadow(color: Color(0x66673DE6), blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
